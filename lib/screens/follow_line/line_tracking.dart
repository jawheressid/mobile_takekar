import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/bus_location.dart';
import '../../services/follow_line_service.dart';
import '../../theme/app_colors.dart';

class LineTrackingScreen extends StatefulWidget {
  const LineTrackingScreen({
    super.key,
    required this.lineName,
    required this.regionName,
  });

  final String lineName;
  final String regionName;

  @override
  State<LineTrackingScreen> createState() => _LineTrackingScreenState();
}

class _LineTrackingScreenState extends State<LineTrackingScreen> {
  final FollowLineService _service = FollowLineService();
  final MapController _mapController = MapController();
  final Distance _distance = Distance();

  StreamSubscription<BusLocation?>? _busSub;
  StreamSubscription<Position>? _userSub;
  BusLocation? _busLocation;
  LatLng? _userPoint;
  LatLng? _lastBusPoint;
  bool _mapReady = false;

  static const LatLng _fallbackPoint = LatLng(36.8665, 10.1647);
  static const double _mapZoom = 13;

  @override
  void initState() {
    super.initState();
    _listenBusLocation();
    _listenUserLocation();
  }

  // Ecoute les positions du chauffeur en temps reel.
  void _listenBusLocation() {
    _busSub?.cancel();
    _busSub = _service
        .watchBusLocation(
          lineName: widget.lineName,
          regionName: widget.regionName,
        )
        .listen((location) {
      if (!mounted) return;
      setState(() => _busLocation = location);
      final point = location == null
          ? null
          : LatLng(location.latitude, location.longitude);
      if (point != null) {
        _moveMap(point);
      }
    });
  }

  // Ecoute la position utilisateur pour calculer l'ETA.
  Future<void> _listenUserLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _userSub?.cancel();
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      _userSub = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _userPoint = LatLng(position.latitude, position.longitude);
          });
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _moveMap(LatLng point) {
    if (!_mapReady) return;
    if (_lastBusPoint != null &&
        _lastBusPoint!.latitude == point.latitude &&
        _lastBusPoint!.longitude == point.longitude) {
      return;
    }
    _lastBusPoint = point;
    _mapController.move(point, _mapZoom);
  }

  // ETA simple = distance / vitesse.
  int? _estimateEtaMinutes() {
    final location = _busLocation;
    final userPoint = _userPoint;
    if (location == null || userPoint == null) return null;

    final speed = location.speedKmh;
    if (speed == null || speed <= 1) return null;

    final busPoint = LatLng(location.latitude, location.longitude);
    final distanceKm = _distance.as(
      LengthUnit.Kilometer,
      busPoint,
      userPoint,
    );
    if (distanceKm.isNaN || distanceKm.isInfinite) return null;

    final minutes = (distanceKm / speed) * 60;
    if (minutes.isNaN || minutes.isInfinite) return null;
    return minutes.ceil();
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busPoint = _busLocation == null
        ? null
        : LatLng(_busLocation!.latitude, _busLocation!.longitude);
    final mapPoint = busPoint ?? _fallbackPoint;
    final etaMinutes = _estimateEtaMinutes();

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
                    widget.lineName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.regionName,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: mapPoint,
                            initialZoom: _mapZoom,
                            onMapReady: () {
                              _mapReady = true;
                              final current = _busLocation;
                              if (current != null) {
                                _moveMap(
                                  LatLng(current.latitude, current.longitude),
                                );
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.mon_app',
                            ),
                            MarkerLayer(
                              markers: [
                                if (busPoint != null)
                                  Marker(
                                    point: busPoint,
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
                                if (_userPoint != null)
                                  Marker(
                                    point: _userPoint!,
                                    width: 38,
                                    height: 38,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.accentPink.withAlpha(
                                          220,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x22000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person_pin_circle,
                                        color: Colors.white,
                                        size: 20,
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
                    _InfoPanel(
                      speedKmh: _busLocation?.speedKmh,
                      etaMinutes: etaMinutes,
                    ),
                    if (_busLocation == null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune localisation disponible pour le moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.speedKmh, required this.etaMinutes});

  final double? speedKmh;
  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    final speedText =
        speedKmh == null ? '-- km/h' : '${speedKmh!.toStringAsFixed(0)} km/h';
    final etaText = etaMinutes == null ? '-- min' : '$etaMinutes min';

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
            'à votre position',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
