import 'package:cloud_firestore/cloud_firestore.dart';

class StopLocation {
  const StopLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.geohash,
    this.city,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? geohash;
  final String? city;

  static StopLocation? fromDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;

    final name = data['name'];
    final lat = data['lat'];
    final lng = data['lng'];
    if (name is! String || lat is! num || lng is! num) {
      return null;
    }

    final geohash = data['geohash'];
    final city = data['city'];

    return StopLocation(
      id: snapshot.id,
      name: name.trim(),
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      geohash: geohash is String ? geohash.trim() : null,
      city: city is String && city.trim().isNotEmpty ? city.trim() : null,
    );
  }
}
