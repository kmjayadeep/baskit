import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_auth_service.dart';

/// State class for user profile and authentication
class ProfileState {
  final bool isGoogleUser;
  final bool isAnonymous;
  final String displayName;
  final String? email;
  final String? photoURL;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProfileState({
    required this.isGoogleUser,
    required this.isAnonymous,
    required this.displayName,
    this.email,
    this.photoURL,
    required this.isLoading,
    this.error,
    this.successMessage,
  });

  // Initial state
  const ProfileState.initial()
    : this(
        isGoogleUser: false,
        isAnonymous: true,
        displayName: 'Guest User',
        isLoading: true,
      );

  // Create state from current auth service
  factory ProfileState.fromAuthService({
    bool isLoading = false,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      isGoogleUser: FirebaseAuthService.isGoogleUser,
      isAnonymous: FirebaseAuthService.isAnonymous,
      displayName: FirebaseAuthService.userDisplayName,
      email: FirebaseAuthService.userEmail,
      photoURL: FirebaseAuthService.userPhotoURL,
      isLoading: isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  // Copy with method for state updates
  ProfileState copyWith({
    bool? isGoogleUser,
    bool? isAnonymous,
    String? displayName,
    String? email,
    String? photoURL,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return ProfileState(
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// ViewModel for managing user profile and authentication
class ProfileViewModel extends StateNotifier<ProfileState> {
  StreamSubscription<dynamic>? _authSubscription;

  ProfileViewModel() : super(const ProfileState.initial()) {
    _initializeAuthStream();
  }

  // Initialize authentication state stream
  void _initializeAuthStream() {
    // Update initial state from current auth service
    state = ProfileState.fromAuthService();

    // Listen to auth state changes
    _authSubscription = FirebaseAuthService.authStateChanges.listen((user) {
      if (mounted) {
        state = ProfileState.fromAuthService(
          error: state.error,
          successMessage: state.successMessage,
        );
      }
    });
  }

  // Handle successful sign-in
  void onSignInSuccess() {
    if (mounted) {
      state = ProfileState.fromAuthService(
        successMessage: 'Successfully signed in with Google! 🎉',
      );
    }
  }

  // Handle sign-out
  void onSignOut() {
    if (mounted) {
      state = ProfileState.fromAuthService(
        successMessage: 'Signed out successfully',
      );
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
  }

  // Clear both error and success messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccessMessage: true);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Provider for ProfileViewModel
final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
      return ProfileViewModel();
    });
