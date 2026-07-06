import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/action_result.dart';
import '../../../models/shopping_item_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../providers/repository_providers.dart';
import '../../../repositories/shopping_repository.dart';
import '../../../services/permission_service.dart';
import '../../../view_models/auth_view_model.dart';

/// State for the list detail screen.
///
/// [error] stores the latest load or action error for tests and diagnostics. The
/// UI should use [hasLoadError] to decide whether to replace the page with an
/// error screen; action errors are returned directly from ViewModel methods.
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

  const ListDetailState.loading()
    : this(
        isLoading: true,
        isAddingItem: false,
        processingItems: const {},
        isProcessingListAction: false,
      );

  factory ListDetailState.loaded(ShoppingList list) {
    return ListDetailState(
      list: list,
      isLoading: false,
      isAddingItem: false,
      processingItems: const {},
      isProcessingListAction: false,
    );
  }

  factory ListDetailState.error(String error) {
    return ListDetailState(
      isLoading: false,
      isAddingItem: false,
      processingItems: const {},
      isProcessingListAction: false,
      error: error,
    );
  }

  bool get hasLoadError => !isLoading && list == null && error != null;

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

/// ViewModel for managing list detail screen state and business logic.
class ListDetailViewModel extends Notifier<ListDetailState> {
  ListDetailViewModel(this.listId);

  final String listId;
  late ShoppingRepository _repository;
  final Uuid _uuid = const Uuid();
  StreamSubscription<ShoppingList?>? _listSubscription;

  @override
  ListDetailState build() {
    _repository = ref.read(shoppingRepositoryProvider);

    ref.onDispose(() {
      _listSubscription?.cancel();
      _listSubscription = null;
      _repository.disposeListStream(listId);
    });

    _initializeListStream();
    return ListDetailState.loading();
  }

  String? get _currentUserId => ref.read(authUserProvider)?.uid;

  /// Retry loading the list by recreating the list subscription.
  void retryLoad() {
    state = const ListDetailState.loading();
    _initializeListStream();
  }

  void _initializeListStream() {
    _listSubscription?.cancel();
    _listSubscription = _repository
        .watchList(listId)
        .listen(
          (list) {
            if (list != null) {
              state = state.copyWith(
                list: list,
                isLoading: false,
                clearError: true,
              );
            } else {
              state = ListDetailState.error('List not found');
            }
          },
          onError: (error) {
            state = ListDetailState.error(error.toString());
          },
        );
  }

  /// Validate permission and get error message if denied.
  String? validatePermission(ListPermission permission) {
    final list = state.list;
    if (list == null) return 'List not available';

    return PermissionService.validatePermission(
      list,
      _currentUserId,
      permission,
    );
  }

  Future<ActionResult> addItem(String itemName, String? quantity) async {
    final list = state.list;
    final trimmedName = itemName.trim();
    if (trimmedName.isEmpty) {
      return const ActionResult.failure('Item name is required');
    }
    if (list == null) return const ActionResult.failure('List not available');

    final permissionError = validatePermission(ListPermission.write);
    if (permissionError != null) return _fail(permissionError);

    if (state.isAddingItem) {
      return const ActionResult.failure('An item is already being added');
    }

    state = state.copyWith(isAddingItem: true, clearError: true);

    try {
      final newItem = ShoppingItem(
        id: _uuid.v4(),
        name: trimmedName,
        quantity: _blankToNull(quantity),
        createdAt: DateTime.now(),
      );

      final success = await _repository.addItem(listId, newItem);
      if (!success) throw Exception('Failed to add item');

      return const ActionResult.success();
    } catch (e) {
      return _fail('Failed to add item: ${_cleanError(e)}');
    } finally {
      if (state.isAddingItem) {
        state = state.copyWith(isAddingItem: false);
      }
    }
  }

  Future<ActionResult> toggleItemCompletion(ShoppingItem item) {
    return _runItemAction(
      item,
      permission: ListPermission.write,
      failureMessage: 'Failed to update item',
      errorPrefix: 'Error updating item',
      action:
          () => _repository.updateItem(
            listId,
            item.id,
            completed: !item.isCompleted,
          ),
    );
  }

  Future<ActionResult> deleteItem(ShoppingItem item) {
    return _runItemAction(
      item,
      permission: ListPermission.deleteItems,
      failureMessage: 'Failed to delete item',
      errorPrefix: 'Error deleting item',
      action: () => _repository.deleteItem(listId, item.id),
    );
  }

  Future<ActionResult> editItem(
    ShoppingItem item,
    String newName,
    String? newQuantity,
  ) {
    if (newName.trim().isEmpty) {
      return Future.value(const ActionResult.failure('Item name is required'));
    }

    return _runItemAction(
      item,
      permission: ListPermission.write,
      failureMessage: 'Failed to update item',
      errorPrefix: 'Error updating item',
      action:
          () => _repository.updateItem(
            listId,
            item.id,
            name: newName.trim(),
            quantity: _blankToNull(newQuantity),
          ),
    );
  }

  Future<ActionResult> deleteList() {
    if (state.list == null) {
      return Future.value(const ActionResult.failure('List not available'));
    }

    return _runListAction(
      permission: ListPermission.deleteList,
      failureMessage: 'Failed to delete list',
      errorPrefix: 'Error deleting list',
      action: () => _repository.deleteList(listId),
    );
  }

  Future<ActionResult> shareList(String email) {
    if (state.list == null) {
      return Future.value(const ActionResult.failure('List not available'));
    }

    return _runListAction(
      permission: ListPermission.share,
      failureMessage: 'Failed to share list',
      errorPrefix: 'Error sharing list',
      action: () async {
        final result = await _repository.shareList(listId, email);
        if (!result.success) {
          throw Exception(result.errorMessage ?? 'Failed to share list');
        }
        return true;
      },
    );
  }

  Future<ActionResult> removeMember(String userId) async {
    final list = state.list;
    if (list == null) return const ActionResult.failure('List not available');

    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return _fail('You must be signed in to manage members');
    }

    final isSelfRemoval = userId == currentUserId;

    if (list.ownerId == userId) {
      return _fail('Cannot remove the list owner');
    }

    if (!isSelfRemoval &&
        !PermissionService.hasListPermission(
          list,
          currentUserId,
          ListPermission.manageMembers,
        )) {
      return _fail('Only the list owner can manage members');
    }

    final memberExists = list.members.any((member) => member.userId == userId);
    if (!memberExists) return _fail('Member not found in this list');

    return _runListAction(
      failureMessage: 'Failed to remove member',
      errorPrefix: 'Error removing member',
      action: () => _repository.removeMember(listId, userId),
    );
  }

  Future<ActionResult> leaveList() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return _fail('You must be signed in to leave this list');
    }

    if (state.list?.ownerId == currentUserId) {
      return _fail('List owners cannot leave their own list');
    }

    return removeMember(currentUserId);
  }

  Future<ActionResult> clearCompletedItems() {
    if (state.list == null) {
      return Future.value(const ActionResult.failure('List not available'));
    }

    return _runListAction(
      permission: ListPermission.deleteItems,
      failureMessage: 'Failed to clear completed items',
      errorPrefix: 'Error clearing completed items',
      action: () => _repository.clearCompleted(listId),
    );
  }

  Future<ActionResult> _runItemAction(
    ShoppingItem item, {
    required ListPermission permission,
    required Future<bool> Function() action,
    required String failureMessage,
    required String errorPrefix,
  }) async {
    final permissionError = validatePermission(permission);
    if (permissionError != null) return _fail(permissionError);

    if (state.processingItems.contains(item.id)) {
      return const ActionResult.failure('This item is already being updated');
    }

    _setItemProcessing(item.id, isProcessing: true);

    try {
      final success = await action();
      if (!success) throw Exception(failureMessage);
      return const ActionResult.success();
    } catch (e) {
      return _fail('$errorPrefix: ${_cleanError(e)}');
    } finally {
      _setItemProcessing(item.id, isProcessing: false);
    }
  }

  Future<ActionResult> _runListAction({
    ListPermission? permission,
    required Future<bool> Function() action,
    required String failureMessage,
    required String errorPrefix,
  }) async {
    if (permission != null) {
      final permissionError = validatePermission(permission);
      if (permissionError != null) return _fail(permissionError);
    }

    if (state.isProcessingListAction) {
      return const ActionResult.failure(
        'Another list action is already running',
      );
    }

    state = state.copyWith(isProcessingListAction: true, clearError: true);

    try {
      final success = await action();
      if (!success) throw Exception(failureMessage);
      return const ActionResult.success();
    } catch (e) {
      return _fail('$errorPrefix: ${_cleanError(e)}');
    } finally {
      state = state.copyWith(isProcessingListAction: false);
    }
  }

  ActionResult _fail(String message) {
    state = state.copyWith(error: message);
    return ActionResult.failure(message);
  }

  void _setItemProcessing(String itemId, {required bool isProcessing}) {
    final processingItems = Set<String>.from(state.processingItems);
    if (isProcessing) {
      processingItems.add(itemId);
    } else {
      processingItems.remove(itemId);
    }
    state = state.copyWith(
      processingItems: processingItems,
      clearError: isProcessing,
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

final listDetailViewModelProvider =
    NotifierProvider.family<ListDetailViewModel, ListDetailState, String>(
      ListDetailViewModel.new,
    );
