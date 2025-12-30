import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FollowLinePage extends StatelessWidget {
  const FollowLinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔶 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Color(0xFFF4B400),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: const [
                Text(
                  'Ligne 3', // ✅ بدّلنا الرقم
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nord',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // 🗺️ MAP
          SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(36.8065, 10.1815), // تونس
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(36.8065, 10.1815),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.directions_bus,
                        color: Color(0xFFF4B400),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ℹ️ INFO CARD
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Column(
                children: const [
                  Text(
                    '-- km/h',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Vitesse actuelle'),
                  SizedBox(height: 16),
                  Text(
                    '-- min',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4B400),
                    ),
                  ),
                  Text('à la prochaine station'),
                ],
              ),
            ),
          ),

          const Text(
            'Aucune localisation disponible pour le moment.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
