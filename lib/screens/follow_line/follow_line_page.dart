import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../pages/report_problem_page.dart';
import '../../services/driver_run_service.dart';

class FollowLinePage extends StatefulWidget {
  const FollowLinePage({super.key, required this.run});

  final DriverRun run;

  @override
  State<FollowLinePage> createState() => _FollowLinePageState();
}

class _FollowLinePageState extends State<FollowLinePage> {
  final DriverRunService _service = DriverRunService();
  DriverRunTracker? _tracker;
  bool _gpsReady = false;
  String? _gpsError;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final tracker = DriverRunTracker(service: _service, run: widget.run);
      await tracker.start();
      if (!mounted) return;
      setState(() {
        _tracker = tracker;
        _gpsReady = true;
        _gpsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _gpsReady = false;
        _gpsError = friendlyDriverRunErrorMessage(error);
      });
    }
  }

  Future<void> _finishService() async {
    if (_stopping) return;
    setState(() => _stopping = true);

    try {
      await _tracker?.stop();
      await _service.stopService(widget.run);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyDriverRunErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _stopping = false);
      }
    }
  }

  @override
  void dispose() {
    _tracker?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _gpsReady
        ? 'GPS actif'
        : (_gpsError == null ? 'Activation GPS' : 'GPS arrêté');
    final statusColor = _gpsReady ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // HEADER: infos de service (ligne + bus + statut).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFFF4B400),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.run.lineName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.run.busId,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                // Badge d'état (pour l'instant: toujours "En service").
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(64),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_gpsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_off, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _gpsError!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: _startTracking,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),

          if (_gpsError != null) const SizedBox(height: 16),

          // CARTE: exemple simple avec un marker statique.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(36.8065, 10.1815),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mon_app',
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
          ),

          const SizedBox(height: 20),

          // ACTIONS: boutons placeholder (non branchés pour l'instant).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Community'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4B400),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(ReportProblemPage.route),
                    icon: const Icon(Icons.report_gmailerrorred),
                    label: const Text('Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FIN DU SERVICE: pour l'instant on revient simplement à l'écran précédent.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopping ? null : _finishService,
                icon: const Icon(Icons.stop_circle),
                label: const Text('Finir le trajet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
