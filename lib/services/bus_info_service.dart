import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:wayfinder/models/bus_route_info.dart';
import 'package:wayfinder/openai/openai_config.dart';
import 'package:wayfinder/services/city_transit_registry.dart';

class BusInfoService {
  final OpenAIClient _client;
  BusInfoService({OpenAIClient? client}) : _client = client ?? OpenAIClient(model: 'gpt-4o-mini');

  Future<BusRouteInfo?> fetchRouteInfo({
    required String fromTitle,
    required double fromLat,
    required double fromLon,
    required String toTitle,
    required double toLat,
    required double toLon,
    List<Map<String, String?>> destinationPlatforms = const [],
    CityTransitContext? city,
    List<String> candidateRouteRefs = const [],
  }) async {
    try {
      final schema = {
        'type': 'object',
        'properties': {
          'next_departure_local': {'type': 'string', 'description': 'Time for the next bus in local time, e.g., 14:25'},
          'typical_frequency': {'type': 'string', 'description': 'Typical frequency text, e.g., every 10–15 min'},
          'platform_hint': {'type': 'string', 'description': 'Likely platform/bay description, add (usually)'},
          'operator': {'type': 'string', 'description': 'Likely operator, e.g., KSRTC/State RTC/Private'},
          'route_number': {'type': 'string', 'description': 'Common route number if applicable'},
          'duration_minutes_estimate': {'type': 'number', 'description': 'Estimated travel time in minutes'},
          'fare_estimate': {'type': 'string', 'description': 'Approximate fare with currency if possible'},
          'destination_details': {'type': 'string', 'description': 'Key arrival info, major stop names/landmarks'},
          'notes': {'type': 'string', 'description': 'Caveats such as timing variance, holiday schedules'},
          'confidence': {'type': 'string', 'enum': ['low', 'medium', 'high']},
        },
        'required': ['next_departure_local', 'platform_hint', 'operator', 'destination_details', 'typical_frequency', 'confidence', 'route_number'],
        'additionalProperties': true,
      };

      final extra = {
        'message': 'Output must be a JSON object that conforms to the provided schema.',
        'schema': schema,
      };

      final platformSnippet = destinationPlatforms.isEmpty
          ? 'No detected platforms near destination.'
          : 'Detected platforms near destination: ${destinationPlatforms.map((p) => (p['name'] ?? '') + (p['ref'] != null && p['ref']!.isNotEmpty ? ' (${p['ref']})' : '')).take(8).join(', ')}';

      final operatorHint = city != null ? 'Prioritize the local city operator: ${city.operatorName} in ${city.cityName}. If route numbers are typical, use them.' : 'Use a realistic local city operator if applicable.';
      final hubHint = city != null && city.majorHubs.isNotEmpty ? 'Common hubs include: ${city.majorHubs.join(', ')}.' : '';
      final routeHint = candidateRouteRefs.isNotEmpty ? 'Likely route numbers near both ends: ${candidateRouteRefs.join(', ')}. Prefer one of these if sensible.' : '';
      final prompt = '''
You are determining city bus info between two areas.
From: "$fromTitle" (lat: $fromLat, lon: $fromLon)
To: "$toTitle" (lat: $toLat, lon: $toLon)
$platformSnippet
$operatorHint $hubHint $routeHint

Task: Provide the next likely departure time (local time), typical frequency, a platform/bay hint (mark as usually if not certain), the likely operator name, a route number if commonly used (choose from hints if provided), estimated travel time and fare, plus concise destination_details about where to alight and landmarks. If exact data is unknown, give a locally realistic heuristic and include a note to verify at the stand enquiry counter. Keep outputs applicable to the city; avoid intercity RTC when a city operator exists.
Return only a JSON object per schema.
''';

      final json = await _client.chatJson(prompt, extraSystem: extra);
      if (json.isEmpty) return null;

      // Sanitize and enrich missing fields to guarantee fare and details.
      _ensureDefaults(
        json: json,
        toTitle: toTitle,
        fromLat: fromLat,
        fromLon: fromLon,
        toLat: toLat,
        toLon: toLon,
        city: city,
        destinationPlatforms: destinationPlatforms,
        candidateRouteRefs: candidateRouteRefs,
      );
      return BusRouteInfo.fromJson(json);
    } catch (e) {
      debugPrint('BusInfoService.fetchRouteInfo error: $e');
      // Offline heuristic fallback so the UI shows something useful (e.g., BMTC in Bengaluru)
      try {
        final operatorName = city?.operatorName ?? 'City Bus';
        String platform = 'Platform (usually)';
        if (destinationPlatforms.isNotEmpty) {
          platform = '${destinationPlatforms.first['name']}${(destinationPlatforms.first['ref'] ?? '').isNotEmpty ? ' (${destinationPlatforms.first['ref']})' : ''} (usually)';
        }
        final routeNum = candidateRouteRefs.isNotEmpty ? candidateRouteRefs.first : '';
        final km = _distanceKm(fromLat, fromLon, toLat, toLon);
        final fare = _estimateFareRange(km, city);
        final info = BusRouteInfo(
          nextDepartureLocal: 'in ~5–15 min',
          platformHint: platform,
          operatorName: operatorName,
          routeNumber: routeNum,
          frequency: 'every 5–15 min (typical)',
          destinationDetails: 'Alight near "$toTitle"; check stop name on the bus LED.',
          notes: 'Heuristic estimate. Verify at the stand enquiry counter.',
          confidence: 'low',
          durationMinutes: null,
          fareEstimate: fare,
        );
        return info;
      } catch (e2) {
        debugPrint('BusInfoService fallback failed: $e2');
        return null;
      }
    }
  }

  // Ensures the JSON has fare_estimate, platform_hint, destination_details, frequency, and route_number.
  void _ensureDefaults({
    required Map<String, dynamic> json,
    required String toTitle,
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
    CityTransitContext? city,
    List<Map<String, String?>> destinationPlatforms = const [],
    List<String> candidateRouteRefs = const [],
  }) {
    // Fare
    final fareRaw = (json['fare_estimate'] ?? '').toString().trim();
    if (fareRaw.isEmpty) {
      final km = _distanceKm(fromLat, fromLon, toLat, toLon);
      json['fare_estimate'] = _estimateFareRange(km, city);
    }

    // Platform hint
    final plat = (json['platform_hint'] ?? '').toString().trim();
    if (plat.isEmpty) {
      if (destinationPlatforms.isNotEmpty) {
        final first = destinationPlatforms.first;
        final name = (first['name'] ?? 'Platform').toString();
        final ref = (first['ref'] ?? '').toString();
        json['platform_hint'] = ref.isNotEmpty ? '$name ($ref) (usually)' : '$name (usually)';
      } else {
        json['platform_hint'] = 'Platform (usually)';
      }
    }

    // Destination details
    final dest = (json['destination_details'] ?? '').toString().trim();
    if (dest.isEmpty) {
      json['destination_details'] = 'Alight near "$toTitle"; check stop name on the bus LED.';
    }

    // Frequency
    final freq = (json['typical_frequency'] ?? json['typical_frequency_minutes'] ?? '').toString().trim();
    if (freq.isEmpty) {
      json['typical_frequency'] = 'every 5–15 min (typical)';
    }

    // Route number
    final routeNum = (json['route_number'] ?? '').toString().trim();
    if (routeNum.isEmpty && candidateRouteRefs.isNotEmpty) {
      json['route_number'] = candidateRouteRefs.first;
    }

    // Next departure local
    final next = (json['next_departure_local'] ?? '').toString().trim();
    if (next.isEmpty) {
      json['next_departure_local'] = 'in ~5–15 min';
    }
  }

  // Very small haversine helper
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (R * c).abs();
  }

  double _deg2rad(double d) => d * 3.141592653589793 / 180.0;

  // Heuristic fare estimation by city/operator with a rounded range
  String _estimateFareRange(double km, CityTransitContext? city) {
    // Guard against zero distance
    final d = km.clamp(1.0, 50.0);
    double perKm = 2.5;
    double minBase = 5;
    double maxCap = 60;
    final op = (city?.operatorName ?? '').toUpperCase();
    if (op.contains('BMTC')) {
      perKm = 3.5; minBase = 5; maxCap = 70;
    } else if (op.contains('DTC')) {
      perKm = 2.5; minBase = 5; maxCap = 50;
    } else if (op.contains('MTC')) {
      perKm = 2.4; minBase = 5; maxCap = 50;
    } else if (op.contains('BEST')) {
      perKm = 4.0; minBase = 6; maxCap = 80;
    } else if (op.contains('TSRTC')) {
      perKm = 2.6; minBase = 5; maxCap = 55;
    } else if (op.contains('WBTC')) {
      perKm = 2.2; minBase = 5; maxCap = 50;
    }
    double est = (minBase + perKm * d);
    est = est.clamp(minBase, maxCap);
    // Build a +-20% range and round to nearest 5
    double low = _round5(est * 0.85);
    double high = _round5(est * 1.15);
    if (low >= high) high = low + 5;
    return '₹${low.toInt()}–₹${high.toInt()} (approx.)';
  }

  double _round5(double v) => (v / 5.0).round() * 5.0;
}
