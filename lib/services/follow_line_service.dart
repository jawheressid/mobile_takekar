import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/bus_location.dart';

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

  Future<String?> _fetchLineId({
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
        if (regional.docs.isNotEmpty) return regional.docs.first.id;
      }

      final snapshot = await baseQuery.limit(1).get();
      if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;
    } catch (_) {}
    return null;
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
    final lineId = await _fetchLineId(
      lineName: lineName,
      regionName: regionName,
    );
    if (lineId == null) {
      yield null;
      return;
    }

    // Flux temps réel depuis RTDB (liveRuns).
    final query = _database
        .ref('liveRuns')
        .orderByChild('lineId')
        .equalTo(lineId);

    await for (final event in query.onValue) {
      yield _latestFromLiveRuns(event.snapshot.value);
    }
  }
}
