import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_list_model.dart';
import '../../../models/shopping_item_model.dart';
import '../../../repositories/shopping_repository.dart';
import '../../../providers/repository_providers.dart';
import '../../../services/permission_service.dart';
import '../../../view_models/auth_view_model.dart';

/// State class for the list detail screen
///
/// Authentication state (isAnonymous) is now handled by the centralized AuthViewModel.
class ListDetailState {
  final ShoppingList? list;
  final bool isLoading;
  final bool isAddingItem;
  final Set<String> processingItems;
  final bool isProcessingListAction;
  final String? error;

  const ListDetailState({
    this.list,
    required this.isLoading,
    required this.isAddingItem,
    required this.processingItems,
    required this.isProcessingListAction,
    this.error,
  });

  // Initial loading state
  const ListDetailState.loading()
    : this(
        isLoading: true,
        isAddingItem: false,
        processingItems: const {},
        isProcessingListAction: false,
      );

  // State with loaded list
  factory ListDetailState.loaded(ShoppingList list) {
    return ListDetailState(
      list: list,
      isLoading: false,
      isAddingItem: false,
      processingItems: const {},
      isProcessingListAction: false,
    );
  }

  // Error state
  factory ListDetailState.error(String error) {
    return ListDetailState(
      isLoading: false,
      isAddingItem: false,
      processingItems: const {},
      isProcessingListAction: false,
      error: error,
    );
  }

  // Copy with method for state updates
  ListDetailState copyWith({
    ShoppingList? list,
    bool? isLoading,
    bool? isAddingItem,
    Set<String>? processingItems,
    bool? isProcessingListAction,
    String? error,
    bool clearError = false,
  }) {
    return ListDetailState(
      list: list ?? this.list,
      isLoading: isLoading ?? this.isLoading,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      processingItems: processingItems ?? this.processingItems,
      isProcessingListAction:
          isProcessingListAction ?? this.isProcessingListAction,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for managing list detail screen state and business logic
///
/// Authentication state is now handled by the centralized AuthViewModel.
class ListDetailViewModel extends Notifier<ListDetailState> {
  ListDetailViewModel(this.listId);

  final String listId;
  late final ShoppingRepository _repository;
  final Uuid _uuid = const Uuid();

  @override
  ListDetailState build() {
    _repository = ref.read(shoppingRepositoryProvider);

    // Clean up resources when disposing
    ref.onDispose(() {
      _repository.disposeListStream(listId);
    });

    // Initialize stream
    _initializeListStream();
    return ListDetailState.loading();
  }

  /// Get current user ID from auth provider
  String? get _currentUserId => ref.read(authUserProvider)?.uid;

  // Initialize the list stream for real-time updates
  void _initializeListStream() {
    final listStream = _repository.watchList(listId);
    listStream.listen(
      (list) {
        if (list != null) {
          state = ListDetailState.loaded(list);
        } else {
          state = ListDetailState.error('List not found');
        }
      },
      onError: (error) {
        state = ListDetailState.error(error.toString());
      },
    );
  }

  /// Validate permission and get error message if denied
  String? validatePermission(String permissionType) {
    if (state.list == null) return 'List not available';

    return PermissionService.validatePermission(
      state.list!,
      _currentUserId,
      permissionType,
    );
  }

  // Add new item with optimistic UI and state management
  Future<bool> addItem(String itemName, String? quantity) async {
    // Validate input
    if (itemName.trim().isEmpty || state.list == null) return false;

    // Check permissions
    final permissionError = validatePermission('write');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Prevent multiple simultaneous calls
    if (state.isAddingItem) return false;

    // Set loading state
    state = state.copyWith(isAddingItem: true, clearError: true);

    try {
      final newItem = ShoppingItem(
        id: _uuid.v4(),
        name: itemName.trim(),
        quantity: quantity?.trim().isEmpty == true ? null : quantity?.trim(),
        createdAt: DateTime.now(),
      );

      final success = await _repository.addItem(listId, newItem);

      if (!success) {
        throw Exception('Failed to add item');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(
        isAddingItem: false,
        error:
            'Failed to add item: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    } finally {
      // Reset loading state
      if (state.isAddingItem) {
        state = state.copyWith(isAddingItem: false);
      }
    }
  }

  // Toggle item completion with debouncing
  Future<bool> toggleItemCompletion(ShoppingItem item) async {
    // Check permissions
    final permissionError = validatePermission('write');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Prevent multiple simultaneous calls for this item
    if (state.processingItems.contains(item.id)) return false;

    // Add item to processing set
    final newProcessingItems = Set<String>.from(state.processingItems);
    newProcessingItems.add(item.id);
    state = state.copyWith(
      processingItems: newProcessingItems,
      clearError: true,
    );

    try {
      final success = await _repository.updateItem(
        listId,
        item.id,
        completed: !item.isCompleted,
      );

      if (!success) {
        throw Exception('Failed to update item');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error updating item: $e');
      return false;
    } finally {
      // Remove item from processing set
      final updatedProcessingItems = Set<String>.from(state.processingItems);
      updatedProcessingItems.remove(item.id);
      state = state.copyWith(processingItems: updatedProcessingItems);
    }
  }

  // Delete item with undo functionality
  Future<bool> deleteItemWithUndo(ShoppingItem item) async {
    // Check permissions
    final permissionError = validatePermission('delete');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Prevent multiple simultaneous calls for this item
    if (state.processingItems.contains(item.id)) return false;

    // Add item to processing set
    final newProcessingItems = Set<String>.from(state.processingItems);
    newProcessingItems.add(item.id);
    state = state.copyWith(
      processingItems: newProcessingItems,
      clearError: true,
    );

    try {
      final success = await _repository.deleteItem(listId, item.id);

      if (!success) {
        throw Exception('Failed to delete item');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error deleting item: $e');
      return false;
    } finally {
      // Remove item from processing set
      final updatedProcessingItems = Set<String>.from(state.processingItems);
      updatedProcessingItems.remove(item.id);
      state = state.copyWith(processingItems: updatedProcessingItems);
    }
  }

  // Undo delete by re-adding the item
  Future<bool> undoDeleteItem(ShoppingItem item) async {
    // Check permissions (same as add item)
    final permissionError = validatePermission('write');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    try {
      final success = await _repository.addItem(listId, item);

      if (!success) {
        throw Exception('Failed to restore item');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error restoring item: $e');
      return false;
    }
  }

  // Edit item (update name and/or quantity)
  Future<bool> editItem(
    ShoppingItem item,
    String newName,
    String? newQuantity,
  ) async {
    // Validate input
    if (newName.trim().isEmpty) return false;

    // Check permissions
    final permissionError = validatePermission('write');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Prevent multiple simultaneous calls for this item
    if (state.processingItems.contains(item.id)) return false;

    // Add item to processing set
    final newProcessingItems = Set<String>.from(state.processingItems);
    newProcessingItems.add(item.id);
    state = state.copyWith(
      processingItems: newProcessingItems,
      clearError: true,
    );

    try {
      final success = await _repository.updateItem(
        listId,
        item.id,
        name: newName.trim(),
        quantity:
            newQuantity?.trim().isEmpty == true ? null : newQuantity?.trim(),
      );

      if (!success) {
        throw Exception('Failed to update item');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error updating item: $e');
      return false;
    } finally {
      // Remove item from processing set
      final updatedProcessingItems = Set<String>.from(state.processingItems);
      updatedProcessingItems.remove(item.id);
      state = state.copyWith(processingItems: updatedProcessingItems);
    }
  }

  // Delete the entire list
  Future<bool> deleteList() async {
    if (state.list == null) return false;

    // Check permissions
    final permissionError = validatePermission('delete_list');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Set list-level processing state
    state = state.copyWith(isProcessingListAction: true, clearError: true);

    try {
      final success = await _repository.deleteList(listId);

      if (!success) {
        throw Exception('Failed to delete list');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error deleting list: $e');
      return false;
    } finally {
      // Reset processing state
      state = state.copyWith(isProcessingListAction: false);
    }
  }

  // Share list with user by email
  Future<bool> shareList(String email) async {
    if (state.list == null) return false;

    // Check permissions
    final permissionError = validatePermission('share');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Set list-level processing state
    state = state.copyWith(isProcessingListAction: true, clearError: true);

    try {
      final result = await _repository.shareList(listId, email);

      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Failed to share list');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error sharing list: $e');
      return false;
    } finally {
      // Reset processing state
      state = state.copyWith(isProcessingListAction: false);
    }
  }

  // Clear all completed items from the list
  Future<bool> clearCompletedItems() async {
    if (state.list == null) return false;

    // Check permissions
    final permissionError = validatePermission('delete');
    if (permissionError != null) {
      state = state.copyWith(error: permissionError);
      return false;
    }

    // Set list-level processing state
    state = state.copyWith(isProcessingListAction: true, clearError: true);

    try {
      final success = await _repository.clearCompleted(listId);

      if (!success) {
        throw Exception('Failed to clear completed items');
      }

      return true;
    } catch (e) {
      // Set error state
      state = state.copyWith(error: 'Error clearing completed items: $e');
      return false;
    } finally {
      // Reset processing state
      state = state.copyWith(isProcessingListAction: false);
    }
  }
}

// Provider for ListDetailViewModel
final listDetailViewModelProvider =
    NotifierProvider.family<ListDetailViewModel, ListDetailState, String>(
      ListDetailViewModel.new,
    );
