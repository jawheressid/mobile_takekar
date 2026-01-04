import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/line_route.dart';
import '../models/stop_location.dart';
import '../models/trip_option.dart';

class TripSearchService {
  TripSearchService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Distance _distance = Distance();

  Future<List<TripOption>> searchTrips({
    required String fromLabel,
    required String toLabel,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) async {
    debugPrint(
      '[TripSearch] start from="$fromLabel" to="$toLabel" '
      'fromLat=$fromLat fromLng=$fromLng toLat=$toLat toLng=$toLng',
    );
    final fromNearest = (fromLat != null && fromLng != null)
        ? await findNearestStop(latitude: fromLat, longitude: fromLng)
        : null;
    final toNearest = (toLat != null && toLng != null)
        ? await findNearestStop(latitude: toLat, longitude: toLng)
        : null;
    if (fromNearest != null) {
      debugPrint(
        '[TripSearch] nearest from stop=${fromNearest.stop.id} '
        'name="${fromNearest.stop.name}" km=${fromNearest.distanceKm.toStringAsFixed(2)}',
      );
    }
    if (toNearest != null) {
      debugPrint(
        '[TripSearch] nearest to stop=${toNearest.stop.id} '
        'name="${toNearest.stop.name}" km=${toNearest.distanceKm.toStringAsFixed(2)}',
      );
    }

    final fromStops = fromNearest != null
        ? [fromNearest.stop]
        : await fetchStopsForPlace(place: fromLabel, limit: 6);
    final toStops = toNearest != null
        ? [toNearest.stop]
        : await fetchStopsForPlace(place: toLabel, limit: 6);

    debugPrint(
      '[TripSearch] stops from=${fromStops.length} to=${toStops.length}',
    );
    if (fromStops.isEmpty || toStops.isEmpty) {
      debugPrint('[TripSearch] stop list empty, return 0 trips');
      return const [];
    }

    final stopIds = <String>{
      ...fromStops.map((stop) => stop.id),
      ...toStops.map((stop) => stop.id),
    };
    final routes = await fetchRoutesForStopIds(stopIds);
    debugPrint('[TripSearch] routes found=${routes.length}');
    if (routes.isEmpty) {
      debugPrint('[TripSearch] no routes, return 0 trips');
      return const [];
    }

    final fromWalkKm = fromNearest == null
        ? null
        : {fromNearest.stop.id: fromNearest.distanceKm};
    final toWalkKm =
        toNearest == null ? null : {toNearest.stop.id: toNearest.distanceKm};

    final directTrips = buildDirectTrips(
      routes: routes,
      fromStops: fromStops,
      toStops: toStops,
      fromLabel: fromLabel,
      toLabel: toLabel,
      fromWalkKmByStopId: fromWalkKm,
      toWalkKmByStopId: toWalkKm,
    );
    final transferTrips = buildTransferTrips(
      routes: routes,
      fromStops: fromStops,
      toStops: toStops,
      fromLabel: fromLabel,
      toLabel: toLabel,
      fromWalkKmByStopId: fromWalkKm,
      toWalkKmByStopId: toWalkKm,
    );

    debugPrint(
      '[TripSearch] direct=${directTrips.length} transfer=${transferTrips.length}',
    );
    final result =
        _dedupeTrips([...directTrips, ...transferTrips]).take(12).toList();
    debugPrint('[TripSearch] result count=${result.length}');
    return result;
  }

  Future<List<StopLocation>> fetchStopsForPlace({
    required String place,
    int limit = 5,
  }) async {
    final query = place.trim();
    if (query.isEmpty) return const [];
    debugPrint('[TripSearch] fetchStopsForPlace query="$query" limit=$limit');

    final exactName = await _firestore
        .collection('stops')
        .where('name', isEqualTo: query)
        .limit(limit)
        .get();
    final exactNameStops = exactName.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();
    if (exactNameStops.isNotEmpty) {
      debugPrint(
        '[TripSearch] exact name stops=${exactNameStops.length}',
      );
      return exactNameStops;
    }

    final exactCity = await _firestore
        .collection('stops')
        .where('city', isEqualTo: query)
        .limit(limit)
        .get();
    final exactCityStops = exactCity.docs
        .map(StopLocation.fromDoc)
        .whereType<StopLocation>()
        .toList();
    if (exactCityStops.isNotEmpty) {
      debugPrint(
        '[TripSearch] exact city stops=${exactCityStops.length}',
      );
      return exactCityStops;
    }

    final end = '$query${String.fromCharCode(0xf8ff)}';
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
    if (prefixNameStops.isNotEmpty) {
      debugPrint(
        '[TripSearch] prefix name stops=${prefixNameStops.length}',
      );
      return prefixNameStops;
    }

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

  Future<NearestStop?> findNearestStop({
    required double latitude,
    required double longitude,
    int limit = 200,
  }) async {
    debugPrint(
      '[TripSearch] findNearestStop lat=$latitude lng=$longitude limit=$limit',
    );
    final snapshot = await _firestore.collection('stops').limit(limit).get();
    StopLocation? closest;
    double? closestMeters;

    for (final doc in snapshot.docs) {
      final stop = StopLocation.fromDoc(doc);
      if (stop == null) continue;
      final meters = _distance.as(
        LengthUnit.Meter,
        LatLng(latitude, longitude),
        LatLng(stop.latitude, stop.longitude),
      );
      if (closestMeters == null || meters < closestMeters) {
        closestMeters = meters;
        closest = stop;
      }
    }

    if (closest == null || closestMeters == null) return null;
    debugPrint(
      '[TripSearch] nearest stop="${closest.name}" meters=${closestMeters.toStringAsFixed(1)}',
    );
    return NearestStop(stop: closest, distanceKm: closestMeters / 1000);
  }

  Future<List<LineRoute>> fetchRoutesForStopIds(Set<String> stopIds) async {
    if (stopIds.isEmpty) return const [];
    debugPrint('[TripSearch] fetchRoutesForStopIds count=${stopIds.length}');
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
    required String fromLabel,
    required String toLabel,
    Map<String, double>? fromWalkKmByStopId,
    Map<String, double>? toWalkKmByStopId,
  }) {
    debugPrint(
      '[TripSearch] buildDirectTrips routes=${routes.length} from=${fromStops.length} to=${toStops.length}',
    );
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
          final walkFromKm = fromWalkKmByStopId?[fromEntry.key] ?? 0;
          final walkToKm = toWalkKmByStopId?[toEntry.key] ?? 0;
          final busKm = max(0.5, stopCount * 0.6);
          final totalKm = busKm + walkFromKm + walkToKm;
          final walkMinutes = _walkMinutes(walkFromKm + walkToKm);
          final busMinutes = max(5, stopCount * 4);

          trips.add(
            TripOption(
              lineName: route.lineName,
              isDirect: true,
              durationMinutes: busMinutes + walkMinutes,
              priceTnd: max(1.0, stopCount * 0.4),
              distanceKm: totalKm,
              stops: stopCount,
              nextDeparture: '--',
              departureTimes: const [],
              path: _buildDirectPath(
                fromLabel: fromLabel,
                toLabel: toLabel,
                fromStopName: fromEntry.value.name,
                toStopName: toEntry.value.name,
                lineName: route.lineName,
                stopCount: stopCount,
              ),
            ),
          );
        }
      }
    }

    debugPrint('[TripSearch] direct trips=${trips.length}');
    return trips;
  }

  List<TripOption> buildTransferTrips({
    required List<LineRoute> routes,
    required List<StopLocation> fromStops,
    required List<StopLocation> toStops,
    required String fromLabel,
    required String toLabel,
    Map<String, double>? fromWalkKmByStopId,
    Map<String, double>? toWalkKmByStopId,
  }) {
    debugPrint(
      '[TripSearch] buildTransferTrips routes=${routes.length} from=${fromStops.length} to=${toStops.length}',
    );
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
            final walkFromKm = fromWalkKmByStopId?[fromEntry.key] ?? 0;
            final walkToKm = toWalkKmByStopId?[toEntry.key] ?? 0;
            final busKm = max(1.0, stopCount * 0.7);
            final totalKm = busKm + walkFromKm + walkToKm;
            final walkMinutes = _walkMinutes(walkFromKm + walkToKm);
            final busMinutes = max(10, stopCount * 5);

            trips.add(
              TripOption(
                lineName: '${routeA.lineName} + ${routeB.lineName}',
                isDirect: false,
                durationMinutes: busMinutes + walkMinutes + 5,
                priceTnd: max(1.5, stopCount * 0.5),
                distanceKm: totalKm,
                stops: stopCount,
                nextDeparture: '--',
                departureTimes: const [],
                path: _buildTransferPath(
                  fromLabel: fromLabel,
                  toLabel: toLabel,
                  fromStopName: fromEntry.value.name,
                  toStopName: toEntry.value.name,
                  lineA: routeA.lineName,
                  lineB: routeB.lineName,
                  stopCount: stopCount,
                ),
              ),
            );
          }
        }
      }
    }

    debugPrint('[TripSearch] transfer trips=${trips.length}');
    return trips;
  }

  String? _findTransferStop(LineRoute routeA, LineRoute routeB) {
    final setB = routeB.stopIds.toSet();
    for (final stopId in routeA.stopIds) {
      if (setB.contains(stopId)) return stopId;
    }
    return null;
  }

  List<TripStop> _buildDirectPath({
    required String fromLabel,
    required String toLabel,
    required String fromStopName,
    required String toStopName,
    required String lineName,
    required int stopCount,
  }) {
    final walkToStop = _isSamePlace(fromLabel, fromStopName)
        ? 'Arret de depart'
        : 'Marche jusqu\'a $fromStopName';
    final walkToDestination = _isSamePlace(toLabel, toStopName)
        ? 'Arret d\'arrivee'
        : 'Marche jusqu\'a destination';

    return [
      TripStop(
        name: fromLabel,
        label: walkToStop,
        kind: TripStopKind.start,
      ),
      TripStop(
        name: fromStopName,
        label: '$lineName \u2022 $stopCount arrets',
        kind: TripStopKind.middle,
      ),
      TripStop(
        name: toStopName,
        label: 'Descendre du bus',
        kind: TripStopKind.middle,
      ),
      TripStop(
        name: toLabel,
        label: walkToDestination,
        kind: TripStopKind.end,
      ),
    ];
  }

  List<TripStop> _buildTransferPath({
    required String fromLabel,
    required String toLabel,
    required String fromStopName,
    required String toStopName,
    required String lineA,
    required String lineB,
    required int stopCount,
  }) {
    final walkToStop = _isSamePlace(fromLabel, fromStopName)
        ? 'Arret de depart'
        : 'Marche jusqu\'a $fromStopName';
    final walkToDestination = _isSamePlace(toLabel, toStopName)
        ? 'Arret d\'arrivee'
        : 'Marche jusqu\'a destination';

    return [
      TripStop(
        name: fromLabel,
        label: walkToStop,
        kind: TripStopKind.start,
      ),
      TripStop(
        name: fromStopName,
        label: '$lineA \u2022 $stopCount arrets',
        kind: TripStopKind.middle,
      ),
      TripStop(
        name: 'Correspondance',
        label: 'Changer vers $lineB',
        kind: TripStopKind.middle,
      ),
      TripStop(
        name: toStopName,
        label: 'Descendre du bus',
        kind: TripStopKind.middle,
      ),
      TripStop(
        name: toLabel,
        label: walkToDestination,
        kind: TripStopKind.end,
      ),
    ];
  }

  int _walkMinutes(double km) {
    if (km <= 0) return 0;
    return ((km / 4.5) * 60).round();
  }

  bool _isSamePlace(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  List<TripOption> _dedupeTrips(List<TripOption> trips) {
    final seen = <String>{};
    final unique = <TripOption>[];
    for (final trip in trips) {
      final key = '${trip.lineName}|${trip.stops}|${trip.path.length}';
      if (seen.add(key)) {
        unique.add(trip);
      }
    }
    return unique;
  }
}

class NearestStop {
  const NearestStop({required this.stop, required this.distanceKm});

  final StopLocation stop;
  final double distanceKm;
}
