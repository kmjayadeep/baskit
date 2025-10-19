import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  static User? get currentUser {
    if (!isFirebaseAvailable) {
      debugPrint('🚫 Firebase not available - returning null for currentUser');
      return null;
    }
    final user = _auth.currentUser;
    return user;
  }

  // Get current user stream
  static Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  // Check if user is anonymous
  static bool get isAnonymous {
    if (!isFirebaseAvailable) {
      debugPrint('🚫 Firebase not available - returning true for isAnonymous');
      return true;
    }
    final user = currentUser;
    final result = user?.isAnonymous ?? true;
    return result;
  }

  // Check if user is signed in with Google
  static bool get isGoogleUser {
    if (!isFirebaseAvailable || currentUser == null) {
      return false;
    }
    return currentUser!.providerData.any(
      (info) => info.providerId == 'google.com',
    );
  }

  // Get user display info
  static String get userDisplayName {
    if (!isFirebaseAvailable || currentUser == null) {
      return 'Guest';
    }
    return currentUser!.displayName ?? currentUser!.email ?? 'Anonymous User';
  }

  static String? get userEmail {
    if (!isFirebaseAvailable || currentUser == null) {
      return null;
    }
    return currentUser!.email;
  }

  static String? get userPhotoURL {
    if (!isFirebaseAvailable || currentUser == null) {
      return null;
    }
    return currentUser!.photoURL;
  }

  // Initialize anonymous authentication
  static Future<UserCredential?> signInAnonymously() async {
    if (!isFirebaseAvailable) {
      return null;
    }

    try {
      final result = await _auth.signInAnonymously();
      debugPrint('✅ Signed in anonymously: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseAvailable) {
      return null;
    }

    try {
      // Create Google Auth Provider for both platforms
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential;

      if (kIsWeb) {
        // WEB: Use Firebase Auth's signInWithPopup for web platform
        debugPrint('🌐 Using web sign-in flow (signInWithPopup)');

        // If user is anonymous, link the Google account to preserve data
        if (isAnonymous && currentUser != null) {
          debugPrint('Linking anonymous account with Google account...');
          userCredential = await currentUser!.linkWithPopup(googleProvider);
          debugPrint(
            '✅ Successfully linked accounts: ${userCredential.user?.email}',
          );
        } else {
          userCredential = await _auth.signInWithPopup(googleProvider);
          debugPrint('✅ Signed in with Google: ${userCredential.user?.email}');
        }
      } else {
        // MOBILE/DESKTOP: Use Firebase Auth's signInWithProvider
        // This provides native Google Sign-In UI on mobile platforms
        debugPrint('📱 Using mobile/desktop sign-in flow');

        // If user is anonymous, link the Google account to preserve data
        if (isAnonymous && currentUser != null) {
          debugPrint('Linking anonymous account with Google account...');
          userCredential = await currentUser!.linkWithProvider(googleProvider);
          debugPrint(
            '✅ Successfully linked accounts: ${userCredential.user?.email}',
          );
        } else {
          userCredential = await _auth.signInWithProvider(googleProvider);
          debugPrint('✅ Signed in with Google: ${userCredential.user?.email}');
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out (returns to anonymous auth)
  static Future<void> signOut() async {
    if (!isFirebaseAvailable) {
      return;
    }

    try {
      debugPrint('Signing out current user...');

      // Clear local data before signing out
      await StorageService.instance.clearUserData();

      await _googleSignIn.signOut();
      await _auth.signOut();

      // Sign back in anonymously to maintain functionality
      await signInAnonymously();
      debugPrint('✅ Signed out and returned to anonymous mode');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Delete account (returns to anonymous auth)
  static Future<bool> deleteAccount() async {
    if (!isFirebaseAvailable) {
      return false;
    }

    try {
      debugPrint('Deleting user account...');

      // Clear local data before deleting account
      await StorageService.instance.clearUserData();

      await currentUser?.delete();

      // Sign back in anonymously to maintain functionality
      await signInAnonymously();
      debugPrint('✅ Account deleted and returned to anonymous mode');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  // Update display name
  static Future<bool> updateDisplayName(String displayName) async {
    if (!isFirebaseAvailable) {
      return false;
    }

    try {
      await currentUser?.updateDisplayName(displayName);
      debugPrint('✅ Display name updated: $displayName');
      return true;
    } catch (e) {
      debugPrint('Error updating display name: $e');
      return false;
    }
  }

  // Check account status for UI
  static String get accountStatusText {
    if (!isFirebaseAvailable) {
      return 'Local mode';
    }
    if (isAnonymous) {
      return 'Guest mode';
    }
    if (isGoogleUser) {
      return 'Google account';
    }
    return 'Signed in';
  }

  // Get account upgrade suggestion
  static String get upgradePrompt {
    if (!isFirebaseAvailable) {
      return 'Enable cloud sync by adding Firebase config';
    }
    if (isAnonymous) {
      return 'Sign in with Google to sync across devices';
    }
    return 'Account synced across devices';
  }
}
