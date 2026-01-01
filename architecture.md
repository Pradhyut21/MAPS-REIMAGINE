# Wayfinder - Voice-Enabled Maps Application Architecture

## Overview
A voice-enabled maps application with emergency services, restaurant finder, transport info, and real-time navigation.

## Design System
- **Colors**: Dark theme with brown/tan cards (#6B5D54), golden yellow accents (#F5B800), red for emergency (#C53030)
- **Typography**: Clean, modern fonts with generous spacing
- **UI Style**: Non-Material Design, custom sleek interface avoiding Material components

## Features
1. **Home Screen**: Beautiful scenic background, quick action buttons, saved places
2. **Map View**: Interactive map with location markers and search
3. **Explore Map**: Navigate and explore locations
4. **Eat & Drink**: Restaurant finder with directions and bus guidance
5. **Go (Tourist Attractions)**: Famous places near user location
6. **Transport/Bus**: Route planner and bus guidance
7. **AI Assistant**: Voice-enabled travel alerts and geofencing
8. **Emergency**: Quick access to emergency services, nearby hospitals/police, location sharing

## Data Models
- `User`: User profile and location
- `Place`: Generic place model (restaurants, attractions, hospitals, etc.)
- `SearchHistory`: Recent searches
- `SavedPlace`: User's saved/favorite places
- `TravelAlert`: Geofence alerts for proximity notifications
- `BusRoute`: Transport route information

## Service Classes
- `LocationService`: Handle GPS and location tracking
- `PlaceService`: Manage places (restaurants, attractions, emergency services)
- `SearchService`: Handle search history
- `SavedPlaceService`: Manage saved places
- `VoiceService`: Voice recognition and commands
- `AlertService`: Geofence and travel alerts
- `NavigationService`: Route and direction calculations

## Screens/Pages
1. `HomePage`: Main dashboard with scenic background and quick actions
2. `MapPage`: Interactive map view
3. `RestaurantPage`: Restaurant finder
4. `AttractionsPage`: Tourist attractions (Go page)
5. `TransportPage`: Bus/transport route planner
6. `AIAssistantPage`: Voice-enabled AI assistant
7. `EmergencyPage`: Emergency services access

## Storage
- Local storage using shared_preferences for all data
- Sample data for restaurants, attractions, emergency services

## Dependencies
- google_maps_flutter: Map integration
- geolocator: Location services
- geocoding: Address to coordinates conversion
- speech_to_text: Voice recognition
- flutter_tts: Text-to-speech
- shared_preferences: Local storage
- intl: Date/time formatting
- url_launcher: Phone calls and external links
