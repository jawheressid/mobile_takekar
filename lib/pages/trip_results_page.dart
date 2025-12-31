import 'package:flutter/material.dart';

import '../models/trip_option.dart';
import '../theme/app_colors.dart';
import 'trip_details_page.dart';

class TripResultsArgs {
  const TripResultsArgs({required this.from, required this.to});

  final String from;
  final String to;
}

enum TripSort { price, duration }

class TripResultsPage extends StatefulWidget {
  const TripResultsPage({super.key});

  static const String route = '/trip-results';

  @override
  State<TripResultsPage> createState() => _TripResultsPageState();
}

class _TripResultsPageState extends State<TripResultsPage> {
  TripSort sort = TripSort.price;

  // Filtres simples demandés: prix & durée max.
  double maxPriceTnd = 6.0;
  double maxDurationMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final TripResultsArgs typedArgs = args is TripResultsArgs
        ? args
        : const TripResultsArgs(from: 'Départ', to: 'Arrivée');

    // Données mock (exemple) — plus tard vous pouvez remplacer par un appel API/Firebase.
    final allTrips = _mockTrips(from: typedArgs.from, to: typedArgs.to);

    // Application des filtres.
    final filteredTrips =
        allTrips
            .where(
              (t) =>
                  t.priceTnd <= maxPriceTnd &&
                  t.durationMinutes <= maxDurationMinutes,
            )
            .toList()
          ..sort((a, b) {
            switch (sort) {
              case TripSort.price:
                return a.priceTnd.compareTo(b.priceTnd);
              case TripSort.duration:
                return a.durationMinutes.compareTo(b.durationMinutes);
            }
          });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header jaune "Résultats"
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
                    '${filteredTrips.length} trajets trouvés • ${typedArgs.from} → ${typedArgs.to}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Zone de filtres (simple)
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
                    Row(
                      children: [
                        const Text(
                          'Trier par: ',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<TripSort>(
                          value: sort,
                          items: const [
                            DropdownMenuItem(
                              value: TripSort.price,
                              child: Text('Prix'),
                            ),
                            DropdownMenuItem(
                              value: TripSort.duration,
                              child: Text('Durée'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => sort = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prix max: ${maxPriceTnd.toStringAsFixed(1)} DT',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Slider(
                      value: maxPriceTnd,
                      min: 1,
                      max: 10,
                      divisions: 18,
                      onChanged: (v) => setState(() => maxPriceTnd = v),
                    ),
                    Text(
                      'Durée max: ${maxDurationMinutes.round()} min',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Slider(
                      value: maxDurationMinutes,
                      min: 10,
                      max: 120,
                      divisions: 22,
                      onChanged: (v) => setState(() => maxDurationMinutes = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
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
                    icon: Icons.payments_outlined,
                    text: '${trip.priceTnd.toStringAsFixed(2)} DT',
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
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textPrimary)),
      ],
    );
  }
}

List<TripOption> _mockTrips({required String from, required String to}) {
  // Petit générateur "fake" : 3 trajets comme dans l’exemple.
  // Vous pouvez remplacer ça plus tard par une logique réelle (API, DB, Firestore...).
  return [
    TripOption(
      lineName: 'Ligne 3',
      isDirect: true,
      durationMinutes: 25,
      priceTnd: 2.50,
      distanceKm: 5.2,
      stops: 4,
      nextDeparture: '08:00',
      departureTimes: const [
        '08:00',
        '08:30',
        '09:00',
        '09:30',
        '10:00',
        '10:30',
        '11:00',
      ],
      path: [
        TripStop(name: from, label: 'Départ', kind: TripStopKind.start),
        const TripStop(
          name: 'Rue Victor Hugo',
          label: 'Arrêt 1',
          kind: TripStopKind.middle,
        ),
        const TripStop(
          name: 'Centre Commercial',
          label: 'Arrêt 2',
          kind: TripStopKind.middle,
        ),
        TripStop(name: to, label: 'Arrivée', kind: TripStopKind.end),
      ],
    ),
    TripOption(
      lineName: 'Ligne 7',
      isDirect: true,
      durationMinutes: 32,
      priceTnd: 3.00,
      distanceKm: 6.8,
      stops: 5,
      nextDeparture: '07:45',
      departureTimes: const ['07:45', '08:15', '08:45', '09:15', '09:45'],
      path: [
        TripStop(name: from, label: 'Départ', kind: TripStopKind.start),
        const TripStop(
          name: 'Avenue Habib Bourguiba',
          label: 'Arrêt 1',
          kind: TripStopKind.middle,
        ),
        const TripStop(
          name: 'Bab El Bhar',
          label: 'Arrêt 2',
          kind: TripStopKind.middle,
        ),
        const TripStop(
          name: 'Rue de Marseille',
          label: 'Arrêt 3',
          kind: TripStopKind.middle,
        ),
        TripStop(name: to, label: 'Arrivée', kind: TripStopKind.end),
      ],
    ),
    TripOption(
      lineName: 'Ligne 12',
      isDirect: true,
      durationMinutes: 38,
      priceTnd: 3.50,
      distanceKm: 7.5,
      stops: 5,
      nextDeparture: '08:10',
      departureTimes: const ['08:10', '08:40', '09:10', '09:40'],
      path: [
        TripStop(name: from, label: 'Départ', kind: TripStopKind.start),
        const TripStop(
          name: 'Station Lafayette',
          label: 'Arrêt 1',
          kind: TripStopKind.middle,
        ),
        const TripStop(
          name: 'Bab Saadoun',
          label: 'Arrêt 2',
          kind: TripStopKind.middle,
        ),
        const TripStop(
          name: 'Géant',
          label: 'Arrêt 3',
          kind: TripStopKind.middle,
        ),
        TripStop(name: to, label: 'Arrivée', kind: TripStopKind.end),
      ],
    ),
  ];
}
