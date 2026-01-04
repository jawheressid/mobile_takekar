import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/bus_location.dart';
import '../models/line_route.dart';
import '../models/stop_location.dart';

class FollowLineService {
  FollowLineService({FirebaseFirestore? firestore, FirebaseDatabase? database})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _database = database ?? FirebaseDatabase.instance;

  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  // Keep it simple: try Firestore, fallback to hardcoded lists.
  Future<List<String>> fetchLines() async {
    try {
      final snapshot = await _firestore.collection('lines').get();
      final names = snapshot.docs
          .map((d) => (d.data()['name'] as String?)?.trim())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    } catch (_) {}
    return const ['Ligne 1', 'Ligne 2', 'Ligne 3'];
  }

  Future<List<String>> fetchRegions({required String lineName}) async {
    try {
      final snapshot = await _firestore
          .collection('lines')
          .where('name', isEqualTo: lineName)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return const ['Centre-ville', 'Nord', 'Sud'];
      final data = snapshot.docs.first.data();
      final regions = data['regions'];
      if (regions is List) {
        return regions
            .map((e) => e is String ? e.trim() : null)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const ['Centre-ville', 'Nord', 'Sud'];
  }

  Future<_LineInfo?> _fetchLineInfo({
    required String lineName,
    required String regionName,
  }) async {
    try {
      final baseQuery = _firestore
          .collection('lines')
          .where('name', isEqualTo: lineName);

      final trimmedRegion = regionName.trim();
      if (trimmedRegion.isNotEmpty) {
        final regional = await baseQuery
            .where('regions', arrayContains: trimmedRegion)
            .limit(1)
            .get();
        if (regional.docs.isNotEmpty) {
          final doc = regional.docs.first;
          return _LineInfo(
            id: doc.id,
            active: _isActive(doc.data()),
          );
        }
      }

      final snapshot = await baseQuery.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return _LineInfo(
          id: doc.id,
          active: _isActive(doc.data()),
        );
      }
    } catch (_) {}
    return null;
  }

  bool _isActive(Map<String, dynamic> data) {
    final active = data['active'];
    return active is bool ? active : true;
  }

  BusLocation? _latestFromLiveRuns(dynamic raw) {
    if (raw is! Map) return null;

    BusLocation? latest;
    var latestMillis = -1;

    // liveRuns contient plusieurs services actifs; on prend le plus récent.
    for (final value in raw.values) {
      final location = BusLocation.fromRealtimeMap(value);
      if (location == null) continue;
      final millis = location.updatedAt?.millisecondsSinceEpoch ?? 0;
      if (millis >= latestMillis) {
        latestMillis = millis;
        latest = location;
      }
    }

    return latest;
  }

  Stream<BusLocation?> watchBusLocation({
    required String lineName,
    required String regionName,
  }) async* {
    final lineInfo = await _fetchLineInfo(
      lineName: lineName,
      regionName: regionName,
    );
    if (lineInfo == null) {
      yield null;
      return;
    }

    final fallbackStop =
        lineInfo.active ? null : await _fallbackStopForLine(lineInfo.id);

    // Flux temps réel depuis RTDB (liveRuns).
    final query = _database
        .ref('liveRuns')
        .orderByChild('lineId')
        .equalTo(lineInfo.id);

    await for (final event in query.onValue) {
      final live = _latestFromLiveRuns(event.snapshot.value);
      if (live != null) {
        yield live;
        continue;
      }
      if (fallbackStop != null) {
        yield BusLocation(
          latitude: fallbackStop.latitude,
          longitude: fallbackStop.longitude,
          speedKmh: 0,
          updatedAt: DateTime.now(),
        );
      } else {
        yield null;
      }
    }
  }

  Future<StopLocation?> _fallbackStopForLine(String lineId) async {
    try {
      final routeSnapshot = await _firestore
          .collection('line_routes')
          .where('lineId', isEqualTo: lineId)
          .limit(1)
          .get();
      if (routeSnapshot.docs.isEmpty) return null;

      final route = LineRoute.fromDoc(
        routeSnapshot.docs.first.id,
        routeSnapshot.docs.first.data(),
      );
      if (route == null || route.stopIds.isEmpty) return null;

      final stopSnapshot =
          await _firestore.collection('stops').doc(route.stopIds.first).get();
      return StopLocation.fromDoc(stopSnapshot);
    } catch (_) {}
    return null;
  }
}

class _LineInfo {
  const _LineInfo({required this.id, required this.active});

  final String id;
  final bool active;
}
