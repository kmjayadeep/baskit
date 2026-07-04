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
import '../../utils/snackbar_extensions.dart';
import 'utils/item_sorter.dart';
import 'widgets/list_detail_app_bar.dart';
import 'widgets/list_header_widget.dart';
import 'widgets/add_item_widget.dart';
import 'widgets/quick_add_chips_widget.dart';
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
import 'widgets/dialogs/clear_completed_confirmation_dialog.dart';
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
  ItemsSortOption _selectedItemsSort = ItemsSortOption.newest;
  bool _showQuickAddChips = true;

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    super.dispose();
  }

  /// Check if current user has permission for an action.
  bool _hasPermission(ListPermission permission, ShoppingList list) {
    final currentUserId = ref.read(authUserProvider)?.uid;
    return PermissionService.hasListPermission(list, currentUserId, permission);
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
    final result = await viewModel.addItem(
      itemName,
      quantity.isEmpty ? null : quantity,
    );

    if (result.isSuccess) {
      HapticFeedback.selectionClick();
    }

    // Handle failure - restore input and show retry option
    if (!result.isSuccess && mounted) {
      // Restore the input values so user can retry
      _addItemController.text = itemName;
      _addQuantityController.text = quantity;

      context.showErrorWithRetrySnackBar(
        result.errorMessage ?? 'Failed to add item',
        () => _addItem(currentList),
      );
    }
  }

  // Toggle item completion using ViewModel
  Future<void> _toggleItemCompletion(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.toggleItemCompletion(item);

    if (result.isSuccess) {
      HapticFeedback.selectionClick();
    }

    // Show error message if operation failed
    if (!result.isSuccess && mounted) {
      context.showErrorSnackBar(result.errorMessage ?? 'Error updating item');
    }
  }

  // Delete item using ViewModel
  Future<void> _deleteItem(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.deleteItem(item);

    if (result.isSuccess && mounted) {
      HapticFeedback.mediumImpact();
      context.showSuccessSnackBar('${item.name} deleted');
    } else if (!result.isSuccess && mounted) {
      context.showErrorSnackBar(result.errorMessage ?? 'Error deleting item');
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
      final actionResult = await viewModel.editItem(item, newName, newQuantity);

      // Show error message if operation failed
      if (!actionResult.isSuccess && mounted) {
        context.showErrorSnackBar(
          actionResult.errorMessage ?? 'Error updating item',
        );
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
      final result = await viewModel.deleteList();

      if (result.isSuccess && mounted) {
        context.go('/lists');
      } else if (!result.isSuccess && mounted) {
        context.showErrorSnackBar(result.errorMessage ?? 'Error deleting list');
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
      final result = await viewModel.leaveList();

      if (mounted) {
        if (result.isSuccess) {
          context.showSuccessSnackBar('You left "${currentList.name}"');
          context.go('/lists');
        } else {
          context.showErrorSnackBar(
            result.errorMessage ?? 'Failed to leave list',
          );
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
          (context) =>
              EnhancedShareListDialog(list: currentList, onShare: _shareList),
    );
  }

  // Share list with user by email using ViewModel
  Future<void> _shareList(String email) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.shareList(email);

    if (mounted) {
      if (result.isSuccess) {
        context.showSuccessSnackBar('List shared with $email successfully!');
      } else {
        context.showErrorSnackBar(
          result.errorMessage ?? 'Failed to share list',
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
    final result = await viewModel.removeMember(member.userId);

    if (!mounted) {
      return result.isSuccess;
    }

    if (result.isSuccess) {
      context.showSuccessSnackBar(
        'Removed ${member.displayName} from "${list.name}"',
      );
    } else {
      context.showErrorSnackBar(
        result.errorMessage ?? 'Failed to remove member',
      );
    }

    return result.isSuccess;
  }

  // Clear completed items with confirmation using ViewModel
  Future<void> _clearCompletedItems(ShoppingList list) async {
    final completedCount = list.completedItemsCount;

    if (completedCount == 0) {
      context.showInfoSnackBar('No completed items to clear');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => ClearCompletedConfirmationDialog(list: list),
    );

    if (shouldClear == true && mounted) {
      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final result = await viewModel.clearCompletedItems();

      if (mounted) {
        if (result.isSuccess) {
          context.showSuccessSnackBar(
            'Cleared $completedCount completed ${completedCount == 1 ? 'item' : 'items'}',
          );
        } else {
          context.showErrorSnackBar(
            result.errorMessage ?? 'Failed to clear completed items',
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

    if (state.hasLoadError) {
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
    final sortedItems = ItemSorter.sort(list.items, _selectedItemsSort);
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
      appBar: ListDetailAppBar(
        list: list,
        canShare: _hasPermission(ListPermission.share, list),
        canEditMetadata: _hasPermission(ListPermission.editMetadata, list),
        canDeleteItems: _hasPermission(ListPermission.deleteItems, list),
        canDeleteList: _hasPermission(ListPermission.deleteList, list),
        canLeaveList: canLeaveList,
        onShowMembers: () => _showMemberList(list),
        onShare: () => _showShareDialog(list),
        onEdit: () => _editList(list),
        onDelete: () => _deleteList(list),
        onClearCompleted: () => _clearCompletedItems(list),
        onLeave: () => _leaveList(list),
      ),
      body: Column(
        children: [
          // List info header
          ListHeaderWidget(list: list),

          // Add item section - only show if user can write
          if (_hasPermission(ListPermission.write, list))
            AddItemWidget(
              list: list,
              itemController: _addItemController,
              quantityController: _addQuantityController,
              isAddingItem: state.isAddingItem,
              onAddItem: () => _addItem(list),
            ),

          // Quick-add chips for frequently used items
          if (_hasPermission(ListPermission.write, list) &&
              list.frequentItemNames.isNotEmpty &&
              _showQuickAddChips)
            QuickAddChips(
              itemNames: list.frequentItemNames,
              enabled: !state.isAddingItem,
              onItemTap: (name) {
                _addItemController.text = name;
                _addItem(list);
              },
              onDismiss: () => setState(() => _showQuickAddChips = false),
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
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final item = pendingItems[index];
                                return ItemCardWidget(
                                  key: ValueKey(item.id),
                                  item: item,
                                  isProcessing: state.processingItems.contains(
                                    item.id,
                                  ),
                                  onToggleCompleted:
                                      _hasPermission(ListPermission.write, list)
                                          ? _toggleItemCompletion
                                          : null,
                                  onDelete:
                                      _hasPermission(
                                            ListPermission.deleteItems,
                                            list,
                                          )
                                          ? _deleteItem
                                          : null,
                                  onEdit:
                                      _hasPermission(ListPermission.write, list)
                                          ? _editItem
                                          : null,
                                );
                              }, childCount: pendingItems.length),
                            ),
                          ),

                          // Completed items section
                          if (completedItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: CompletedItemsSection(
                                completedItems: completedItems,
                                processingItems: state.processingItems,
                                onToggleCompleted:
                                    _hasPermission(ListPermission.write, list)
                                        ? _toggleItemCompletion
                                        : null,
                                onDelete:
                                    _hasPermission(
                                          ListPermission.deleteItems,
                                          list,
                                        )
                                        ? _deleteItem
                                        : null,
                                onEdit:
                                    _hasPermission(ListPermission.write, list)
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
