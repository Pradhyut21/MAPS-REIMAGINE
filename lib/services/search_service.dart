import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/search_history.dart';

class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;

  Future<List<SearchHistory>> getSearchHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      
      if (historyJson == null) return [];

      final List<dynamic> decoded = jsonDecode(historyJson);
      final allHistory = decoded.map((json) => SearchHistory.fromJson(json)).toList();
      final userHistory = allHistory.where((h) => h.userId == userId).toList();
      
      userHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return userHistory.take(_maxHistoryItems).toList();
    } catch (e) {
      debugPrint('Error loading search history: $e');
      return [];
    }
  }

  Future<void> addSearchHistory(SearchHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      
      List<SearchHistory> historyList = [];
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        historyList = decoded.map((json) => SearchHistory.fromJson(json)).toList();
      }
      
      historyList.removeWhere((h) => 
        h.userId == history.userId && 
        h.searchQuery.toLowerCase() == history.searchQuery.toLowerCase()
      );
      
      historyList.insert(0, history);
      
      if (historyList.length > _maxHistoryItems * 2) {
        historyList = historyList.take(_maxHistoryItems * 2).toList();
      }
      
      final jsonString = jsonEncode(historyList.map((h) => h.toJson()).toList());
      await prefs.setString(_searchHistoryKey, jsonString);
    } catch (e) {
      debugPrint('Error adding search history: $e');
    }
  }

  Future<void> clearSearchHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      
      if (historyJson == null) return;

      final List<dynamic> decoded = jsonDecode(historyJson);
      final historyList = decoded.map((json) => SearchHistory.fromJson(json)).toList();
      
      historyList.removeWhere((h) => h.userId == userId);
      
      final jsonString = jsonEncode(historyList.map((h) => h.toJson()).toList());
      await prefs.setString(_searchHistoryKey, jsonString);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }
}
