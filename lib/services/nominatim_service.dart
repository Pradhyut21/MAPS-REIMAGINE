import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wayfinder/models/map_suggestion.dart';

class NominatimService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<MapSuggestion>> search(String query, {int limit = 8}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': limit.toString(),
      });
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'wayfinder-app/1.0 (dreamflow)',
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.map((e) => MapSuggestion.fromJson(e as Map<String, dynamic>)).toList();
      }
      debugPrint('Nominatim status ${res.statusCode}: ${res.body}');
      return [];
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return [];
    }
  }
}
