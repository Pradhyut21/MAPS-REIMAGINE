import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfinder/models/user.dart' as model;

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kCurrentUser = 'current_user_json';

  model.User? _cachedUser;
  bool _ready = false;

  /// Load the cached user from local storage. Call once at app start.
  Future<void> bootstrap() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kCurrentUser);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedUser = model.User.fromJson(map);
      }
    } catch (e) {
      debugPrint('AuthService.bootstrap error: $e');
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  bool get ready => _ready;
  model.User? get currentUser => _cachedUser;
  bool get isLoggedInSync => _cachedUser != null;
  bool get isGuestSync => _cachedUser != null &&
      (_cachedUser!.email == null || _cachedUser!.email!.isEmpty) &&
      _cachedUser!.name.trim().toLowerCase() == 'guest';

  Future<model.User?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kCurrentUser);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cachedUser = model.User.fromJson(map);
      return _cachedUser;
    } catch (e) {
      debugPrint('AuthService.getCurrentUser error: $e');
      return null;
    } finally {
      if (!_ready) {
        _ready = true;
        notifyListeners();
      }
    }
  }

  Future<model.User?> signInOrCreate({required String name, String? email}) async {
    try {
      final now = DateTime.now();
      final u = model.User(
        id: 'local_${now.millisecondsSinceEpoch}',
        name: name.trim(),
        email: (email?.trim().isEmpty ?? true) ? null : email!.trim(),
        currentLatitude: null,
        currentLongitude: null,
        createdAt: now,
        updatedAt: now,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCurrentUser, jsonEncode(u.toJson()));
      _cachedUser = u;
      notifyListeners();
      return u;
    } catch (e) {
      debugPrint('AuthService.signInOrCreate error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCurrentUser);
      _cachedUser = null;
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async => (await getCurrentUser()) != null;
}
