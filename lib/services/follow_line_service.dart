import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bus_location.dart';

class FollowLineService {
  FollowLineService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      final snapshot = await _firestore.collection('lines').where('name', isEqualTo: lineName).limit(1).get();
      if (snapshot.docs.isEmpty) return const ['Centre-ville', 'Nord', 'Sud'];
      final data = snapshot.docs.first.data();
      final regions = data['regions'];
      if (regions is List) {
        return regions.map((e) => e is String ? e.trim() : null).whereType<String>().where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
    return const ['Centre-ville', 'Nord', 'Sud'];
  }

  String locationDocId({required String lineName, required String regionName}) {
    final raw = '${lineName}_$regionName'.toLowerCase();
    final normalized = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
    return normalized.replaceAll(RegExp(r'^_|_$'), '');
  }

  Stream<BusLocation?> watchBusLocation({required String lineName, required String regionName}) {
    final id = locationDocId(lineName: lineName, regionName: regionName);
    return _firestore.collection('bus_locations').doc(id).snapshots().map(BusLocation.fromDoc);
  }
}
