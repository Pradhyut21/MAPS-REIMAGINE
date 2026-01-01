import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/saved_place.dart';

class SavedPlaceService {
  static const String _savedPlacesKey = 'saved_places';

  Future<List<SavedPlace>> getAllSavedPlaces(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlacesJson = prefs.getString(_savedPlacesKey);
      
      if (savedPlacesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(savedPlacesJson);
      final allPlaces = decoded.map((json) => SavedPlace.fromJson(json)).toList();
      return allPlaces.where((p) => p.userId == userId).toList();
    } catch (e) {
      debugPrint('Error loading saved places: $e');
      return [];
    }
  }

  Future<void> addSavedPlace(SavedPlace place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlacesJson = prefs.getString(_savedPlacesKey);
      
      List<SavedPlace> places = [];
      if (savedPlacesJson != null) {
        final List<dynamic> decoded = jsonDecode(savedPlacesJson);
        places = decoded.map((json) => SavedPlace.fromJson(json)).toList();
      }
      
      places.add(place);
      
      final jsonString = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_savedPlacesKey, jsonString);
    } catch (e) {
      debugPrint('Error adding saved place: $e');
    }
  }

  Future<void> removeSavedPlace(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlacesJson = prefs.getString(_savedPlacesKey);
      
      if (savedPlacesJson == null) return;

      final List<dynamic> decoded = jsonDecode(savedPlacesJson);
      final places = decoded.map((json) => SavedPlace.fromJson(json)).toList();
      
      places.removeWhere((p) => p.id == id);
      
      final jsonString = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_savedPlacesKey, jsonString);
    } catch (e) {
      debugPrint('Error removing saved place: $e');
    }
  }

  Future<bool> isPlaceSaved(String userId, String placeId) async {
    final savedPlaces = await getAllSavedPlaces(userId);
    return savedPlaces.any((p) => p.placeId == placeId);
  }
}
