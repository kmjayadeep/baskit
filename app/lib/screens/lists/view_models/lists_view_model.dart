import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/shopping_list_model.dart';
import '../../../repositories/shopping_repository.dart';
import '../../../providers/repository_providers.dart';
import '../../../view_models/auth_view_model.dart';

// State class to hold lists data with loading and error states
class ListsState {
  final List<ShoppingList> lists;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const ListsState({
    required this.lists,
    required this.isLoading,
    required this.isRefreshing,
    this.error,
  });

  // Helper factory constructors
  const ListsState.initial()
    : this(lists: const [], isLoading: true, isRefreshing: false);

  const ListsState.loading()
    : this(lists: const [], isLoading: true, isRefreshing: false);

  const ListsState.data(List<ShoppingList> lists)
    : this(lists: lists, isLoading: false, isRefreshing: false);

  const ListsState.error(String error, List<ShoppingList> lists)
    : this(lists: lists, isLoading: false, isRefreshing: false, error: error);

  // copyWith method for state updates
  ListsState copyWith({
    List<ShoppingList>? lists,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return ListsState(
      lists: lists ?? this.lists,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ViewModel for managing shopping lists state and business logic
class ListsViewModel extends Notifier<ListsState> {
  late final ShoppingRepository _repository;
  StreamSubscription<List<ShoppingList>>? _listsSubscription;
  bool _isFirstLoad = true;

  @override
  ListsState build() {
    _repository = ref.read(shoppingRepositoryProvider);

    // Automatically reinitialize lists stream when auth state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      // Only reinitialize if auth status actually changed
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.user?.uid != next.user?.uid) {
        initializeListsStream();
      }
    });

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _listsSubscription?.cancel();
    });

    // Initialize stream and return initial state
    initializeListsStream();
    return const ListsState.initial();
  }

  // Initialize the lists stream for real-time updates
  void initializeListsStream() {
    // Cancel existing subscription
    _listsSubscription?.cancel();

    // Show the loading state only on the initial load. When re-subscribing
    // (auth change, pull-to-refresh), keep the current lists visible so the
    // page does not flash to an empty spinner between resubscribe and the
    // next stream emission.
    if (_isFirstLoad) {
      state = const ListsState.loading();
    }

    // Create new stream subscription
    _listsSubscription = _repository.watchLists().listen(
      (lists) {
        _isFirstLoad = false;
        state = ListsState.data(lists);
      },
      onError: (error) {
        state = ListsState.error(error.toString(), state.lists);
      },
    );
  }

  // Note: Authentication state changes are now handled automatically
  // by ref.listen() in the build() method

  // Refresh lists (pull to refresh) with debouncing
  Future<void> refreshLists() async {
    if (state.isRefreshing) return;

    // Set refreshing state
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // Force sync with Firebase if available
      await _repository.sync();

      // Re-subscribe so the UI reflects the synced data. Keep existing lists
      // visible until the stream emits (initializeListsStream no longer
      // resets to a loading state after the initial load), and clear the
      // refreshing flag here because the stream listener does not know
      // about it.
      initializeListsStream();
      state = state.copyWith(isRefreshing: false);
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Failed to refresh lists: ${error.toString()}',
      );
    }
  }
}

// Provider for ListsViewModel with automatic auth state watching
final listsViewModelProvider = NotifierProvider<ListsViewModel, ListsState>(
  ListsViewModel.new,
);
