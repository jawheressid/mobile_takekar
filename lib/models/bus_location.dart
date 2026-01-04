import 'package:cloud_firestore/cloud_firestore.dart';

class BusLocation {
  const BusLocation({
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.nextStopEtaMinutes,
    this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final double? speedKmh;
  final int? nextStopEtaMinutes;
  final DateTime? updatedAt;

  static BusLocation? fromDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;

    final lat = data['lat'];
    final lng = data['lng'];
    if (lat is! num || lng is! num) return null;

    final speed = data['speedKmh'];
    final eta = data['nextStopEtaMin'];
    final updatedAt = data['updatedAt'];

    return BusLocation(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      speedKmh: speed is num ? speed.toDouble() : null,
      nextStopEtaMinutes: eta is num ? eta.toInt() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  
  static BusLocation? fromRealtimeMap(dynamic raw) {
    if (raw is! Map) return null;

    final lat = raw['lat'];
    final lng = raw['lng'];
    if (lat is! num || lng is! num) return null;

    final speed = raw['speed'];
    final updatedAt = raw['updatedAt'];
    final updatedTime = updatedAt is num
        ? DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt())
        : null;

    return BusLocation(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      speedKmh: speed is num ? speed.toDouble() : null,
      updatedAt: updatedTime,
    );
  }
}
