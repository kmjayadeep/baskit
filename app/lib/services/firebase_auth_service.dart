import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../repositories/storage_shopping_repository.dart';

enum AccountDeletionFailure {
  firebaseUnavailable,
  noCurrentUser,
  requiresRecentLogin,
  operationFailed,
  localResetFailed,
}

extension AccountDeletionFailureMessage on AccountDeletionFailure {
  String get userMessage {
    switch (this) {
      case AccountDeletionFailure.firebaseUnavailable:
        return 'Account deletion is unavailable while Baskit is running in local mode.';
      case AccountDeletionFailure.noCurrentUser:
        return 'No signed-in account is available to delete.';
      case AccountDeletionFailure.requiresRecentLogin:
        return 'Please sign in again before deleting your account.';
      case AccountDeletionFailure.operationFailed:
        return 'Could not delete your account. Please try again.';
      case AccountDeletionFailure.localResetFailed:
        return 'Your account was deleted, but Baskit could not reset local app data. Please sign out or reinstall before using this device.';
    }
  }
}

class GoogleSignInFailure implements Exception {
  final String message;

  const GoogleSignInFailure(this.message);

  @override
  String toString() => message;
}

class AccountDeletionResult {
  final bool success;
  final AccountDeletionFailure? failure;
  final String? message;

  const AccountDeletionResult._({
    required this.success,
    this.failure,
    this.message,
  });

  const AccountDeletionResult.success() : this._(success: true);

  factory AccountDeletionResult.failure(AccountDeletionFailure failure) {
    return AccountDeletionResult._(
      success: false,
      failure: failure,
      message: failure.userMessage,
    );
  }

  bool get requiresReauthentication =>
      failure == AccountDeletionFailure.requiresRecentLogin;
}

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  static bool get _shouldUseNativeGoogleSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (kIsWeb) {
      return;
    }

    final initialization = _googleSignInInitialization ??= _googleSignIn
        .initialize();
    try {
      await initialization;
    } catch (_) {
      _googleSignInInitialization = null;
      rethrow;
    }
  }

  // Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } on FirebaseException {
      return false;
    } catch (_) {
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
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error signing in anonymously [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with Google.
  //
  // By default, anonymous guest accounts are linked so local lists are kept.
  // Set [linkAnonymousAccount] to false for explicit existing-account sign-in
  // flows where the user wants to switch to their cloud account instead.
  static Future<UserCredential?> signInWithGoogle({
    bool linkAnonymousAccount = true,
  }) async {
    if (!isFirebaseAvailable) {
      return null;
    }

    try {
      if (kIsWeb) {
        return _signInWithGoogleWeb(linkAnonymousAccount: linkAnonymousAccount);
      }

      if (_shouldUseNativeGoogleSignIn) {
        return _signInWithNativeGoogleAccountPicker(
          linkAnonymousAccount: linkAnonymousAccount,
        );
      }

      return _signInWithFirebaseProvider(
        linkAnonymousAccount: linkAnonymousAccount,
      );
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In error [${e.code}]: ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw GoogleSignInFailure(_googleSignInExceptionMessage(e));
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error signing in with Google [${e.code}]: ${e.message}');
      final message = _firebaseGoogleSignInMessage(e);
      if (message == null) {
        return null;
      }
      throw GoogleSignInFailure(message);
    } on GoogleSignInFailure {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error signing in with Google: $e');
      throw const GoogleSignInFailure(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  static Future<UserCredential> _signInWithGoogleWeb({
    required bool linkAnonymousAccount,
  }) async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    debugPrint('🌐 Using web sign-in flow (signInWithPopup)');

    if (linkAnonymousAccount && isAnonymous && currentUser != null) {
      debugPrint('Linking anonymous account with Google account...');
      final userCredential = await currentUser!.linkWithPopup(googleProvider);
      debugPrint(
        '✅ Successfully linked accounts: ${userCredential.user?.email}',
      );
      return userCredential;
    }

    final userCredential = await _auth.signInWithPopup(googleProvider);
    debugPrint('✅ Signed in with Google: ${userCredential.user?.email}');
    return userCredential;
  }

  static Future<UserCredential> _signInWithFirebaseProvider({
    required bool linkAnonymousAccount,
  }) async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    debugPrint('🖥️ Using Firebase provider sign-in flow');

    if (linkAnonymousAccount && isAnonymous && currentUser != null) {
      debugPrint('Linking anonymous account with Google account...');
      final userCredential = await currentUser!.linkWithProvider(
        googleProvider,
      );
      debugPrint(
        '✅ Successfully linked accounts: ${userCredential.user?.email}',
      );
      return userCredential;
    }

    final userCredential = await _auth.signInWithProvider(googleProvider);
    debugPrint('✅ Signed in with Google: ${userCredential.user?.email}');
    return userCredential;
  }

  static Future<UserCredential> _signInWithNativeGoogleAccountPicker({
    required bool linkAnonymousAccount,
  }) async {
    debugPrint('📱 Using native Google account picker sign-in flow');
    await _ensureGoogleSignInInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInFailure(
        'Native Google sign-in is unavailable on this device.',
      );
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInFailure(
        'Google did not return a valid sign-in token. Please try again.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    try {
      if (linkAnonymousAccount && isAnonymous && currentUser != null) {
        debugPrint('Linking anonymous account with native Google account...');
        final userCredential = await currentUser!.linkWithCredential(
          credential,
        );
        debugPrint(
          '✅ Successfully linked accounts: ${userCredential.user?.email}',
        );
        return userCredential;
      }

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint(
        '✅ Signed in with native Google account: ${userCredential.user?.email}',
      );
      return userCredential;
    } on FirebaseAuthException {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint(
          'Failed to clear native Google session after auth error: $e',
        );
      }
      rethrow;
    }
  }

  static String _googleSignInExceptionMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google sign-in is not configured correctly for this app build.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in is unavailable on this device. Please try again later.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  @visibleForTesting
  static bool isGoogleSignInCancellation(FirebaseAuthException e) {
    switch (e.code) {
      case 'canceled':
      case 'cancelled':
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
        return true;
      default:
        return false;
    }
  }

  static String? _firebaseGoogleSignInMessage(FirebaseAuthException e) {
    if (isGoogleSignInCancellation(e)) {
      return null;
    }

    switch (e.code) {
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'This Google account is already linked to another Baskit account.';
      case 'provider-already-linked':
        return 'This Baskit account is already linked with Google.';
      case 'network-request-failed':
        return 'Network unavailable. Please check your connection and try again.';
      default:
        return 'Google sign-in failed. Please try again.';
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
      await StorageShoppingRepository.instance().clearUserData();

      if (_shouldUseNativeGoogleSignIn) {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      }
      await _auth.signOut();

      // Sign back in anonymously to maintain functionality
      await signInAnonymously();
      debugPrint('✅ Signed out and returned to anonymous mode');
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error signing out [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error signing out: $e');
    }
  }

  // Delete account (returns to anonymous auth)
  static Future<bool> deleteAccount() async {
    final result = await deleteAccountResult();
    return result.success;
  }

  static Future<AccountDeletionResult> deleteAccountResult() async {
    if (!isFirebaseAvailable) {
      return AccountDeletionResult.failure(
        AccountDeletionFailure.firebaseUnavailable,
      );
    }

    final user = currentUser;
    if (user == null) {
      return AccountDeletionResult.failure(
        AccountDeletionFailure.noCurrentUser,
      );
    }
    final userId = user.uid;

    var remoteDeletionSucceeded = false;

    try {
      debugPrint('Deleting user account...');

      await user.delete();
      remoteDeletionSucceeded = true;

      // Clear local user data only after Firebase account deletion succeeds.
      await StorageShoppingRepository.instance().clearUserData(
        migratedUserId: userId,
      );

      // Sign back in anonymously to maintain guest-first functionality.
      await signInAnonymously();
      debugPrint('✅ Account deleted and returned to anonymous mode');
      return const AccountDeletionResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error deleting account [${e.code}]: ${e.message}');
      if (remoteDeletionSucceeded) {
        return AccountDeletionResult.failure(
          AccountDeletionFailure.localResetFailed,
        );
      }
      if (e.code == 'requires-recent-login') {
        return AccountDeletionResult.failure(
          AccountDeletionFailure.requiresRecentLogin,
        );
      }
      return AccountDeletionResult.failure(
        AccountDeletionFailure.operationFailed,
      );
    } catch (e) {
      debugPrint('Unexpected error deleting account: $e');
      if (remoteDeletionSucceeded) {
        return AccountDeletionResult.failure(
          AccountDeletionFailure.localResetFailed,
        );
      }
      return AccountDeletionResult.failure(
        AccountDeletionFailure.operationFailed,
      );
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
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error updating display name [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error updating display name: $e');
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
