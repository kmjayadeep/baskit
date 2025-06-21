import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    if (!isFirebaseAvailable) return null;
    return _auth.currentUser;
  }

  // Get current user stream
  static Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) return Stream.value(null);
    return _auth.authStateChanges();
  }

  // Check if user is anonymous
  static bool get isAnonymous {
    if (!isFirebaseAvailable) return true;
    return currentUser?.isAnonymous ?? true;
  }

  // Check if user is signed in with Google
  static bool get isGoogleUser {
    if (!isFirebaseAvailable || currentUser == null) return false;
    return currentUser!.providerData.any(
      (info) => info.providerId == 'google.com',
    );
  }

  // Get user display info
  static String get userDisplayName {
    if (!isFirebaseAvailable || currentUser == null) return 'Guest';
    return currentUser!.displayName ?? currentUser!.email ?? 'Anonymous User';
  }

  static String? get userEmail {
    if (!isFirebaseAvailable || currentUser == null) return null;
    return currentUser!.email;
  }

  static String? get userPhotoURL {
    if (!isFirebaseAvailable || currentUser == null) return null;
    return currentUser!.photoURL;
  }

  // Initialize anonymous authentication
  static Future<UserCredential?> signInAnonymously() async {
    if (!isFirebaseAvailable) return null;

    try {
      final result = await _auth.signInAnonymously();
      print('✅ Signed in anonymously: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseAvailable) return null;

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign-in cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('Google sign-in successful: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // If user is anonymous, link the Google account to preserve data
      if (isAnonymous && currentUser != null) {
        print('Linking anonymous account with Google account...');
        final result = await currentUser!.linkWithCredential(credential);
        print('✅ Successfully linked accounts: ${result.user?.email}');
        return result;
      } else {
        // Sign in with the credential
        final result = await _auth.signInWithCredential(credential);
        print('✅ Signed in with Google: ${result.user?.email}');
        return result;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out (returns to anonymous auth)
  static Future<void> signOut() async {
    if (!isFirebaseAvailable) return;

    try {
      print('Signing out current user...');
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Sign back in anonymously to maintain functionality
      await signInAnonymously();
      print('✅ Signed out and returned to anonymous mode');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Delete account (returns to anonymous auth)
  static Future<bool> deleteAccount() async {
    if (!isFirebaseAvailable) return false;

    try {
      print('Deleting user account...');
      await currentUser?.delete();

      // Sign back in anonymously to maintain functionality
      await signInAnonymously();
      print('✅ Account deleted and returned to anonymous mode');
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Update display name
  static Future<bool> updateDisplayName(String displayName) async {
    if (!isFirebaseAvailable) return false;

    try {
      await currentUser?.updateDisplayName(displayName);
      print('✅ Display name updated: $displayName');
      return true;
    } catch (e) {
      print('Error updating display name: $e');
      return false;
    }
  }

  // Check account status for UI
  static String get accountStatusText {
    if (!isFirebaseAvailable) return 'Local mode';
    if (isAnonymous) return 'Guest mode';
    if (isGoogleUser) return 'Google account';
    return 'Signed in';
  }

  // Get account upgrade suggestion
  static String get upgradePrompt {
    if (!isFirebaseAvailable)
      return 'Enable cloud sync by adding Firebase config';
    if (isAnonymous) return 'Sign in with Google to sync across devices';
    return 'Account synced across devices';
  }
}
