import 'package:flutter/material.dart';

import '../models/trip_option.dart';
import '../services/trip_search_service.dart';
import '../theme/app_colors.dart';
import 'trip_details_page.dart';

class TripResultsArgs {
  const TripResultsArgs({
    required this.fromLabel,
    required this.toLabel,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  final String fromLabel;
  final String toLabel;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
}

class TripResultsPage extends StatefulWidget {
  const TripResultsPage({super.key});

  static const String route = '/trip-results';

  @override
  State<TripResultsPage> createState() => _TripResultsPageState();
}

class _TripResultsPageState extends State<TripResultsPage> {
  final TripSearchService _service = TripSearchService();
  TripResultsArgs _args =
      const TripResultsArgs(fromLabel: 'Depart', toLabel: 'Arrivee');
  Future<List<TripOption>>? _tripsFuture;

  
  double maxWaitMinutes = 45;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tripsFuture != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    _args = args is TripResultsArgs
        ? args
        : const TripResultsArgs(fromLabel: 'Depart', toLabel: 'Arrivee');
    debugPrint(
      '[TripResults] init args from="${_args.fromLabel}" to="${_args.toLabel}" '
      'fromLat=${_args.fromLat} fromLng=${_args.fromLng} '
      'toLat=${_args.toLat} toLng=${_args.toLng}',
    );
    _tripsFuture = _service.searchTrips(
      fromLabel: _args.fromLabel,
      toLabel: _args.toLabel,
      fromLat: _args.fromLat,
      fromLng: _args.fromLng,
      toLat: _args.toLat,
      toLng: _args.toLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _tripsFuture;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<TripOption>>(
          future: future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState != ConnectionState.done;
            final hasError = snapshot.hasError;
            final allTrips = snapshot.data ?? const <TripOption>[];
            final List<TripOption> filteredTrips = hasError
                ? <TripOption>[]
                : allTrips
                    .where((t) => t.durationMinutes <= maxWaitMinutes)
                    .toList(growable: true);
            debugPrint(
              '[TripResults] build loading=$isLoading error=$hasError '
              'trips=${allTrips.length} filtered=${filteredTrips.length}',
            );
            if (hasError) {
              debugPrint('[TripResults] error: ${snapshot.error}');
              debugPrint('[TripResults] stack: ${snapshot.stackTrace}');
            }

            final subtitle = isLoading
                ? 'Recherche en cours...'
                : '${filteredTrips.length} trajets trouvés • ${_args.fromLabel} → ${_args.toLabel}';

            return Column(
              children: [
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                  decoration: const BoxDecoration(
                    gradient: sunriseGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Résultats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temps d\'attente max: ${maxWaitMinutes.round()} min',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        Slider(
                          value: maxWaitMinutes,
                          min: 5,
                          max: 120,
                          divisions: 23,
                          onChanged: (v) => setState(() => maxWaitMinutes = v),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (hasError) {
                        return const Center(
                          child: Text(
                            'Erreur lors de la recherche.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      if (filteredTrips.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun trajet trouvé.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) => _TripCard(
                          trip: filteredTrips[index],
                          onTap: () => Navigator.of(context).pushNamed(
                            TripDetailsPage.route,
                            arguments: filteredTrips[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final TripOption trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stopSequence = _buildStopSequence(trip);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.sunrise,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.lineName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.isDirect ? 'Direct' : 'Avec correspondance',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoPill(
                    icon: Icons.schedule,
                    text: '${trip.durationMinutes} min',
                  ),
                  _InfoPill(
                    icon: Icons.place_outlined,
                    text: '${trip.distanceKm.toStringAsFixed(1)} km',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  stopSequence,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${trip.stops} arrêts • Prochain départ: ${trip.nextDeparture}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(text, style: const TextStyle(color: AppColors.textPrimary)),
      ],
    );
  }
}

String _buildStopSequence(TripOption trip) {
  if (trip.path.isEmpty) return 'Trajet';
  final ordered = <String>[];
  String? last;
  for (final stop in trip.path) {
    final name = stop.name.trim();
    if (name.isEmpty) continue;
    if (last == null || last.toLowerCase() != name.toLowerCase()) {
      ordered.add(name);
      last = name;
    }
  }
  if (ordered.isEmpty) return 'Trajet';
  return ordered.join(' \u2192 ');
}
