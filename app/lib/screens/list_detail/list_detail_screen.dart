import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_item_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/permission_service.dart';
import '../../extensions/shopping_list_extensions.dart';
import 'widgets/list_header_widget.dart';
import 'widgets/add_item_widget.dart';
import 'widgets/empty_items_state_widget.dart';
import 'widgets/item_card_widget.dart';
import 'widgets/dialogs/edit_item_dialog.dart';
import 'widgets/dialogs/sign_in_prompt_dialog.dart';
import 'widgets/dialogs/enhanced_share_list_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';
import 'widgets/dialogs/member_list_dialog.dart';
import '../lists/list_form_screen.dart';
import 'view_models/list_detail_view_model.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _addItemController = TextEditingController();
  final _addQuantityController = TextEditingController();

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    super.dispose();
  }

  /// Check if current user has permission for an action
  bool _hasPermission(String permissionType, ShoppingList list) {
    final currentUserId = ref.read(authUserProvider)?.uid;
    return PermissionService.hasListPermission(
      list,
      currentUserId,
      permissionType,
    );
  }

  // Helper methods for consistent SnackBar handling
  void _showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorWithRetrySnackBar(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  // Add new item using ViewModel
  Future<void> _addItem(ShoppingList currentList) async {
    final itemName = _addItemController.text.trim();
    final quantity = _addQuantityController.text.trim();

    if (itemName.isEmpty) return;

    // Clear input fields immediately for instant feedback
    _addItemController.clear();
    _addQuantityController.clear();

    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.addItem(
      itemName,
      quantity.isEmpty ? null : quantity,
    );

    // Handle failure - restore input and show retry option
    if (!success && mounted) {
      // Restore the input values so user can retry
      _addItemController.text = itemName;
      _addQuantityController.text = quantity;

      final state = ref.read(listDetailViewModelProvider(widget.listId));
      _showErrorWithRetrySnackBar(
        state.error ?? 'Failed to add item',
        () => _addItem(currentList),
      );
    }
  }

  // Toggle item completion using ViewModel
  Future<void> _toggleItemCompletion(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.toggleItemCompletion(item);

    // Show error message if operation failed
    if (!success && mounted) {
      final state = ref.read(listDetailViewModelProvider(widget.listId));
      _showErrorSnackBar(state.error ?? 'Error updating item');
    }
  }

  // Delete item with undo functionality using ViewModel
  Future<void> _deleteItemWithUndo(
    ShoppingItem item,
    ShoppingList currentList,
  ) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.deleteItemWithUndo(item);

    if (success && mounted) {
      // Show snackbar with undo option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              final undoSuccess = await viewModel.undoDeleteItem(item);
              if (!undoSuccess && mounted) {
                final state = ref.read(
                  listDetailViewModelProvider(widget.listId),
                );
                _showErrorSnackBar(state.error ?? 'Error restoring item');
              }
            },
          ),
        ),
      );
    } else if (!success && mounted) {
      // Show error message if delete failed
      final state = ref.read(listDetailViewModelProvider(widget.listId));
      _showErrorSnackBar(state.error ?? 'Error deleting item');
    }
  }

  // Edit item using ViewModel and extracted dialog
  Future<void> _editItem(ShoppingItem item) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );

    if (result != null && mounted) {
      final newName = result['name']!;
      final newQuantity = result['quantity'];

      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final success = await viewModel.editItem(item, newName, newQuantity);

      // Show error message if operation failed
      if (!success && mounted) {
        final state = ref.read(listDetailViewModelProvider(widget.listId));
        _showErrorSnackBar(state.error ?? 'Error updating item');
      }
    }
  }

  // Delete list with confirmation using ViewModel
  Future<void> _deleteList(ShoppingList currentList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(list: currentList),
    );

    if (confirmed == true && mounted) {
      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final success = await viewModel.deleteList();

      if (success && mounted) {
        context.go('/lists');
      } else if (!success && mounted) {
        final state = ref.read(listDetailViewModelProvider(widget.listId));
        _showErrorSnackBar(state.error ?? 'Error deleting list');
      }
    }
  }

  // Show share dialog using extracted widgets
  Future<void> _showShareDialog(ShoppingList currentList) async {
    // Check if user is anonymous using centralized auth
    final authState = ref.read(authViewModelProvider);

    if (authState.isAnonymous) {
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (context) => const SignInPromptDialog(),
      );

      // Navigate to profile page if user chose to sign in
      if (shouldNavigate == true && mounted) {
        context.push('/profile');
      }
      return;
    }

    // User is authenticated, show the enhanced share dialog
    await showDialog(
      context: context,
      builder:
          (context) => EnhancedShareListDialog(
            list: currentList,
            onShare: (email) => _shareList(currentList, email),
          ),
    );
  }

  // Share list with user by email using ViewModel
  Future<void> _shareList(ShoppingList currentList, String email) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.shareList(email);

    if (mounted) {
      if (success) {
        _showSuccessSnackBar('List shared with $email successfully!');
      } else {
        final state = ref.read(listDetailViewModelProvider(widget.listId));
        _showErrorSnackBar(state.error ?? 'Failed to share list');
      }
    }
  }

  // Navigate to edit list screen
  void _editList(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListFormScreen(existingList: list),
      ),
    );
  }

  // Show the member list dialog
  void _showMemberList(ShoppingList list) {
    final authState = ref.read(authViewModelProvider);

    showDialog(
      context: context,
      builder:
          (context) => MemberListDialog(
            list: list,
            currentUserEmail: authState.email,
            currentUserId: authState.user?.uid, // Firebase UID for ownership
            onInviteMore: () {
              Navigator.of(context).pop(); // Close member list dialog
              _showShareDialog(list); // Open share dialog
            },
          ),
    );
  }

  // Clear completed items with confirmation using ViewModel
  Future<void> _clearCompletedItems(ShoppingList list) async {
    final completedCount = list.completedItemsCount;

    if (completedCount == 0) {
      _showInfoSnackBar('No completed items to clear');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.clear_all, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Clear Completed Items'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently remove $completedCount completed ${completedCount == 1 ? 'item' : 'items'} from "${list.name}".',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This is useful for reusing lists like weekly grocery lists.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Items'),
              ),
            ],
          ),
    );

    if (shouldClear == true && mounted) {
      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final success = await viewModel.clearCompletedItems();

      if (mounted) {
        if (success) {
          _showSuccessSnackBar(
            'Cleared $completedCount completed ${completedCount == 1 ? 'item' : 'items'}',
          );
        } else {
          final state = ref.read(listDetailViewModelProvider(widget.listId));
          _showErrorSnackBar(
            state.error ?? 'Failed to clear completed items',
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listDetailViewModelProvider(widget.listId));

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading list'),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final list = state.list;
    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('List Not Found')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.grey),
              Text('List not found or no longer available'),
            ],
          ),
        ),
      );
    }

    final listColor = list.displayColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/lists');
            }
          },
        ),
        title: Text(list.name),
        backgroundColor: listColor.withValues(alpha: 0.1),
        actions: [
          // Share button - only show if user can share
          if (_hasPermission('share', list))
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(list),
              tooltip: 'Share List',
            ),
          // Edit button - only show if user can edit metadata
          if (_hasPermission('edit_metadata', list))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editList(list),
              tooltip: 'Edit List',
            ),
          // Menu with permission-based items - only show if there are valid actions
          if ((_hasPermission('delete', list) &&
                  list.completedItemsCount > 0) ||
              _hasPermission('delete_list', list))
            PopupMenuButton(
              itemBuilder: (context) {
                final menuItems = <PopupMenuEntry<String>>[];

                // Clear completed - only if user can delete and there are completed items
                if (_hasPermission('delete', list) &&
                    list.completedItemsCount > 0) {
                  menuItems.add(
                    const PopupMenuItem(
                      value: 'clear_completed',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Clear Completed Items',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Delete list - only if user can delete list (owner only)
                if (_hasPermission('delete_list', list)) {
                  menuItems.add(
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete List',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return menuItems;
              },
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteList(list);
                } else if (value == 'clear_completed') {
                  _clearCompletedItems(list);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // List info header
          ListHeaderWidget(
            list: list,
            onShowMembers: () => _showMemberList(list),
          ),

          // Add item section - only show if user can write
          if (_hasPermission('write', list))
            AddItemWidget(
              list: list,
              itemController: _addItemController,
              quantityController: _addQuantityController,
              isAddingItem: state.isAddingItem,
              onAddItem: () => _addItem(list),
            ),

          // Items list
          Expanded(
            child:
                list.items.isEmpty
                    ? const EmptyItemsStateWidget()
                    : SafeArea(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.sortedItems.length,
                        itemBuilder: (context, index) {
                          final item = list.sortedItems[index];
                          return ItemCardWidget(
                            key: ValueKey(item.id),
                            item: item,
                            isProcessing: state.processingItems.contains(
                              item.id,
                            ),
                            onToggleCompleted:
                                _hasPermission('write', list)
                                    ? _toggleItemCompletion
                                    : null,
                            onDelete:
                                _hasPermission('delete', list)
                                    ? (item) => _deleteItemWithUndo(item, list)
                                    : null,
                            onEdit:
                                _hasPermission('write', list)
                                    ? _editItem
                                    : null,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
