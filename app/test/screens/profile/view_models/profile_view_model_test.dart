import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baskit/screens/profile/view_models/profile_view_model.dart';

void main() {
  group('ProfileState Tests', () {
    test('should create initial state correctly', () {
      const state = ProfileState.initial();

      expect(state.isGoogleUser, false);
      expect(state.isAnonymous, true);
      expect(state.displayName, 'Guest User');
      expect(state.email, null);
      expect(state.photoURL, null);
      expect(state.isLoading, true);
      expect(state.error, null);
      expect(state.successMessage, null);
    });

    test('should create state with custom values correctly', () {
      const state = ProfileState(
        isGoogleUser: true,
        isAnonymous: false,
        displayName: 'John Doe',
        email: 'john@example.com',
        photoURL: 'https://example.com/photo.jpg',
        isLoading: false,
        error: 'Test error',
        successMessage: 'Test success',
      );

      expect(state.isGoogleUser, true);
      expect(state.isAnonymous, false);
      expect(state.displayName, 'John Doe');
      expect(state.email, 'john@example.com');
      expect(state.photoURL, 'https://example.com/photo.jpg');
      expect(state.isLoading, false);
      expect(state.error, 'Test error');
      expect(state.successMessage, 'Test success');
    });

    test('should copy with new values correctly', () {
      const initialState = ProfileState.initial();

      final updatedState = initialState.copyWith(
        isLoading: false,
        successMessage: 'Success!',
        error: 'Error occurred',
      );

      expect(updatedState.isLoading, false);
      expect(updatedState.successMessage, 'Success!');
      expect(updatedState.error, 'Error occurred');
      // Other values should remain the same
      expect(updatedState.isGoogleUser, initialState.isGoogleUser);
      expect(updatedState.displayName, initialState.displayName);
      expect(updatedState.isAnonymous, initialState.isAnonymous);
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
