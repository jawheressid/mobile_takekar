class LineRoute {
  const LineRoute({
    required this.id,
    required this.lineId,
    required this.lineName,
    required this.direction,
    required this.stopIds,
  });

  final String id;
  final String lineId;
  final String lineName;
  final int direction;
  final List<String> stopIds;

  static LineRoute? fromDoc(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final lineId = data['lineId'];
    final lineName = data['lineName'];
    final direction = data['direction'];
    final stopIds = data['stopIds'];
    if (lineId is! String || lineName is! String || stopIds is! List) {
      return null;
    }

    return LineRoute(
      id: id,
      lineId: lineId,
      lineName: lineName,
      direction: direction is num ? direction.toInt() : 0,
      stopIds: stopIds
          .map((e) => e is String ? e.trim() : null)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}
