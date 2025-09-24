import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_item_model.dart';
import '../../services/storage_service.dart';
import '../../services/firebase_auth_service.dart';
import 'widgets/list_header_widget.dart';
import 'widgets/add_item_widget.dart';
import 'widgets/empty_items_state_widget.dart';
import 'widgets/item_card_widget.dart';
import 'widgets/dialogs/edit_item_dialog.dart';
import 'widgets/dialogs/sign_in_prompt_dialog.dart';
import 'widgets/dialogs/share_list_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';
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
  bool _isProcessingListAction =
      false; // Track list-level actions for non-ViewModel operations

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to add item'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _addItem(currentList),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Error updating item'),
          backgroundColor: Colors.red,
        ),
      );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error ?? 'Error restoring item'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      );
    } else if (!success && mounted) {
      // Show error message if delete failed
      final state = ref.read(listDetailViewModelProvider(widget.listId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Error deleting item'),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Error updating item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete list with confirmation using extracted dialog
  Future<void> _deleteList(ShoppingList currentList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(list: currentList),
    );

    if (confirmed == true) {
      try {
        final success = await StorageService.instance.deleteList(
          currentList.id,
        );
        if (success && mounted) {
          context.go('/lists');
        } else {
          throw Exception('Failed to delete list');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting list: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show share dialog using extracted widgets
  Future<void> _showShareDialog(ShoppingList currentList) async {
    // Prevent multiple simultaneous calls
    if (_isProcessingListAction) return;

    // Check if user is anonymous
    if (FirebaseAuthService.isAnonymous) {
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

    // User is authenticated, show the share dialog
    await showDialog(
      context: context,
      builder:
          (context) => ShareListDialog(
            list: currentList,
            onShare: (email) => _shareList(currentList, email),
          ),
    );
  }

  // Share list with user by email
  Future<void> _shareList(ShoppingList currentList, String email) async {
    try {
      final result = await StorageService.instance.shareList(
        currentList.id,
        email,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('List shared with $email successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ??
                    'Failed to share list. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing list: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  // Clear completed items with confirmation and debouncing
  Future<void> _clearCompletedItems(ShoppingList list) async {
    // Prevent multiple simultaneous calls
    if (_isProcessingListAction) return;

    final completedCount = list.completedItemsCount;

    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed items to clear'),
          duration: Duration(seconds: 2),
        ),
      );
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
      setState(() {
        _isProcessingListAction = true;
      });

      try {
        final success = await StorageService.instance.clearCompleted(list.id);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cleared $completedCount completed ${completedCount == 1 ? 'item' : 'items'}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to clear completed items. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing items: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingListAction = false;
          });
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(list),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editList(list),
            tooltip: 'Edit List',
          ),
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  if (list.completedItemsCount >
                      0) // Only show if there are completed items
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
                ],
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
          ListHeaderWidget(list: list),

          // Add item section
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
                            onToggleCompleted: _toggleItemCompletion,
                            onDelete: (item) => _deleteItemWithUndo(item, list),
                            onEdit: _editItem,
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
