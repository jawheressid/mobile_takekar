class TripStop {
  const TripStop({required this.name, required this.label, required this.kind});

  final String name;
  final String label; 
  final TripStopKind kind;
}

enum TripStopKind { start, middle, end }

class TripOption {
  const TripOption({
    required this.lineName,
    required this.isDirect,
    required this.durationMinutes,
    required this.priceTnd,
    required this.distanceKm,
    required this.stops,
    required this.nextDeparture,
    required this.departureTimes,
    required this.path,
  });

  final String lineName; 
  final bool isDirect;
  final int durationMinutes;
  final double priceTnd;
  final double distanceKm;
  final int stops;
  final String nextDeparture; 
  final List<String> departureTimes;
  final List<TripStop> path;
}
