import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/line_route.dart';
import '../models/stop_location.dart';
import '../models/trip_option.dart';

class TripSearchService {
  TripSearchService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<StopLocation>> fetchStopsForPlace({
    required String place,
    int limit = 5,
  }) async {
    final query = place.trim();
    if (query.isEmpty) return const [];

    final exactName = await _firestore
        .collection('stops')
        .where('name', isEqualTo: query)
        .limit(limit)
        .get();

    final exactNameStops = exactName.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();

    if (exactNameStops.isNotEmpty) return exactNameStops;

    final exactCity = await _firestore
        .collection('stops')
        .where('city', isEqualTo: query)
        .limit(limit)
        .get();

    final exactCityStops = exactCity.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();

    if (exactCityStops.isNotEmpty) return exactCityStops;

    final end = query + String.fromCharCode(0xf8ff);
    final prefixName = await _firestore
        .collection('stops')
        .orderBy('name')
        .startAt([query])
        .endAt([end])
        .limit(limit)
        .get();

    final prefixNameStops = prefixName.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();

    if (prefixNameStops.isNotEmpty) return prefixNameStops;

    final prefixCity = await _firestore
        .collection('stops')
        .orderBy('city')
        .startAt([query])
        .endAt([end])
        .limit(limit)
        .get();

    return prefixCity.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();
  }

  Future<List<LineRoute>> fetchRoutesForStopIds(
    Set<String> stopIds,
  ) async {
    if (stopIds.isEmpty) return const [];
    final snapshot = await _firestore
        .collection('line_routes')
        .where('stopIds', arrayContainsAny: stopIds.toList())
        .get();
    return snapshot.docs
        .map((doc) => LineRoute.fromDoc(doc.id, doc.data()))
        .whereType<LineRoute>()
        .toList();
  }

  List<TripOption> buildDirectTrips({
    required List<LineRoute> routes,
    required List<StopLocation> fromStops,
    required List<StopLocation> toStops,
  }) {
    final fromLookup = {for (final stop in fromStops) stop.id: stop};
    final toLookup = {for (final stop in toStops) stop.id: stop};
    final trips = <TripOption>[];

    for (final route in routes) {
      for (final fromEntry in fromLookup.entries) {
        final fromIndex = route.stopIds.indexOf(fromEntry.key);
        if (fromIndex == -1) continue;

        for (final toEntry in toLookup.entries) {
          final toIndex = route.stopIds.indexOf(toEntry.key);
          if (toIndex == -1 || toIndex <= fromIndex) continue;
          final stopCount = toIndex - fromIndex;
          trips.add(
            TripOption(
              lineName: route.lineName,
              direction: route.direction,
              isDirect: true,
              durationMinutes: max(5, stopCount * 4),
              priceTnd: max(1.0, stopCount * 0.4),
              distanceKm: max(0.5, stopCount * 0.6),
              stops: stopCount,
              fromStopName: fromEntry.value.name,
              toStopName: toEntry.value.name,
              nextDeparture: '—',
              departureTimes: const [],
              path: _buildPath(
                route: route,
                fromIndex: fromIndex,
                toIndex: toIndex,
                fromStopName: fromEntry.value.name,
                toStopName: toEntry.value.name,
              ),
            ),
          );
        }
      }
    }

    return trips;
  }

  List<TripOption> buildTransferTrips({
    required List<LineRoute> routes,
    required List<StopLocation> fromStops,
    required List<StopLocation> toStops,
  }) {
    final fromLookup = {for (final stop in fromStops) stop.id: stop};
    final toLookup = {for (final stop in toStops) stop.id: stop};
    final trips = <TripOption>[];

    for (final routeA in routes) {
      for (final routeB in routes) {
        if (routeA.id == routeB.id) continue;
        for (final fromEntry in fromLookup.entries) {
          final fromIndex = routeA.stopIds.indexOf(fromEntry.key);
          if (fromIndex == -1) continue;

          for (final toEntry in toLookup.entries) {
            final toIndex = routeB.stopIds.indexOf(toEntry.key);
            if (toIndex == -1) continue;

            final transferId = _findTransferStop(routeA, routeB);
            if (transferId == null) continue;
            final transferIndexA = routeA.stopIds.indexOf(transferId);
            final transferIndexB = routeB.stopIds.indexOf(transferId);
            if (transferIndexA <= fromIndex || transferIndexB >= toIndex) {
              continue;
            }

            final stopCount =
                (transferIndexA - fromIndex) + (toIndex - transferIndexB);
            trips.add(
              TripOption(
                lineName: '${routeA.lineName} + ${routeB.lineName}',
                direction: routeA.direction,
                isDirect: false,
                durationMinutes: max(10, stopCount * 5),
                priceTnd: max(1.5, stopCount * 0.5),
                distanceKm: max(1.0, stopCount * 0.7),
                stops: stopCount,
                fromStopName: fromEntry.value.name,
                toStopName: toEntry.value.name,
                nextDeparture: '—',
                departureTimes: const [],
                path: _buildTransferPath(
                  routeA: routeA,
                  routeB: routeB,
                  fromIndex: fromIndex,
                  transferId: transferId,
                  toIndex: toIndex,
                  fromStopName: fromEntry.value.name,
                  toStopName: toEntry.value.name,
                ),
              ),
            );
          }
        }
      }
    }

    return trips;
  }

  String? _findTransferStop(LineRoute routeA, LineRoute routeB) {
    final setB = routeB.stopIds.toSet();
    for (final stopId in routeA.stopIds) {
      if (setB.contains(stopId)) {
        return stopId;
      }
    }
    return null;
  }

  List<TripStop> _buildPath({
    required LineRoute route,
    required int fromIndex,
    required int toIndex,
    required String fromStopName,
    required String toStopName,
  }) {
    final stops = <TripStop>[
      TripStop(
        name: fromStopName,
        label: 'Départ',
        kind: TripStopKind.start,
      ),
    ];

    for (int i = fromIndex + 1; i < toIndex; i++) {
      stops.add(
        TripStop(
          name: 'Arrêt ${i - fromIndex}',
          label: 'Sur la ligne',
          kind: TripStopKind.middle,
        ),
      );
    }

    stops.add(
      TripStop(
        name: toStopName,
        label: 'Arrivée',
        kind: TripStopKind.end,
      ),
    );

    return stops;
  }

  List<TripStop> _buildTransferPath({
    required LineRoute routeA,
    required LineRoute routeB,
    required int fromIndex,
    required String transferId,
    required int toIndex,
    required String fromStopName,
    required String toStopName,
  }) {
    final transferStop = TripStop(
      name: 'Correspondance',
      label: transferId,
      kind: TripStopKind.middle,
    );

    return [
      TripStop(
        name: fromStopName,
        label: 'Départ',
        kind: TripStopKind.start,
      ),
      transferStop,
      TripStop(
        name: toStopName,
        label: 'Arrivée',
        kind: TripStopKind.end,
      ),
    ];
  }
}
