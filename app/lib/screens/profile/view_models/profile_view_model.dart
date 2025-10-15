import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for profile UI (loading, messages)
///
/// Authentication data is now handled by the centralized AuthViewModel.
/// This state class only manages UI-specific state for the profile screen.
class ProfileState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProfileState({
    required this.isLoading,
    this.error,
    this.successMessage,
  });

  // Initial state
  const ProfileState.initial() : this(isLoading: false);

  // Copy with method for state updates
  ProfileState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// ViewModel for managing profile UI state
///
/// Authentication state is now handled by the centralized AuthViewModel.
/// This ViewModel only manages UI-specific actions like loading states and messages.
class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState.initial();
  }

  // Handle successful sign-in (only updates UI message)
  void onSignInSuccess() {
    state = state.copyWith(
      successMessage: 'Successfully signed in with Google! 🎉',
    );
  }

  // Handle sign-out (only updates UI message)
  void onSignOut() {
    state = state.copyWith(successMessage: 'Signed out successfully');
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
}

// Provider for ProfileViewModel
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
