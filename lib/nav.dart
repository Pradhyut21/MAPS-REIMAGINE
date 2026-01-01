import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/screens/map_page.dart';
import 'package:wayfinder/screens/restaurants_page.dart';
import 'package:wayfinder/screens/attractions_page.dart';
import 'package:wayfinder/screens/transport_page.dart';
import 'package:wayfinder/screens/ai_assistant_page.dart';
import 'package:wayfinder/screens/emergency_page.dart';
import 'package:wayfinder/screens/voice_settings_page.dart';
import 'package:wayfinder/screens/collections_page.dart';
import 'package:wayfinder/screens/offline_page.dart';
import 'package:wayfinder/screens/trip_packages_page.dart';
import 'package:wayfinder/screens/login_page.dart';
import 'package:wayfinder/services/auth_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: AuthService.instance,
    redirect: (context, state) {
      final auth = AuthService.instance;
      if (!auth.ready) return null;

      final loggingIn = state.matchedLocation == AppRoutes.login;
      final loggedIn = auth.isLoggedInSync;

      // Require sign-in only for Trip Packages (guests are allowed)
      final goingToTrips = state.matchedLocation == AppRoutes.trips;
      if (goingToTrips && !loggedIn) {
        final redirectTo = state.uri.toString();
        return '${AppRoutes.login}?redirect=${Uri.encodeComponent(redirectTo)}';
      }
      if (loggedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _transitionPage(const HomePage()),
      ),
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final lat = double.tryParse(qp['lat'] ?? '');
          final lon = double.tryParse(qp['lon'] ?? '');
          final title = qp['title'];
          final auto = (qp['autoroute'] ?? 'false').toLowerCase() == 'true';
          final fromLat = double.tryParse(qp['fromLat'] ?? '');
          final fromLon = double.tryParse(qp['fromLon'] ?? '');
          return _transitionPage(MapPage(
            initialTargetLat: lat,
            initialTargetLon: lon,
            initialTargetTitle: title,
            autoRoute: auto,
            initialOriginLat: fromLat,
            initialOriginLon: fromLon,
          ));
        },
      ),
      GoRoute(
        path: AppRoutes.restaurants,
        name: 'restaurants',
        pageBuilder: (context, state) => _transitionPage(const RestaurantsPage()),
      ),
      GoRoute(
        path: AppRoutes.attractions,
        name: 'attractions',
        pageBuilder: (context, state) => _transitionPage(const AttractionsPage()),
      ),
      GoRoute(
        path: AppRoutes.transport,
        name: 'transport',
        pageBuilder: (context, state) {
          final destination = state.uri.queryParameters['destination'];
          return _transitionPage(TransportPage(destination: destination));
        },
      ),
      GoRoute(
        path: AppRoutes.ai,
        name: 'ai',
        pageBuilder: (context, state) => _transitionPage(const AIAssistantPage()),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        name: 'emergency',
        pageBuilder: (context, state) => _transitionPage(const EmergencyPage()),
      ),
      GoRoute(
        path: AppRoutes.voiceSettings,
        name: 'voiceSettings',
        pageBuilder: (context, state) => _transitionPage(const VoiceSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.collections,
        name: 'collections',
        pageBuilder: (context, state) => _transitionPage(const CollectionsPage()),
      ),
      GoRoute(
        path: AppRoutes.offline,
        name: 'offline',
        pageBuilder: (context, state) => _transitionPage(const OfflinePage()),
      ),
      GoRoute(
        path: AppRoutes.trips,
        name: 'trips',
        pageBuilder: (context, state) => _transitionPage(const TripPackagesPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return _transitionPage(LoginPage(redirect: redirect));
        },
      ),
    ],
  );
}

CustomTransitionPage _transitionPage(Widget child) => CustomTransitionPage(
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
        final scale = Tween<double>(begin: 0.98, end: 1.0).animate(curved);
        final slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
    );

class AppRoutes {
  static const String home = '/';
  static const String map = '/map';
  static const String restaurants = '/restaurants';
  static const String attractions = '/attractions';
  static const String transport = '/transport';
  static const String ai = '/ai';
  static const String emergency = '/emergency';
  static const String voiceSettings = '/voice-settings';
  static const String collections = '/collections';
  static const String offline = '/offline';
  static const String trips = '/trips';
  static const String login = '/login';
}
