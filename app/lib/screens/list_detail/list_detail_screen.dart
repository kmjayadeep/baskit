import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list_model.dart';
import '../../models/list_member_model.dart';
import '../../models/shopping_item_model.dart';
import '../../constants/app_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/permission_service.dart';
import '../../extensions/shopping_list_extensions.dart';
import 'widgets/list_header_widget.dart';
import 'widgets/add_item_widget.dart';
import 'widgets/empty_items_state_widget.dart';
import 'widgets/items_header_widget.dart';
import 'widgets/item_card_widget.dart';
import 'widgets/completed_items_section_widget.dart';
import 'widgets/dialogs/edit_item_dialog.dart';
import 'widgets/dialogs/sign_in_prompt_dialog.dart';
import 'widgets/dialogs/enhanced_share_list_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';
import 'widgets/dialogs/member_list_dialog.dart';
import 'widgets/dialogs/leave_list_confirmation_dialog.dart';
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
  ItemsSortOption _selectedItemsSort = ItemsSortOption.status;

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

  List<ShoppingItem> _sortItems(ShoppingList list) {
    final sortedItems = [...list.items];

    int byName(ShoppingItem a, ShoppingItem b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    int byNameFallback(ShoppingItem a, ShoppingItem b) {
      final nameComparison = byName(a, b);
      if (nameComparison != 0) {
        return nameComparison;
      }

      return a.createdAt.compareTo(b.createdAt);
    }

    int byStatus(ShoppingItem a, ShoppingItem b) {
      if (a.isCompleted == b.isCompleted) {
        return 0;
      }

      return a.isCompleted ? 1 : -1;
    }

    switch (_selectedItemsSort) {
      case ItemsSortOption.status:
        return list.sortedItems;
      case ItemsSortOption.name:
        sortedItems.sort((a, b) {
          final statusComparison = byStatus(a, b);
          if (statusComparison != 0) {
            return statusComparison;
          }

          return byNameFallback(a, b);
        });
      case ItemsSortOption.newest:
        sortedItems.sort((a, b) {
          final statusComparison = byStatus(a, b);
          if (statusComparison != 0) {
            return statusComparison;
          }

          final createdAtComparison = b.createdAt.compareTo(a.createdAt);
          if (createdAtComparison != 0) {
            return createdAtComparison;
          }

          return byName(a, b);
        });
      case ItemsSortOption.oldest:
        sortedItems.sort((a, b) {
          final statusComparison = byStatus(a, b);
          if (statusComparison != 0) {
            return statusComparison;
          }

          final createdAtComparison = a.createdAt.compareTo(b.createdAt);
          if (createdAtComparison != 0) {
            return createdAtComparison;
          }

          return byName(a, b);
        });
    }

    return sortedItems;
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

    if (success) {
      HapticFeedback.selectionClick();
    }

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

    if (success) {
      HapticFeedback.selectionClick();
    }

    // Show error message if operation failed
    if (!success && mounted) {
      final state = ref.read(listDetailViewModelProvider(widget.listId));
      _showErrorSnackBar(state.error ?? 'Error updating item');
    }
  }

  // Delete item using ViewModel
  Future<void> _deleteItem(
    ShoppingItem item,
    ShoppingList currentList,
  ) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.deleteItem(item);

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _showSuccessSnackBar('${item.name} deleted');
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

  // Leave list with confirmation using ViewModel
  Future<void> _leaveList(ShoppingList currentList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => LeaveListConfirmationDialog(list: currentList),
    );

    if (confirmed == true && mounted) {
      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final success = await viewModel.leaveList();

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('You left "${currentList.name}"');
          context.go('/lists');
        } else {
          final state = ref.read(listDetailViewModelProvider(widget.listId));
          _showErrorSnackBar(state.error ?? 'Failed to leave list');
        }
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
            onRemoveMember: (member) => _removeMember(list, member),
            onInviteMore: () {
              Navigator.of(context).pop(); // Close member list dialog
              _showShareDialog(list); // Open share dialog
            },
          ),
    );
  }

  Future<bool> _removeMember(ShoppingList list, ListMember member) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final success = await viewModel.removeMember(member.userId);

    if (!mounted) {
      return success;
    }

    if (success) {
      _showSuccessSnackBar('Removed ${member.displayName} from "${list.name}"');
    } else {
      final state = ref.read(listDetailViewModelProvider(widget.listId));
      _showErrorSnackBar(state.error ?? 'Failed to remove member');
    }

    return success;
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.basketOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.clear_all,
                    color: AppColors.basketOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Clear completed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
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
                    color: AppColors.basketOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.basketOrange.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.basketOrange,
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
                  backgroundColor: AppColors.basketOrange,
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

    final authState = ref.watch(authViewModelProvider);
    final currentUserId = authState.user?.uid;
    final sortedItems = _sortItems(list);
    final pendingItems =
        sortedItems.where((item) => !item.isCompleted).toList();
    final completedItems =
        sortedItems.where((item) => item.isCompleted).toList();
    final canLeaveList =
        currentUserId != null &&
        list.ownerId != null &&
        list.ownerId != currentUserId &&
        list.members.any((member) => member.userId == currentUserId);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
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
        backgroundColor: AppColors.warmBackground,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Members button - only show if list has shared members
          if (list.sharedMemberCount > 0)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => _showMemberList(list),
              tooltip: 'View Members',
            ),
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
              _hasPermission('delete_list', list) ||
              canLeaveList)
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

                if (canLeaveList) {
                  menuItems.add(
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Leave List',
                            style: TextStyle(color: Colors.red),
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
                } else if (value == 'leave') {
                  _leaveList(list);
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
          if (list.items.isNotEmpty)
            ItemsHeaderWidget(
              itemsCount: pendingItems.length,
              selectedSort: _selectedItemsSort,
              onSortChanged: (sort) {
                setState(() {
                  _selectedItemsSort = sort;
                });
              },
            ),
          Expanded(
            child:
                list.items.isEmpty
                    ? const EmptyItemsStateWidget()
                    : SafeArea(
                      child: CustomScrollView(
                        slivers: [
                          // Pending items
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = pendingItems[index];
                                  final lastPending = index ==
                                      pendingItems.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          lastPending &&
                                                  completedItems.isEmpty
                                              ? 0
                                              : 10,
                                    ),
                                    child: ItemCardWidget(
                                      key: ValueKey(item.id),
                                      item: item,
                                      isProcessing:
                                          state.processingItems.contains(
                                            item.id,
                                          ),
                                      onToggleCompleted:
                                          _hasPermission('write', list)
                                              ? _toggleItemCompletion
                                              : null,
                                      onDelete:
                                          _hasPermission('delete', list)
                                              ? (item) =>
                                                  _deleteItem(
                                                    item,
                                                    list,
                                                  )
                                              : null,
                                      onEdit:
                                          _hasPermission('write', list)
                                              ? _editItem
                                              : null,
                                    ),
                                  );
                                },
                                childCount: pendingItems.length,
                              ),
                            ),
                          ),

                          // Completed items section
                          if (completedItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: CompletedItemsSection(
                                completedItems: completedItems,
                                processingItems: state.processingItems,
                                onToggleCompleted:
                                    _hasPermission('write', list)
                                        ? _toggleItemCompletion
                                        : null,
                                onDelete:
                                    _hasPermission('delete', list)
                                        ? (item) =>
                                            _deleteItem(item, list)
                                        : null,
                                onEdit:
                                    _hasPermission('write', list)
                                        ? _editItem
                                        : null,
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
