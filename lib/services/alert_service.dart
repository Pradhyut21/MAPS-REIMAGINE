import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/travel_alert.dart';

class AlertService {
  static const String _alertsKey = 'travel_alerts';

  Future<List<TravelAlert>> getAllAlerts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(alertsJson);
      final allAlerts = decoded.map((json) => TravelAlert.fromJson(json)).toList();
      return allAlerts.where((a) => a.userId == userId).toList();
    } catch (e) {
      debugPrint('Error loading alerts: $e');
      return [];
    }
  }

  Future<List<TravelAlert>> getActiveAlerts(String userId) async {
    final alerts = await getAllAlerts(userId);
    return alerts.where((a) => a.isActive).toList();
  }

  Future<void> addAlert(TravelAlert alert) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      List<TravelAlert> alerts = [];
      if (alertsJson != null) {
        final List<dynamic> decoded = jsonDecode(alertsJson);
        alerts = decoded.map((json) => TravelAlert.fromJson(json)).toList();
      }
      
      alerts.add(alert);
      
      final jsonString = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_alertsKey, jsonString);
    } catch (e) {
      debugPrint('Error adding alert: $e');
    }
  }

  Future<void> updateAlert(TravelAlert alert) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson == null) return;

      final List<dynamic> decoded = jsonDecode(alertsJson);
      final alerts = decoded.map((json) => TravelAlert.fromJson(json)).toList();
      
      final index = alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        alerts[index] = alert;
      }
      
      final jsonString = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_alertsKey, jsonString);
    } catch (e) {
      debugPrint('Error updating alert: $e');
    }
  }

  Future<void> removeAlert(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson == null) return;

      final List<dynamic> decoded = jsonDecode(alertsJson);
      final alerts = decoded.map((json) => TravelAlert.fromJson(json)).toList();
      
      alerts.removeWhere((a) => a.id == id);
      
      final jsonString = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_alertsKey, jsonString);
    } catch (e) {
      debugPrint('Error removing alert: $e');
    }
  }

  Future<void> clearAllAlerts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson == null) return;

      final List<dynamic> decoded = jsonDecode(alertsJson);
      final alerts = decoded.map((json) => TravelAlert.fromJson(json)).toList();
      
      alerts.removeWhere((a) => a.userId == userId);
      
      final jsonString = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_alertsKey, jsonString);
    } catch (e) {
      debugPrint('Error clearing alerts: $e');
    }
  }
}
