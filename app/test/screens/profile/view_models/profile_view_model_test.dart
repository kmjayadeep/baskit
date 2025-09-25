import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baskit/screens/profile/view_models/profile_view_model.dart';

/// Tests for ProfileViewModel and ProfileState
/// 
/// Note: Auth-related state (isGoogleUser, isAnonymous, displayName, etc.) 
/// is now handled by the centralized AuthViewModel in lib/view_models/auth_view_model.dart.
/// ProfileState only contains UI-specific state: isLoading, error, successMessage.
void main() {
  group('ProfileState Tests', () {
    test('should create initial state correctly', () {
      const state = ProfileState.initial();

      // ProfileState now only contains UI-specific state
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.successMessage, null);
    });

    test('should create state with custom values correctly', () {
      const state = ProfileState(
        isLoading: false,
        error: 'Test error',
        successMessage: 'Test success',
      );

      expect(state.isLoading, false);
      expect(state.error, 'Test error');
      expect(state.successMessage, 'Test success');
    });

    test('should copy with new values correctly', () {
      const initialState = ProfileState.initial();

      final updatedState = initialState.copyWith(
        isLoading: true,
        successMessage: 'Success!',
        error: 'Error occurred',
      );

      expect(updatedState.isLoading, true);
      expect(updatedState.successMessage, 'Success!');
      expect(updatedState.error, 'Error occurred');
    });

    test('should copy with clearing error and success message', () {
      const initialState = ProfileState(
        isLoading: false,
        error: 'Some error',
        successMessage: 'Some success',
      );

      final clearedState = initialState.copyWith(
        clearError: true,
        clearSuccessMessage: true,
      );

      expect(clearedState.error, null);
      expect(clearedState.successMessage, null);
      expect(clearedState.isLoading, false); // Should remain unchanged
    });
  });

  group('ProfileViewModel Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle sign-in success message correctly', () {
      final viewModel = container.read(profileViewModelProvider.notifier);

      viewModel.onSignInSuccess();
      final state = container.read(profileViewModelProvider);

      expect(state.successMessage, 'Successfully signed in with Google! 🎉');
    });

    test('should handle sign-out message correctly', () {
      final viewModel = container.read(profileViewModelProvider.notifier);

      viewModel.onSignOut();
      final state = container.read(profileViewModelProvider);

      expect(state.successMessage, 'Signed out successfully');
    });

    test('should clear error message correctly', () {
      final viewModel = container.read(profileViewModelProvider.notifier);

      // Set an error state manually (simulating error from auth operations)
      final initialState = container.read(profileViewModelProvider);
      viewModel.state = initialState.copyWith(error: 'Test error');

      expect(container.read(profileViewModelProvider).error, 'Test error');

      // Clear error
      viewModel.clearError();

      expect(container.read(profileViewModelProvider).error, null);
    });

    test('should clear success message correctly', () {
      final viewModel = container.read(profileViewModelProvider.notifier);

      viewModel.onSignInSuccess();
      expect(
        container.read(profileViewModelProvider).successMessage,
        isNotNull,
      );

      viewModel.clearSuccessMessage();
      expect(container.read(profileViewModelProvider).successMessage, null);
    });

    test('should clear both messages correctly', () {
      final viewModel = container.read(profileViewModelProvider.notifier);

      // Set both error and success
      final initialState = container.read(profileViewModelProvider);
      viewModel.state = initialState.copyWith(
        error: 'Test error',
        successMessage: 'Test success',
      );

      expect(container.read(profileViewModelProvider).error, 'Test error');
      expect(
        container.read(profileViewModelProvider).successMessage,
        'Test success',
      );

      // Clear both
      viewModel.clearMessages();

      expect(container.read(profileViewModelProvider).error, null);
      expect(container.read(profileViewModelProvider).successMessage, null);
    });
  });
}
