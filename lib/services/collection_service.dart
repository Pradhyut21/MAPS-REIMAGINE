import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/collection.dart';
import 'package:wayfinder/models/saved_place.dart';

class CollectionService {
  static const String _collectionsKey = 'collections';
  static const String _collectionLinksKey = 'collection_links'; // collectionId -> [savedPlaceId]

  Future<List<Collection>> getCollections(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_collectionsKey);
      if (jsonStr == null) return [];
      final List list = jsonDecode(jsonStr) as List;
      final all = list.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
      return all.where((c) => c.userId == userId).toList();
    } catch (e) {
      debugPrint('Error getCollections: $e');
      return [];
    }
  }

  Future<Collection> ensureDefaultFavorites(String userId) async {
    final existing = await getCollections(userId);
    final fav = existing.where((c) => c.name.toLowerCase() == 'favorites').toList();
    if (fav.isNotEmpty) return fav.first;
    final c = Collection(id: 'col_${DateTime.now().millisecondsSinceEpoch}', userId: userId, name: 'Favorites', createdAt: DateTime.now(), updatedAt: DateTime.now());
    await upsertCollection(c);
    return c;
  }

  Future<void> upsertCollection(Collection c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getCollections(c.userId);
      final others = list.where((e) => e.id != c.id).toList();
      others.add(c);
      final jsonStr = jsonEncode(others.map((e) => e.toJson()).toList());
      await prefs.setString(_collectionsKey, jsonStr);
    } catch (e) {
      debugPrint('Error upsertCollection: $e');
    }
  }

  Future<void> deleteCollection(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getCollections(userId);
      final kept = list.where((e) => e.id != id).toList();
      await prefs.setString(_collectionsKey, jsonEncode(kept.map((e) => e.toJson()).toList()));
      final links = await _getLinksMap();
      links.remove(id);
      await prefs.setString(_collectionLinksKey, jsonEncode(links));
    } catch (e) {
      debugPrint('Error deleteCollection: $e');
    }
  }

  Future<Map<String, List<String>>> _getLinksMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_collectionLinksKey);
      if (jsonStr == null) return {};
      final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()));
    } catch (e) {
      debugPrint('Error _getLinksMap: $e');
      return {};
    }
  }

  Future<void> addPlaceToCollection({required String collectionId, required SavedPlace place}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final links = await _getLinksMap();
      final list = links[collectionId] ?? <String>[];
      if (!list.contains(place.id)) list.add(place.id);
      links[collectionId] = list;
      await prefs.setString(_collectionLinksKey, jsonEncode(links));
    } catch (e) {
      debugPrint('Error addPlaceToCollection: $e');
    }
  }

  Future<void> removePlaceFromCollection({required String collectionId, required String savedPlaceId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final links = await _getLinksMap();
      final list = links[collectionId] ?? <String>[];
      list.remove(savedPlaceId);
      links[collectionId] = list;
      await prefs.setString(_collectionLinksKey, jsonEncode(links));
    } catch (e) {
      debugPrint('Error removePlaceFromCollection: $e');
    }
  }

  Future<List<SavedPlace>> getPlacesInCollection({required String userId, required String collectionId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final links = await _getLinksMap();
      final ids = links[collectionId] ?? <String>[];
      final savedJson = prefs.getString('saved_places');
      if (savedJson == null) return [];
      final List decoded = jsonDecode(savedJson) as List;
      final all = decoded.map((e) => SavedPlace.fromJson(e)).toList();
      return all.where((p) => p.userId == userId && ids.contains(p.id)).toList();
    } catch (e) {
      debugPrint('Error getPlacesInCollection: $e');
      return [];
    }
  }
}
