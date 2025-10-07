import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_suggestion_model.dart';
import '../services/contact_suggestions_service.dart';
import 'auth_view_model.dart';

/// State class for contact suggestions
class ContactSuggestionsState {
  final List<ContactSuggestion> contacts;
  final bool isLoading;
  final String? error;

  const ContactSuggestionsState({
    required this.contacts,
    required this.isLoading,
    this.error,
  });

  /// Initial loading state
  const ContactSuggestionsState.loading()
    : contacts = const [],
      isLoading = true,
      error = null;

  /// Loaded state with contacts
  const ContactSuggestionsState.loaded(this.contacts)
    : isLoading = false,
      error = null;

  /// Error state
  const ContactSuggestionsState.error(
    this.error, [
    List<ContactSuggestion>? previousContacts,
  ]) : contacts = previousContacts ?? const [],
       isLoading = false;

  /// Copy with method for state updates
  ContactSuggestionsState copyWith({
    List<ContactSuggestion>? contacts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ContactSuggestionsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactSuggestionsState &&
        other.contacts == contacts &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(contacts, isLoading, error);
}

/// ViewModel for managing contact suggestions state
///
/// Wraps the static ContactSuggestionsService to provide proper MVVM integration
/// with reactive state management and Riverpod providers.
class ContactSuggestionsViewModel
    extends StateNotifier<ContactSuggestionsState> {
  final Ref _ref;
  StreamSubscription<List<ContactSuggestion>>? _contactsSubscription;

  ContactSuggestionsViewModel(this._ref)
    : super(const ContactSuggestionsState.loading()) {
    initializeContactsStream();
  }

  /// Get current user ID from auth provider
  String? get _currentUserId => _ref.read(authUserProvider)?.uid;

  /// Initialize contacts stream based on current user
  void initializeContactsStream() {
    _contactsSubscription?.cancel();

    final userId = _currentUserId;
    if (userId == null) {
      state = const ContactSuggestionsState.loaded([]);
      return;
    }

    state = const ContactSuggestionsState.loading();

    _contactsSubscription = ContactSuggestionsService.getUserContacts(
      userId,
    ).listen(
      (contacts) {
        if (mounted) {
          state = ContactSuggestionsState.loaded(contacts);
        }
      },
      onError: (error) {
        if (mounted) {
          state = ContactSuggestionsState.error(
            error.toString(),
            state.contacts,
          );
        }
      },
    );
  }

  /// Refresh contacts cache
  Future<void> refreshContacts() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await ContactSuggestionsService.refreshContactCache(userId);
      initializeContactsStream();
    } catch (e) {
      if (mounted) {
        state = ContactSuggestionsState.error(
          'Failed to refresh contacts: $e',
          state.contacts,
        );
      }
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    ContactSuggestionsService.clearCache();
    super.dispose();
  }
}

// ==========================================
// PROVIDERS
// ==========================================

/// Global provider for ContactSuggestionsViewModel
final contactSuggestionsViewModelProvider =
    StateNotifierProvider<ContactSuggestionsViewModel, ContactSuggestionsState>(
      (ref) {
        final viewModel = ContactSuggestionsViewModel(ref);

        // Listen to auth changes and reinitialize when user changes
        ref.listen<String?>(authUserProvider.select((user) => user?.uid), (
          previous,
          next,
        ) {
          // Clear cache and reinitialize when user changes
          if (previous != next) {
            ContactSuggestionsService.clearCache();
            viewModel.initializeContactsStream();
          }
        });

        return viewModel;
      },
    );

/// Convenience provider for contacts list
final contactSuggestionsProvider = Provider<List<ContactSuggestion>>((ref) {
  return ref.watch(contactSuggestionsViewModelProvider).contacts;
});

/// Convenience provider for loading state
final contactSuggestionsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(contactSuggestionsViewModelProvider).isLoading;
});
