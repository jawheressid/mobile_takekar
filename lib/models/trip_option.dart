class TripStop {
  const TripStop({required this.name, required this.label, required this.kind});

  final String name;
  final String label; // Exemple: "Départ", "Arrêt 1", "Arrivée"
  final TripStopKind kind;
}

enum TripStopKind { start, middle, end }

class TripOption {
  const TripOption({
    required this.lineName,
    required this.direction,
    required this.isDirect,
    required this.durationMinutes,
    required this.priceTnd,
    required this.distanceKm,
    required this.stops,
    required this.fromStopName,
    required this.toStopName,
    required this.nextDeparture,
    required this.departureTimes,
    required this.path,
  });

  final String lineName; // Exemple: "Ligne 3"
  final int direction;
  final bool isDirect;
  final int durationMinutes;
  final double priceTnd;
  final double distanceKm;
  final int stops;
  final String fromStopName;
  final String toStopName;
  final String nextDeparture; // Exemple: "08:00"
  final List<String> departureTimes;
  final List<TripStop> path;
}
