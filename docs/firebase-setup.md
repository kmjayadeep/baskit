# Firebase Setup & Configuration

## Overview
Baskit uses Firebase as its backend service, providing authentication, real-time database, and offline support. This guide covers the complete setup process.

## Current Implementation Status ✅
- Firebase dependencies added to `pubspec.yaml`
- Firebase Authentication service created
- Firestore service with offline persistence
- Security rules implemented
- Android build configuration updated

## 1. Firebase Project Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Choose "Default Account for Firebase" for Google Analytics

### Enable Services
1. **Authentication:**
   - Go to Authentication > Sign-in method
   - Enable **Anonymous** authentication (required)
   - Enable **Google** sign-in (recommended)
   - Enable **Email/Password** (optional)

2. **Firestore Database:**
   - Go to Firestore Database
   - Create database in "production mode"
   - Deploy security rules from `app/firestore.rules`

## 2. Add Configuration Files

### Android Configuration
1. In Firebase Console → Project Settings
2. Add Android app:
   - Package name: `com.cboxlab.baskit`
   - App nickname: `Baskit`
3. Download `google-services.json`
4. Place in `app/android/app/google-services.json`

### iOS Configuration (Optional)
1. Add iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place in `app/ios/Runner/GoogleService-Info.plist`

### Web Configuration
1. Add Web app in Firebase Console
2. Copy config and add to `app/web/index.html`

## 3. Android Build Configuration

The following configuration has been applied:

**Project-level `android/build.gradle.kts`:**
```kotlin
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**App-level `android/app/build.gradle.kts`:**
```kotlin
android {
    compileSdk = 34
    ndkVersion = "27.0.12077973"
    
    defaultConfig {
        applicationId = "com.cboxlab.baskit"
        minSdk = 23  // Required for Firebase Auth
        targetSdk = 34
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

## 4. Security Rules Deployment

Deploy the security rules to enable proper data access:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (if needed)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

## 5. Testing the Setup

After configuration:

```bash
cd app
flutter clean
flutter pub get
flutter run
```

Expected behavior:
- ✅ App starts with anonymous authentication
- ✅ Firestore initializes with offline persistence
- ✅ User profile created automatically
- ✅ Real-time sync works when online

## 6. Features Enabled

With Firebase properly configured:
- **Anonymous Authentication**: Immediate app usage
- **Real-time Sync**: Lists sync across devices
- **Offline Support**: Full functionality without internet
- **Account Upgrade**: Convert anonymous to full account
- **Collaboration**: Share lists with other users

## 7. Troubleshooting

**Common Issues:**
- **Build errors**: Verify `google-services.json` location
- **Auth errors**: Check Anonymous auth is enabled
- **Permission errors**: Ensure Firestore rules are deployed
- **Network errors**: Verify app has internet permissions

**Debug Commands:**
```bash
# Check Firebase setup
flutter doctor
# View detailed logs
flutter logs
# Test in debug mode
flutter run --debug
```

## 8. Architecture Benefits

The Firebase integration provides:
- **Real-time Database**: Instant updates across devices
- **Offline-First**: Built-in caching and sync
- **Scalability**: Automatic scaling
- **Security**: Built-in authentication and rules
- **Analytics**: Usage tracking and crash reporting
- **Cost-Effective**: Pay-as-you-go pricing 