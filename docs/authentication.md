# Authentication System

## Overview
Baskit is guest-first. When Firebase is configured, the app signs in anonymously on startup and keeps list data in Hive until the user upgrades with Google Sign-In. If Firebase is not configured, the app runs in local-only mode with no auth APIs.

## Runtime Modes
1. **Local-only (no Firebase config)**
   - No Firebase initialization
   - No auth state stream
   - Lists and items stored in Hive only

2. **Firebase-enabled guest mode (anonymous auth)**
   - App signs in with Firebase anonymous auth on launch
   - User profile document created in `/users/{uid}`
   - Lists remain local in Hive until upgrade

3. **Google authenticated mode**
   - Anonymous account is linked to Google
   - `StorageService` migrates local lists to Firestore
   - All list operations route to Firestore with offline persistence

## Authentication Flow
1. App launches → Firebase initialized (if configured)
2. Anonymous sign-in → `FirebaseAuthService.signInAnonymously()`
3. User profile created → `FirestoreService.initializeUserProfile()`
4. Guest uses the app → local Hive storage
5. User chooses Google Sign-In → account linked to Google
6. Local data migrates → Firestore becomes the source of truth

## Google Authentication Setup
Enable providers in Firebase Console:
1. **Anonymous** authentication (required for guest flow)
2. **Google** authentication (required for upgrade)

See `docs/firebase-setup.md` for platform configuration details.

## Service Implementation
**Primary files:**
- `app/lib/services/firebase_auth_service.dart`
- `app/lib/view_models/auth_view_model.dart`

**Key methods:**
```dart
// Anonymous sign-in on startup
static Future<UserCredential?> signInAnonymously()

// Google Sign-In (links anonymous account if present)
static Future<UserCredential?> signInWithGoogle()

// Sign out and return to anonymous mode
static Future<void> signOut()

// Delete account and return to anonymous mode
static Future<bool> deleteAccount()
```

**Important behavior:**
- `isAnonymous` is `true` when the Firebase user is anonymous or when Firebase is not configured.
- `signInWithGoogle()` links the anonymous account to preserve Firebase identity.
- `signOut()` clears local data, signs out, then re-enters anonymous mode.

## State Management
The auth state is centralized in `AuthViewModel`:
```dart
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authViewModelProvider).user;
});
```

## Data Migration Strategy
Migration is triggered when a user becomes non-anonymous:
1. `StorageService` checks `migration_complete_<uid>` in `SharedPreferences`
2. Local lists are copied to Firestore
3. Local Hive data is cleared
4. Migration flag is persisted

## UI Integration
The profile UI reads auth state via Riverpod and uses `GoogleSignInWidget`:
- Guest users see a “Sign in with Google” button
- Signed-in users see profile details and a sign-out button

## Testing Authentication
```bash
cd app
flutter run
```

Expected behavior:
- Without Firebase config → local-only mode
- With Firebase config → anonymous auth + local storage
- Google Sign-In → list migration to Firestore

## Troubleshooting
Common issues:
1. **Anonymous sign-in fails** → Ensure Anonymous auth is enabled
2. **Google Sign-In fails** → Check OAuth consent screen and SHA fingerprints
3. **Migration not triggered** → Verify `StorageService` logs and auth state

## Security Considerations
- Guest lists stay on device until upgraded
- Authenticated users rely on Firestore security rules
- Sign-out clears local data before returning to anonymous mode
