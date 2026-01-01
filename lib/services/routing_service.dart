import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction;
  final double distanceMeters;
  RouteStep({required this.instruction, required this.distanceMeters});
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final List<RouteStep> steps;

  RouteResult({required this.points, required this.distanceKm, required this.durationMin, required this.steps});
}

class RoutingService {
  static const String _base = 'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse('$_base/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true');
      final res = await http.get(url, headers: {'User-Agent': 'wayfinder-app/1.0 (dreamflow)'});
      if (res.statusCode != 200) {
        debugPrint('OSRM status ${res.statusCode}: ${res.body}');
        return null;
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map<String, dynamic>;
      final double distance = (r['distance'] as num).toDouble() / 1000.0;
      final double duration = (r['duration'] as num).toDouble() / 60.0;
      final geometry = r['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;
      final points = coords.map((c) {
        final lon = (c as List)[0] as num;
        final lat = (c)[1] as num;
        return LatLng(lat.toDouble(), lon.toDouble());
      }).toList();

      // Parse steps into human-readable instructions
      final List<RouteStep> steps = [];
      final legs = (r['legs'] as List?) ?? [];
      if (legs.isNotEmpty) {
        final firstLeg = legs.first as Map<String, dynamic>;
        final legSteps = (firstLeg['steps'] as List?) ?? [];
        for (final s in legSteps) {
          final ms = s as Map<String, dynamic>;
          final maneuver = (ms['maneuver'] as Map<String, dynamic>?);
          final type = (maneuver?['type'] ?? '').toString();
          final modifier = (maneuver?['modifier'] ?? '').toString();
          final name = (ms['name'] ?? '').toString();
          final dist = (ms['distance'] as num?)?.toDouble() ?? 0.0;
          String road = name.isEmpty ? 'the road' : name;
          String instruction;
          switch (type) {
            case 'depart':
              instruction = modifier.isNotEmpty ? 'Head ${modifier.toLowerCase()} on $road' : 'Head on $road';
              break;
            case 'turn':
              instruction = 'Turn ${modifier.toLowerCase()} onto $road';
              break;
            case 'roundabout':
              instruction = 'Enter the roundabout and continue towards $road';
              break;
            case 'merge':
              instruction = 'Merge ${modifier.toLowerCase()} onto $road';
              break;
            case 'new name':
            case 'continue':
              instruction = 'Continue onto $road';
              break;
            case 'arrive':
              instruction = 'You have arrived';
              break;
            default:
              instruction = 'Continue on $road';
          }
          steps.add(RouteStep(instruction: instruction, distanceMeters: dist));
        }
      }
      return RouteResult(points: points, distanceKm: distance, durationMin: duration, steps: steps);
    } catch (e) {
      debugPrint('Routing error: $e');
      return null;
    }
  }
}
