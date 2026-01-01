Dreamflow Flutter App
=====================

A cross-platform Flutter application developed in Dreamflow. This repository targets Android, iOS, and Web, and uses go_router for navigation.

Features
--------
- Modern themed UI with night city background
- Map with dark search, voice input (female voice), and Nominatim suggestions
- Browse by type chips (Restaurants, Cafes, Hotels, etc.)
- AI assistant page using OpenAI (configured via environment variables)
- Trip Packages flow with guest access support

Local development
-----------------
1. Install Flutter (stable channel).
2. From the project root:
```
flutter pub get
flutter run
```

Pushing to GitHub
-----------------
Dreamflow doesn’t directly connect to GitHub yet. To push this code:
1. In Dreamflow, open the menu and select "Download Code" to get a ZIP.
2. Unzip locally, then in a terminal from the project folder:
```
git init
git add .
git commit -m "Initial commit from Dreamflow"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
git push -u origin main
```

CI
--
This repo includes a GitHub Actions workflow (.github/workflows/flutter_ci.yml) that runs `flutter pub get`, `dart analyze`, and `flutter test` on each push/PR.

Notes
-----
- Navigation: use `context.go()` / `context.push()` / `context.pop()` from go_router.
- Backend: To add Firebase or Supabase, use the respective side panel inside Dreamflow to connect your project before adding code.
- OpenAI config: see `lib/openai/openai_config.dart` (relies on environment variables at runtime).
