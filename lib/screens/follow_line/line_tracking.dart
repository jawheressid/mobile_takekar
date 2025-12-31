import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/bus_location.dart';
import '../../services/follow_line_service.dart';
import '../../theme/app_colors.dart';

class LineTrackingScreen extends StatelessWidget {
  const LineTrackingScreen({
    super.key,
    required this.lineName,
    required this.regionName,
  });

  final String lineName;
  final String regionName;

  @override
  Widget build(BuildContext context) {
    final service = FollowLineService();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: const BoxDecoration(
                gradient: sunriseGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                  Text(
                    lineName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    regionName,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<BusLocation?>(
                stream: service.watchBusLocation(
                  lineName: lineName,
                  regionName: regionName,
                ),
                builder: (context, snapshot) {
                  final location = snapshot.data;
                  final point = location == null
                      ? const LatLng(36.8665, 10.1647)
                      : LatLng(location.latitude, location.longitude);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 240,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: point,
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.takekar.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: point,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.sunrise.withAlpha(
                                            230,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 12,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoPanel(location: location),
                        if (location == null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune localisation disponible pour le moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.location});

  final BusLocation? location;

  @override
  Widget build(BuildContext context) {
    final speedText = location?.speedKmh == null
        ? '-- km/h'
        : '${location!.speedKmh!.toStringAsFixed(0)} km/h';
    final etaText = location?.nextStopEtaMinutes == null
        ? '-- min'
        : '${location!.nextStopEtaMinutes} min';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFBC02D),
            blurRadius: 12,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.near_me, color: AppColors.sunrise),
              const SizedBox(width: 10),
              Text(
                speedText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Vitesse actuelle',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          const Text(
            'Arrivée estimée',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            etaText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.sunrise,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'à la prochaine station',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
