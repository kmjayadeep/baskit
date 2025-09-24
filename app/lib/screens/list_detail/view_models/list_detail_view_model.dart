import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_list_model.dart';
import '../../../models/shopping_item_model.dart';
import '../../../services/storage_service.dart';

/// State class for the list detail screen
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
  const ListDetailState.loaded(ShoppingList list)
    : this(
        list: list,
        isLoading: false,
        isAddingItem: false,
        processingItems: const {},
        isProcessingListAction: false,
      );

  // Error state
  const ListDetailState.error(String error)
    : this(
        isLoading: false,
        isAddingItem: false,
        processingItems: const {},
        isProcessingListAction: false,
        error: error,
      );

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
class ListDetailViewModel extends StateNotifier<ListDetailState> {
  final StorageService _storageService;
  final String _listId;
  final Uuid _uuid = const Uuid();

  ListDetailViewModel(this._storageService, this._listId)
    : super(const ListDetailState.loading()) {
    _initializeListStream();
  }

  // Initialize the list stream for real-time updates
  void _initializeListStream() {
    final listStream = _storageService.watchList(_listId);
    listStream.listen(
      (list) {
        if (list != null && mounted) {
          state = ListDetailState.loaded(list);
        } else if (list == null && mounted) {
          state = const ListDetailState.error('List not found');
        }
      },
      onError: (error) {
        if (mounted) {
          state = ListDetailState.error(error.toString());
        }
      },
    );
  }

  @override
  void dispose() {
    // Clean up the list stream when disposing
    _storageService.disposeListStream(_listId);
    super.dispose();
  }

  // Add new item with optimistic UI and state management
  Future<bool> addItem(String itemName, String? quantity) async {
    // Validate input
    if (itemName.trim().isEmpty || state.list == null) return false;

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

      final success = await _storageService.addItem(_listId, newItem);

      if (!success) {
        throw Exception('Failed to add item');
      }

      return true;
    } catch (e) {
      // Set error state
      if (mounted) {
        state = state.copyWith(
          isAddingItem: false,
          error:
              'Failed to add item: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
      return false;
    } finally {
      // Reset loading state if still mounted
      if (mounted && state.isAddingItem) {
        state = state.copyWith(isAddingItem: false);
      }
    }
  }

  // Toggle item completion with debouncing
  Future<bool> toggleItemCompletion(ShoppingItem item) async {
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
      final success = await _storageService.updateItem(
        _listId,
        item.id,
        completed: !item.isCompleted,
      );

      if (!success) {
        throw Exception('Failed to update item');
      }

      return true;
    } catch (e) {
      // Set error state
      if (mounted) {
        state = state.copyWith(error: 'Error updating item: $e');
      }
      return false;
    } finally {
      // Remove item from processing set
      if (mounted) {
        final updatedProcessingItems = Set<String>.from(state.processingItems);
        updatedProcessingItems.remove(item.id);
        state = state.copyWith(processingItems: updatedProcessingItems);
      }
    }
  }

  // Delete item with undo functionality
  Future<bool> deleteItemWithUndo(ShoppingItem item) async {
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
      final success = await _storageService.deleteItem(_listId, item.id);

      if (!success) {
        throw Exception('Failed to delete item');
      }

      return true;
    } catch (e) {
      // Set error state
      if (mounted) {
        state = state.copyWith(error: 'Error deleting item: $e');
      }
      return false;
    } finally {
      // Remove item from processing set
      if (mounted) {
        final updatedProcessingItems = Set<String>.from(state.processingItems);
        updatedProcessingItems.remove(item.id);
        state = state.copyWith(processingItems: updatedProcessingItems);
      }
    }
  }

  // Undo delete by re-adding the item
  Future<bool> undoDeleteItem(ShoppingItem item) async {
    try {
      final success = await _storageService.addItem(_listId, item);

      if (!success) {
        throw Exception('Failed to restore item');
      }

      return true;
    } catch (e) {
      // Set error state
      if (mounted) {
        state = state.copyWith(error: 'Error restoring item: $e');
      }
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
      final success = await _storageService.updateItem(
        _listId,
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
      if (mounted) {
        state = state.copyWith(error: 'Error updating item: $e');
      }
      return false;
    } finally {
      // Remove item from processing set
      if (mounted) {
        final updatedProcessingItems = Set<String>.from(state.processingItems);
        updatedProcessingItems.remove(item.id);
        state = state.copyWith(processingItems: updatedProcessingItems);
      }
    }
  }

  // TODO: Add remaining business logic methods in next steps:
  // - deleteList()
  // - shareList()
  // - clearCompletedItems()
}

// Provider for ListDetailViewModel
final listDetailViewModelProvider =
    StateNotifierProvider.family<ListDetailViewModel, ListDetailState, String>(
      (ref, listId) => ListDetailViewModel(StorageService.instance, listId),
    );
