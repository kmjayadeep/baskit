# Firebase Setup & Configuration

## Overview
Firebase is optional. If Firebase is not configured, the app runs in local-only mode using Hive. When Firebase is configured, the app signs in anonymously on startup, creates a user profile, and enables Google Sign-In upgrades for sync/sharing.

## Current Repo Configuration
The repository already includes Firebase config for Android and web:
- `app/lib/firebase_options.dart` (FlutterFire CLI output)
- `app/android/app/google-services.json`
- `app/web/index.html` includes a Google Sign-In client ID meta tag

iOS/macOS config files are not committed and must be added per project.

## 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a project (or reuse an existing one)
3. Enable Google Analytics if desired

## 2. Enable Firebase Services
### Authentication
Enable these providers:
- **Anonymous** (required for guest flow)
- **Google** (required for account upgrade)

### Firestore
- Create the database in production mode
- Deploy rules from `app/firestore.rules`

## 3. Generate Configuration Files (Recommended)
Run FlutterFire from `app/` to generate platform config files:
```bash
cd app
flutterfire configure
```

This updates:
- `app/lib/firebase_options.dart`
- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`
- `app/macos/Runner/GoogleService-Info.plist`

## 4. Platform File Placement
### Android
Place `google-services.json` in:
`app/android/app/google-services.json`

### iOS / macOS
Place `GoogleService-Info.plist` in:
- `app/ios/Runner/GoogleService-Info.plist`
- `app/macos/Runner/GoogleService-Info.plist`

### Web
Update `app/web/index.html` with your Google Sign-In client ID:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID">
```

## 5. Android Build Configuration
The repo already includes the Google Services plugin and Firebase auth dependencies.
Key settings live in:
- `app/android/build.gradle.kts`
- `app/android/app/build.gradle.kts`

## 6. Deploy Firestore Rules
```bash
npm install -g firebase-tools
firebase login
firebase init firestore
firebase deploy --only firestore:rules
```

## 7. Verify the Setup
```bash
cd app
flutter run
```

Expected behavior:
- Firebase initializes and anonymous auth runs
- User profile created in `/users/{uid}`
- Lists stay in Hive until Google Sign-In upgrade

## Troubleshooting
- **Anonymous auth fails**: Ensure Anonymous provider is enabled
- **Google Sign-In fails**: Confirm SHA fingerprints and OAuth consent setup
- **App runs local-only**: Check `firebase_options.dart` and platform files
