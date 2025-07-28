# Authentication System

## Overview
Baskit implements a guest-first authentication system using Firebase Auth with anonymous login by default and optional account upgrades.

## Authentication Flow

### User Experience
1. **Anonymous Start**: Users automatically get Firebase anonymous auth
2. **Immediate Usage**: Full app functionality without registration
3. **Optional Upgrade**: Convert to Google/Email account for sync
4. **Data Migration**: Seamless transfer of anonymous data

### Current Implementation ✅
- Anonymous authentication enabled
- Google Sign-In configured
- Firebase Auth service created
- Account linking implemented
- Android build configuration updated

## Google Authentication Setup

### Firebase Console Configuration

1. **Enable Google Provider:**
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable **Google** provider
   - Set project support email

2. **OAuth Consent Screen:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to APIs & Services → OAuth consent screen
   - Choose **External** user type
   - Fill required fields:
     - App name: Baskit
     - User support email: Your email
     - Developer contact: Your email

### Android Configuration ✅

The Android setup has been completed with proper build configuration:

**SHA Certificate Fingerprints Required:**
```bash
# Get debug fingerprints
cd app/android
./gradlew signingReport

# Or use keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Add fingerprints to Firebase:**
1. Firebase Console → Project Settings → Android app
2. Add SHA1 and SHA256 fingerprints from debug keystore
3. Download updated `google-services.json`

### Build Configuration ✅

**Project-level dependencies:**
```gradle
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**App-level configuration:**
```gradle
android {
    compileSdk = 34
    ndkVersion = "27.0.12077973"
    
    defaultConfig {
        minSdk = 23  // Required for Firebase Auth
        targetSdk = 34
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

## Service Implementation

### Firebase Auth Service
Location: `app/lib/services/firebase_auth_service.dart`

**Key Features:**
- Anonymous authentication by default
- Google Sign-In integration
- Account linking and migration
- User profile management

**Main Methods:**
```dart
// Anonymous sign-in (automatic)
static Future<UserCredential?> signInAnonymously()

// Google sign-in with account linking
static Future<UserCredential?> signInWithGoogle()

// Sign out with data cleanup
static Future<void> signOut()

// Current user state
static User? get currentUser
static bool get isAnonymous
static String get userDisplayName
```

### Authentication States

**Anonymous User:**
- Automatically signed in on first app launch
- Full functionality with local storage
- Data synced to Firebase with anonymous UID
- Can upgrade to permanent account anytime

**Authenticated User:**
- Google account linked to anonymous account
- Data migrated from anonymous to permanent UID
- Cross-device synchronization enabled
- Enhanced sharing capabilities

## UI Integration

### Google Sign-In Widget
Location: `app/lib/widgets/auth/google_sign_in_widget.dart`

**Usage Example:**
```dart
GoogleSignInWidget(
  onSignInSuccess: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed in with Google!')),
    );
  },
  onSignOut: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed out')),
    );
  },
)
```

### Profile Management
- Guest mode by default
- Optional profile display
- Account upgrade prompts
- Sign-out functionality

## Data Migration Strategy

### Account Linking Process
1. **Anonymous Phase**: Data stored with anonymous UID
2. **Link Account**: Google account linked to anonymous account
3. **Data Transfer**: Anonymous data migrated to permanent UID
4. **Cleanup**: Anonymous account data cleaned up

### Migration Benefits
- **Seamless Transition**: No data loss during upgrade
- **Preserved Experience**: All lists and items transferred
- **Enhanced Features**: Unlocks cross-device sync and sharing

## Testing Authentication

### Test Flow
```bash
cd app
flutter clean
flutter pub get
flutter run
```

### Expected Behavior
- ✅ App starts with anonymous authentication
- ✅ Google Sign-In button appears in profile
- ✅ Sign-in flow works on Android devices
- ✅ Account linking preserves all data
- ✅ Cross-device sync works after authentication

### Debug Authentication
```dart
// Check current auth state
FirebaseAuth.instance.authStateChanges().listen((user) {
  print('Auth state: ${user?.uid} (anonymous: ${user?.isAnonymous})');
});

// Test Google Sign-In
await GoogleSignIn().signIn();
```

## Security Considerations

### Anonymous User Security
- Anonymous UIDs are unique and secure
- Data isolated per anonymous session
- No personal information stored

### Authenticated User Security
- Google OAuth provides verified identity
- Account recovery through Google account
- Secure cross-device access
- Enhanced sharing with verified accounts

### Best Practices
- Always handle authentication state changes
- Graceful fallback to anonymous mode
- Secure token management
- Proper sign-out cleanup

## Troubleshooting

### Common Issues
1. **SHA fingerprint mismatch**: Ensure debug/release fingerprints added to Firebase
2. **Google Sign-In fails**: Check OAuth consent screen configuration
3. **Build errors**: Verify gradle plugin versions and dependencies
4. **Account linking fails**: Check Firebase Auth rules and anonymous user state

### Debug Commands
```bash
# Check SHA fingerprints
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey

# View Firebase debug logs
flutter run --debug
adb logcat | grep Firebase
``` 