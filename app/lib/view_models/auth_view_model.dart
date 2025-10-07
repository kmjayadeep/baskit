import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

/// Centralized authentication state for the entire application
///
/// This class holds all authentication-related data and serves as the
/// single source of truth for auth state across all ViewModels and UI components.
class AuthState {
  final bool isGoogleUser;
  final bool isAnonymous;
  final bool isAuthenticated;
  final bool isFirebaseAvailable;
  final String displayName;
  final String? email;
  final String? photoURL;
  final User? user;

  const AuthState({
    required this.isGoogleUser,
    required this.isAnonymous,
    required this.isAuthenticated,
    required this.isFirebaseAvailable,
    required this.displayName,
    this.email,
    this.photoURL,
    this.user,
  });

  /// Initial state when the app starts (before Firebase is initialized)
  const AuthState.initial()
    : this(
        isGoogleUser: false,
        isAnonymous: true,
        isAuthenticated: false,
        isFirebaseAvailable: false,
        displayName: 'Guest User',
      );

  /// Create state from current FirebaseAuthService
  factory AuthState.fromAuthService() {
    return AuthState(
      isGoogleUser: FirebaseAuthService.isGoogleUser,
      isAnonymous: FirebaseAuthService.isAnonymous,
      isAuthenticated: !FirebaseAuthService.isAnonymous,
      isFirebaseAvailable: FirebaseAuthService.isFirebaseAvailable,
      displayName: FirebaseAuthService.userDisplayName,
      email: FirebaseAuthService.userEmail,
      photoURL: FirebaseAuthService.userPhotoURL,
      user: FirebaseAuthService.currentUser,
    );
  }

  /// Copy with method for state updates
  AuthState copyWith({
    bool? isGoogleUser,
    bool? isAnonymous,
    bool? isAuthenticated,
    bool? isFirebaseAvailable,
    String? displayName,
    String? email,
    String? photoURL,
    User? user,
  }) {
    return AuthState(
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isFirebaseAvailable: isFirebaseAvailable ?? this.isFirebaseAvailable,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isGoogleUser == other.isGoogleUser &&
          isAnonymous == other.isAnonymous &&
          isAuthenticated == other.isAuthenticated &&
          isFirebaseAvailable == other.isFirebaseAvailable &&
          displayName == other.displayName &&
          email == other.email &&
          photoURL == other.photoURL &&
          user?.uid == other.user?.uid;

  @override
  int get hashCode =>
      isGoogleUser.hashCode ^
      isAnonymous.hashCode ^
      isAuthenticated.hashCode ^
      isFirebaseAvailable.hashCode ^
      displayName.hashCode ^
      (email?.hashCode ?? 0) ^
      (photoURL?.hashCode ?? 0) ^
      (user?.uid.hashCode ?? 0);

  @override
  String toString() {
    return 'AuthState(isGoogleUser: $isGoogleUser, isAnonymous: $isAnonymous, '
        'isAuthenticated: $isAuthenticated, displayName: $displayName, email: $email)';
  }
}

/// Centralized authentication ViewModel
///
/// This ViewModel manages authentication state for the entire application.
/// It listens to Firebase auth changes and provides a single source of truth
/// for authentication data, eliminating duplication across other ViewModels.
class AuthViewModel extends StateNotifier<AuthState> {
  StreamSubscription<User?>? _authSubscription;

  AuthViewModel() : super(const AuthState.initial()) {
    _initializeAuthStream();
  }

  /// Initialize the authentication stream
  void _initializeAuthStream() {
    // Set initial state from current auth service
    state = AuthState.fromAuthService();

    // Listen to auth state changes and update state reactively
    _authSubscription = FirebaseAuthService.authStateChanges.listen((
      user,
    ) async {
      if (mounted) {
        // Update auth state first
        state = AuthState.fromAuthService();

        // Initialize user profile when authentication changes
        // This ensures that authenticated users have their Firestore profile document
        if (user != null) {
          try {
            await FirestoreService.initializeUserProfile();
          } catch (e) {
            debugPrint(
              '❌ Error initializing user profile after auth change: $e',
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ==========================================
// GLOBAL PROVIDERS
// ==========================================

/// Global provider for the centralized AuthViewModel
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel();
});

/// Convenience providers for common auth checks
final isAnonymousProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAnonymous;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAuthenticated;
});

final isGoogleUserProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isGoogleUser;
});

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authViewModelProvider).user;
});
