import 'package:cloud_firestore/cloud_firestore.dart';

class StopLocation {
  const StopLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    this.city,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String geohash;
  final String? city;

  static StopLocation? fromDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    final name = data['name'];
    final lat = data['lat'];
    final lng = data['lng'];
    final geohash = data['geohash'];
    if (name is! String || lat is! num || lng is! num || geohash is! String) {
      return null;
    }
    final city = data['city'];
    return StopLocation(
      id: snapshot.id,
      name: name,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      geohash: geohash,
      city: city is String && city.trim().isNotEmpty ? city.trim() : null,
    );
  }
}
