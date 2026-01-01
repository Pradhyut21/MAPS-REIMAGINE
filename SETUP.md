# Wayfinder Setup Guide

## Google Maps API Key Setup

This app requires a Google Maps API key to function properly. Follow these steps:

### 1. Get a Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Create credentials (API Key)
5. Copy your API key

### 2. Add the API Key to Your App

#### For Android:
Open `android/app/src/main/AndroidManifest.xml` and replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

#### For iOS:
Open `ios/Runner/AppDelegate.swift` and replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### 3. Run the App

```bash
flutter pub get
flutter run
```

## Features

- **Home**: Beautiful scenic interface with quick action buttons
- **Map**: Interactive Google Maps with search and location tracking
- **Eat & Drink**: Find nearby restaurants with directions and bus guidance
- **Go**: Discover tourist attractions near your location
- **Transport**: Bus route planner with Google Maps integration
- **AI Assistant**: Voice-enabled travel alerts with geofencing
- **Emergency**: Quick access to emergency services, hospitals, and police stations

## Permissions

The app requires the following permissions:
- Location (for maps and nearby places)
- Microphone (for voice commands)
- Phone (for emergency calls)

All permissions are requested at runtime when needed.

## Sample Data

The app includes sample data for restaurants, attractions, hospitals, and police stations in Bangalore, India. This data is stored locally using shared_preferences.
