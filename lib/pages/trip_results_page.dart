import 'package:flutter/material.dart';

import '../models/trip_option.dart';
import '../services/trip_search_service.dart';
import '../theme/app_colors.dart';
import 'trip_details_page.dart';

class TripResultsArgs {
  const TripResultsArgs({required this.fromQuery, required this.toQuery});

  final String fromQuery;
  final String toQuery;
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

  final _searchService = TripSearchService();
  Future<List<TripOption>>? _resultsFuture;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _resultsFuture = _fetchTrips();
  }

  Future<List<TripOption>> _fetchTrips() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final TripResultsArgs typedArgs = args is TripResultsArgs
        ? args
        : const TripResultsArgs(fromQuery: 'Depart', toQuery: 'Arrivee');

    if (typedArgs.fromQuery.isEmpty || typedArgs.toQuery.isEmpty) {
      return const [];
    }

    final fromStops = await _searchService.fetchStopsForPlace(
      place: typedArgs.fromQuery,
    );
    final toStops = await _searchService.fetchStopsForPlace(
      place: typedArgs.toQuery,
    );

    if (fromStops.isEmpty || toStops.isEmpty) return const [];

    final stopIds = {
      ...fromStops.map((e) => e.id),
      ...toStops.map((e) => e.id),
    };

    final routes = await _searchService.fetchRoutesForStopIds(stopIds);
    final directTrips = _searchService.buildDirectTrips(
      routes: routes,
      fromStops: fromStops,
      toStops: toStops,
    );

    final transferTrips = directTrips.length >= 5
        ? const <TripOption>[]
        : _searchService.buildTransferTrips(
            routes: routes,
            fromStops: fromStops,
            toStops: toStops,
          );

    return [...directTrips, ...transferTrips];
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final TripResultsArgs typedArgs = args is TripResultsArgs
        ? args
        : const TripResultsArgs(fromQuery: 'Depart', toQuery: 'Arrivee');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<TripOption>>(
          future: _resultsFuture ?? Future.value(const <TripOption>[]),
          builder: (context, snapshot) {
            final allTrips = snapshot.data ?? const <TripOption>[];

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
                        '${filteredTrips.length} trajets trouvés • ${typedArgs.fromQuery} → ${typedArgs.toQuery}',
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Slider(
                          value: maxDurationMinutes,
                          min: 10,
                          max: 120,
                          divisions: 22,
                          onChanged: (v) =>
                              setState(() => maxDurationMinutes = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Impossible de charger les trajets.',
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
                  '${trip.stops} arrêts • ${trip.fromStopName} → ${trip.toStopName}',
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
