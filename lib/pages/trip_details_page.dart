import 'package:flutter/material.dart';

import '../models/trip_option.dart';
import '../theme/app_colors.dart';

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({super.key});

  static const String route = '/trip-details';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final TripOption trip = args is TripOption
        ? args
        : const TripOption(
            lineName: 'Ligne',
            isDirect: true,
            durationMinutes: 0,
            priceTnd: 0,
            distanceKm: 0,
            stops: 0,
            nextDeparture: '--:--',
            departureTimes: [],
            path: [],
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header jaune avec le nom de la ligne.
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
                  Text(
                    trip.lineName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Détails du trajet',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Résumé (durée / prix / distance)
                  _SectionCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Metric(
                          label: 'Durée',
                          value: '${trip.durationMinutes} min',
                        ),
                        _Metric(
                          label: 'Prix',
                          value: '${trip.priceTnd.toStringAsFixed(2)} DT',
                        ),
                        _Metric(
                          label: 'Distance',
                          value: '${trip.distanceKm.toStringAsFixed(1)} km',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Horaires (chips)
                  const _SectionTitle(icon: Icons.schedule, title: 'Horaires'),
                  const SizedBox(height: 10),
                  _SectionCard(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: trip.departureTimes.isEmpty
                          ? const [
                              Text(
                                'Aucun horaire disponible',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ]
                          : [
                              for (final time in trip.departureTimes)
                                ChoiceChip(
                                  selected: time == trip.nextDeparture,
                                  label: Text(time),
                                  selectedColor: AppColors.sunrise,
                                  labelStyle: TextStyle(
                                    color: time == trip.nextDeparture
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                            ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Arrêts (timeline simple)
                  _SectionTitle(
                    icon: Icons.pin_drop_outlined,
                    title: 'Arrêts (${trip.path.length})',
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < trip.path.length; i++) ...[
                          _StopRow(
                            stop: trip.path[i],
                            isLast: i == trip.path.length - 1,
                          ),
                          if (i != trip.path.length - 1)
                            const SizedBox(height: 10),
                        ],
                        if (trip.path.isEmpty)
                          const Text(
                            'Aucun arrêt',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.sunrise),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.isLast});

  final TripStop stop;
  final bool isLast;

  Color get _dotColor {
    switch (stop.kind) {
      case TripStopKind.start:
        return Colors.green;
      case TripStopKind.middle:
        return AppColors.sunrise;
      case TripStopKind.end:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline: point + ligne verticale
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                color: const Color(0x22000000),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stop.label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
