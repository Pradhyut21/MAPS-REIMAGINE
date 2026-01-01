import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/place.dart';

class PlaceService {
  static const String _placesKey = 'places';

  Future<List<Place>> getAllPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final placesJson = prefs.getString(_placesKey);
      
      if (placesJson == null) {
        final samplePlaces = _getSamplePlaces();
        await _savePlaces(samplePlaces);
        return samplePlaces;
      }

      final List<dynamic> decoded = jsonDecode(placesJson);
      return decoded.map((json) => Place.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading places: $e');
      return _getSamplePlaces();
    }
  }

  Future<List<Place>> getPlacesByType(PlaceType type) async {
    final places = await getAllPlaces();
    return places.where((p) => p.type == type).toList();
  }

  Future<List<Place>> searchPlaces(String query, {PlaceType? type}) async {
    final places = await getAllPlaces();
    final lowerQuery = query.toLowerCase();
    
    return places.where((place) {
      final matchesQuery = place.name.toLowerCase().contains(lowerQuery) ||
          place.address.toLowerCase().contains(lowerQuery) ||
          (place.category?.toLowerCase().contains(lowerQuery) ?? false);
      
      final matchesType = type == null || place.type == type;
      
      return matchesQuery && matchesType;
    }).toList();
  }

  Future<List<Place>> getNearbyPlaces(double lat, double lon, {PlaceType? type, double maxDistanceKm = 10}) async {
    final places = await getAllPlaces();
    
    return places.where((place) {
      final matchesType = type == null || place.type == type;
      final distance = place.distanceFrom(lat, lon);
      return matchesType && distance <= maxDistanceKm;
    }).toList()
      ..sort((a, b) => a.distanceFrom(lat, lon).compareTo(b.distanceFrom(lat, lon)));
  }

  Future<void> _savePlaces(List<Place> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final placesJson = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_placesKey, placesJson);
    } catch (e) {
      debugPrint('Error saving places: $e');
    }
  }

  List<Place> _getSamplePlaces() {
    final now = DateTime.now();
    return [
      Place(id: '1', name: 'Mavalli Tiffin Rooms', address: '14, Lalbagh Road', latitude: 12.9465, longitude: 77.5847, type: PlaceType.restaurant, category: 'restaurant', rating: 4.5, phoneNumber: '+91 80 2222 0022', createdAt: now, updatedAt: now),
      Place(id: '2', name: 'Sukh Sagar', address: 'MG Road', latitude: 12.9716, longitude: 77.5946, type: PlaceType.restaurant, category: 'restaurant', rating: 4.2, phoneNumber: '+91 80 4112 4112', createdAt: now, updatedAt: now),
      Place(id: '3', name: 'Adyar Ananda Bhavan', address: 'Jayanagar', latitude: 12.9250, longitude: 77.5838, type: PlaceType.restaurant, category: 'restaurant', rating: 4.3, phoneNumber: '+91 80 2663 3730', createdAt: now, updatedAt: now),
      Place(id: '4', name: 'Sri Raghavendra Restaurant', address: 'Indiranagar', latitude: 12.9716, longitude: 77.6412, type: PlaceType.restaurant, category: 'restaurant', rating: 4.4, phoneNumber: '+91 80 2520 4040', createdAt: now, updatedAt: now),
      Place(id: '5', name: 'Vidyarthi Bhavan', address: 'Gandhi Bazaar', latitude: 12.9380, longitude: 77.5760, type: PlaceType.restaurant, category: 'restaurant', rating: 4.6, phoneNumber: '+91 80 2667 7588', createdAt: now, updatedAt: now),
      Place(id: '6', name: 'Lalbagh Glasshouse', address: 'Lalbagh Botanical Garden', latitude: 12.9507, longitude: 77.5848, type: PlaceType.attraction, category: 'attraction', rating: 4.7, description: 'Historic glasshouse with beautiful flower shows', createdAt: now, updatedAt: now),
      Place(id: '7', name: 'Ganesha Temple', address: 'Basavanagudi', latitude: 12.9421, longitude: 77.5752, type: PlaceType.attraction, category: 'attraction', rating: 4.8, description: 'Ancient temple dedicated to Lord Ganesha', createdAt: now, updatedAt: now),
      Place(id: '8', name: 'Chickpet Cross', address: 'Chickpet', latitude: 12.9613, longitude: 77.5789, type: PlaceType.attraction, category: 'attraction', rating: 4.3, description: 'Busy shopping district', createdAt: now, updatedAt: now),
      Place(id: '9', name: 'Rajarajeshwari Arch', address: 'Jayanagar 4th Block', latitude: 12.9247, longitude: 77.5931, type: PlaceType.attraction, category: 'attraction', rating: 4.5, description: 'Iconic landmark arch', createdAt: now, updatedAt: now),
      Place(id: '10', name: 'Victoria Hospital', address: 'Fort Area', latitude: 12.9698, longitude: 77.5802, type: PlaceType.hospital, category: 'hospital', phoneNumber: '+91 80 2670 1150', description: 'Major government hospital', createdAt: now, updatedAt: now),
      Place(id: '11', name: 'Jayanagar General Hospital', address: 'Jayanagar 3rd Block', latitude: 12.9300, longitude: 77.5850, type: PlaceType.hospital, category: 'hospital', phoneNumber: '+91 80 2665 3214', description: 'Community hospital', createdAt: now, updatedAt: now),
      Place(id: '12', name: 'Apollo Hospital', address: 'Bannerghatta Road', latitude: 12.8996, longitude: 77.5977, type: PlaceType.hospital, category: 'hospital', phoneNumber: '+91 80 2630 2211', description: 'Multi-specialty hospital', createdAt: now, updatedAt: now),
      Place(id: '13', name: 'Halasuru Police Station', address: 'Halasuru', latitude: 12.9833, longitude: 77.6187, type: PlaceType.police, category: 'police', phoneNumber: '100', description: 'Local police station', createdAt: now, updatedAt: now),
      Place(id: '14', name: 'Jayanagar Police Station', address: 'Jayanagar 4th Block', latitude: 12.9263, longitude: 77.5937, type: PlaceType.police, category: 'police', phoneNumber: '100', description: 'Local police station', createdAt: now, updatedAt: now),
    ];
  }
}
