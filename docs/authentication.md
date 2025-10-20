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
- Google Sign-In integration (platform-specific flows)
- Account linking with data preservation
- User profile management
- Firebase availability checking

**Main Methods:**
```dart
// Check if Firebase is configured and available
static bool get isFirebaseAvailable

// Anonymous sign-in (automatic on app start)
static Future<UserCredential?> signInAnonymously()

// Google sign-in with automatic account linking for anonymous users
// Uses signInWithPopup for web, signInWithProvider for mobile/desktop
static Future<UserCredential?> signInWithGoogle()

// Sign out with data cleanup (returns to anonymous mode)
static Future<void> signOut()

// Delete account and return to anonymous mode
static Future<bool> deleteAccount()

// Current user state
static User? get currentUser
static bool get isAnonymous
static bool get isGoogleUser
static String get userDisplayName
static String? get userEmail
static String? get userPhotoURL
```

### Centralized Auth State Management

Location: `app/lib/view_models/auth_view_model.dart`

The app uses **Riverpod 3.x** with a centralized `AuthViewModel` that provides auth state to the entire application:

```dart
// Single source of truth for authentication state
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

// Convenience providers for common auth checks
final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authViewModelProvider).user;
});

final isAnonymousProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAnonymous;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAuthenticated;
});
```

**Benefits:**
- Single source of truth for auth state across all ViewModels
- Automatic UI updates when auth state changes
- Eliminates duplication of auth logic
- Integrates with Firebase auth state stream

### Authentication States

**Anonymous User:**
- Automatically signed in on first app launch
- Full functionality with local storage
- Data synced to Firebase with anonymous UID
- Can upgrade to permanent account anytime

**Authenticated User:**
- Google account linked to anonymous account (preserves data)
- Data automatically migrated from local to Firebase
- Cross-device synchronization enabled
- Enhanced sharing capabilities

## UI Integration

### Using Auth State in UI Components

UI components use Riverpod's `ConsumerWidget` or `ConsumerStatefulWidget` to access auth state:

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state
    final authState = ref.watch(authViewModelProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);
    
    return Scaffold(
      body: Column(
        children: [
          Text('User: ${authState.displayName}'),
          if (isAnonymous)
            ElevatedButton(
              onPressed: () => FirebaseAuthService.signInWithGoogle(),
              child: Text('Sign in with Google'),
            )
          else
            ElevatedButton(
              onPressed: () => FirebaseAuthService.signOut(),
              child: Text('Sign out'),
            ),
        ],
      ),
    );
  }
}
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