import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BusPlatform {
  final String name;
  final String? ref;
  final double lat;
  final double lon;
  BusPlatform({required this.name, this.ref, required this.lat, required this.lon});
}

class OverpassService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<BusPlatform>> getNearbyBusPlatforms(double lat, double lon, {int radiusMeters = 600}) async {
    final q = '[out:json][timeout:15];('
        'node["public_transport"="platform"]["bus"](around:$radiusMeters,$lat,$lon);'
        'node["highway"="bus_stop"](around:$radiusMeters,$lat,$lon);'
        'way["highway"="platform"]["bus"](around:$radiusMeters,$lat,$lon);'
        ');out center 20;';
    try {
      final res = await http.post(Uri.parse(_endpoint), body: {'data': q}, headers: {'User-Agent': 'wayfinder-app/1.0 (dreamflow)'});
      if (res.statusCode != 200) {
        debugPrint('Overpass ${res.statusCode}: ${res.body}');
        return [];
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? [];
      return elements.map((e) {
        final tags = (e['tags'] as Map?) ?? {};
        final name = (tags['name'] as String?) ?? (tags['ref'] as String?) ?? 'Platform';
        final ref = tags['ref'] as String?;
        double plat = (e['lat'] as num?)?.toDouble() ?? (e['center']?['lat'] as num?)?.toDouble() ?? lat;
        double plon = (e['lon'] as num?)?.toDouble() ?? (e['center']?['lon'] as num?)?.toDouble() ?? lon;
        return BusPlatform(name: name, ref: ref, lat: plat, lon: plon);
      }).toList();
    } catch (e) {
      debugPrint('Overpass error: $e');
      return [];
    }
  }

  /// Returns the nearest major bus station/stand near the given point.
  /// Useful for showing a suggested origin stand in the Transport UI.
  Future<BusPlatform?> getNearestBusStation(double lat, double lon, {int radiusMeters = 3000}) async {
    final q = '[out:json][timeout:15];('
        'node["amenity"="bus_station"](around:$radiusMeters,$lat,$lon);'
        'way["amenity"="bus_station"](around:$radiusMeters,$lat,$lon);'
        'relation["amenity"="bus_station"](around:$radiusMeters,$lat,$lon);'
        'node["public_transport"="station"]["bus"="yes"](around:$radiusMeters,$lat,$lon);'
        ');out center 10;';
    try {
      final res = await http.post(Uri.parse(_endpoint), body: {'data': q}, headers: {'User-Agent': 'wayfinder-app/1.0 (dreamflow)'});
      if (res.statusCode != 200) {
        debugPrint('Overpass ${res.statusCode}: ${res.body}');
        return null;
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? [];
      if (elements.isEmpty) return null;
      final e = elements.first;
      final tags = (e['tags'] as Map?) ?? {};
      final name = (tags['name'] as String?) ?? 'Bus Station';
      final ref = tags['ref'] as String?;
      final plat = (e['lat'] as num?)?.toDouble() ?? (e['center']?['lat'] as num?)?.toDouble() ?? lat;
      final plon = (e['lon'] as num?)?.toDouble() ?? (e['center']?['lon'] as num?)?.toDouble() ?? lon;
      return BusPlatform(name: name, ref: ref, lat: plat, lon: plon);
    } catch (e) {
      debugPrint('Overpass station error: $e');
      return null;
    }
  }
}
