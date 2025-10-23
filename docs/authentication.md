# Authentication System

## Overview
Baskit implements a **true guest-first** authentication system. Guests use the app without any authentication (no Firebase connection), and users can optionally sign in with Google when they need cloud features.

## Authentication Flow

### User Experience
1. **Guest Start**: Users start with NO authentication - purely local storage
2. **Immediate Usage**: Full app functionality without any registration or network connection
3. **Optional Sign-In**: Sign in with Google when sharing or sync is needed
4. **Data Migration**: Seamless transfer of local data to Firebase on sign-in

### Current Implementation ✅
- Guest mode requires NO authentication (purely local)
- Google Sign-In configured for cloud features
- Firebase Auth service created
- Data migration implemented for guest → authenticated conversion
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
- No authentication required for guest mode
- Google Sign-In integration (platform-specific flows)
- Data migration from local to Firebase on sign-in
- User profile management
- Firebase availability checking

**Main Methods:**
```dart
// Check if Firebase is configured and available
static bool get isFirebaseAvailable

// Google sign-in (establishes Firebase authentication)
// Uses signInWithPopup for web, signInWithProvider for mobile/desktop
static Future<UserCredential?> signInWithGoogle()

// Sign out with data cleanup (returns to guest mode)
static Future<void> signOut()

// Delete account and return to guest mode
static Future<bool> deleteAccount()

// Current user state
static User? get currentUser
static bool get isAnonymous  // true for guest mode, false when signed in
static bool get isGoogleUser
static String get userDisplayName
static String? get userEmail
static String? get userPhotoURL
```

**Note**: The `isAnonymous` getter returns `true` when no Firebase user exists (guest mode), not because of Firebase anonymous authentication.

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

**Guest Mode (No Authentication):**
- No Firebase authentication on app launch
- Full functionality with local storage (Hive only)
- All data stays on device
- No network connection to Firebase
- Can sign in with Google anytime

**Authenticated Mode (Google Sign-In):**
- Google account via Firebase Auth
- Local data automatically migrated to Firebase on first sign-in
- Cross-device synchronization enabled
- Real-time collaboration and sharing capabilities

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

### Guest to Authenticated Conversion
1. **Guest Phase**: Data stored locally in Hive (no Firebase)
2. **Sign In**: User authenticates with Google
3. **Data Transfer**: Local Hive data migrated to Firebase
4. **Cleanup**: Local data cleared after successful migration
5. **Storage Switch**: All operations now route to Firebase

### Migration Benefits
- **Seamless Transition**: No data loss during sign-in
- **Preserved Experience**: All lists and items transferred to Firebase
- **Enhanced Features**: Unlocks cross-device sync, sharing, and collaboration

## Testing Authentication

### Test Flow
```bash
cd app
flutter clean
flutter pub get
flutter run
```

### Expected Behavior
- ✅ App starts in guest mode (no authentication)
- ✅ Google Sign-In button appears in profile for guests
- ✅ Sign-in flow works on Android devices
- ✅ Local data migrates to Firebase on sign-in
- ✅ Cross-device sync works after authentication

### Debug Authentication
```dart
// Check current auth state
final isGuest = FirebaseAuthService.isAnonymous;  // true = guest mode (no Firebase auth)
final user = FirebaseAuthService.currentUser;     // null in guest mode

print('Guest mode: $isGuest');
print('User: ${user?.email ?? "No user"}');

// Test Google Sign-In
await FirebaseAuthService.signInWithGoogle();
```

## Security Considerations

### Guest Mode Security
- Data stays local on device (Hive storage)
- No network transmission of guest data
- No personal information collected
- Complete privacy for unauthenticated users

### Authenticated User Security
- Google OAuth provides verified identity
- Account recovery through Google account
- Secure cross-device access with Firebase security rules
- Enhanced sharing with verified accounts

### Best Practices
- Always handle authentication state changes
- Graceful fallback to guest mode on sign-out
- Secure token management for authenticated users
- Proper sign-out cleanup (clears local data, signs out of Firebase)

## Troubleshooting

### Common Issues
1. **SHA fingerprint mismatch**: Ensure debug/release fingerprints added to Firebase
2. **Google Sign-In fails**: Check OAuth consent screen configuration
3. **Build errors**: Verify gradle plugin versions and dependencies
4. **Data migration fails**: Check StorageService migration logic and Firebase connectivity

### Debug Commands
```bash
# Check SHA fingerprints
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey

# View Firebase debug logs
flutter run --debug
adb logcat | grep Firebase
``` 