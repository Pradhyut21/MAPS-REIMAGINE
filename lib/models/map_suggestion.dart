import 'package:flutter/foundation.dart';

class MapSuggestion {
  final String title;
  final String subtitle;
  final double lat;
  final double lon;

  MapSuggestion({required this.title, required this.subtitle, required this.lat, required this.lon});

  factory MapSuggestion.fromJson(Map<String, dynamic> json) {
    try {
      final display = json['display_name'] as String? ?? '';
      final parts = display.split(',');
      final title = parts.isNotEmpty ? parts.first.trim() : display;
      final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
      final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
      final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
      return MapSuggestion(title: title, subtitle: subtitle, lat: lat, lon: lon);
    } catch (e) {
      debugPrint('MapSuggestion parse error: $e');
      return MapSuggestion(title: 'Unknown', subtitle: '', lat: 0, lon: 0);
    }
  }
}
