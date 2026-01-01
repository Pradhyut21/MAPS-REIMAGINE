class BusRouteInfo {
  final String nextDepartureLocal; // e.g., 14:25
  final String platformHint; // e.g., Platform 3 (usually)
  final String operatorName; // e.g., KSRTC
  final String routeNumber; // may be empty
  final int? durationMinutes; // estimate
  final String? fareEstimate; // e.g., ₹55–₹70
  final String frequency; // e.g., every 10–15 min
  final String destinationDetails; // brief text about stop/landmarks
  final String notes; // caveats
  final String confidence; // low/medium/high

  BusRouteInfo({
    required this.nextDepartureLocal,
    required this.platformHint,
    required this.operatorName,
    required this.routeNumber,
    required this.frequency,
    required this.destinationDetails,
    required this.notes,
    required this.confidence,
    this.durationMinutes,
    this.fareEstimate,
  });

  factory BusRouteInfo.fromJson(Map<String, dynamic> j) => BusRouteInfo(
        nextDepartureLocal: (j['next_departure_local'] ?? '').toString(),
        platformHint: (j['platform_hint'] ?? '').toString(),
        operatorName: (j['operator'] ?? '').toString(),
        routeNumber: (j['route_number'] ?? '').toString(),
        durationMinutes: j['duration_minutes_estimate'] is num ? (j['duration_minutes_estimate'] as num).toInt() : null,
        fareEstimate: j['fare_estimate']?.toString(),
        frequency: (j['typical_frequency'] ?? j['typical_frequency_minutes'] ?? '').toString(),
        destinationDetails: (j['destination_details'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        confidence: (j['confidence'] ?? '').toString(),
      );
}
