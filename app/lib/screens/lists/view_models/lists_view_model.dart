import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/shopping_list_model.dart';
import '../../../repositories/shopping_repository.dart';
import '../../../providers/repository_providers.dart';

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

  const ListsState.refreshing(List<ShoppingList> lists)
    : this(lists: lists, isLoading: false, isRefreshing: true);

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
class ListsViewModel extends StateNotifier<ListsState> {
  final ShoppingRepository _repository;
  StreamSubscription<List<ShoppingList>>? _listsSubscription;

  ListsViewModel(this._repository) : super(const ListsState.initial()) {
    initializeListsStream();
  }

  // Initialize the lists stream for real-time updates
  void initializeListsStream() {
    // Cancel existing subscription
    _listsSubscription?.cancel();

    // Set loading state
    state = const ListsState.loading();

    // Create new stream subscription
    _listsSubscription = _repository.watchLists().listen(
      (lists) {
        if (mounted) {
          state = ListsState.data(lists);
        }
      },
      onError: (error) {
        if (mounted) {
          state = ListsState.error(error.toString(), state.lists);
        }
      },
    );
  }

  // Handle authentication state changes
  void onAuthStateChanged() {
    // Reinitialize the stream when auth state changes
    initializeListsStream();
  }

  // Refresh lists (pull to refresh) with debouncing
  Future<void> refreshLists() async {
    if (state.isRefreshing) return;

    // Set refreshing state
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // Force sync with Firebase if available
      await _repository.sync();

      // Refresh the stream - the stream listener will update the state
      initializeListsStream();
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          isRefreshing: false,
          error: 'Failed to refresh lists: ${error.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _listsSubscription?.cancel();
    super.dispose();
  }
}

// Provider for ListsViewModel
final listsViewModelProvider =
    StateNotifierProvider<ListsViewModel, ListsState>((ref) {
      final repository = ref.read(shoppingRepositoryProvider);
      return ListsViewModel(repository);
    });
