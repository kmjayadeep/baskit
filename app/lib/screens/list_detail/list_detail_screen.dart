import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_item_model.dart';
import '../../services/storage_service.dart';
import '../../services/firebase_auth_service.dart';
import 'widgets/list_header_widget.dart';
import 'widgets/add_item_widget.dart';
import 'widgets/empty_items_state_widget.dart';
import 'widgets/item_card_widget.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late Stream<ShoppingList?> _listStream;
  final _addItemController = TextEditingController();
  final _addQuantityController = TextEditingController();
  final _uuid = const Uuid();
  bool _isAddingItem = false;
  final Set<String> _processingItems = {}; // Track items being processed
  bool _isProcessingListAction = false; // Track list-level actions

  @override
  void initState() {
    super.initState();
    _initializeListStream();
  }

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    // Clean up the list stream when leaving the page
    StorageService.instance.disposeListStream(widget.listId);
    super.dispose();
  }

  // Initialize the list stream for real-time updates
  void _initializeListStream() {
    _listStream = StorageService.instance.watchList(widget.listId);
  }

  // Add new item with optimistic UI and debouncing
  Future<void> _addItem(ShoppingList currentList) async {
    // Prevent multiple simultaneous calls
    if (_isAddingItem) return;

    final itemName = _addItemController.text.trim();
    final quantity = _addQuantityController.text.trim();

    if (itemName.isEmpty) return;

    // Set loading state to prevent multiple calls
    setState(() {
      _isAddingItem = true;
    });

    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: itemName,
      quantity: quantity.isEmpty ? null : quantity,
      createdAt: DateTime.now(),
    );

    // Clear input fields immediately for instant feedback
    _addItemController.clear();
    _addQuantityController.clear();

    try {
      // Perform the actual backend operation
      final success = await StorageService.instance.addItem(
        widget.listId,
        newItem,
      );

      if (!success) {
        throw Exception('Failed to add item');
      }
    } catch (e) {
      // If the operation fails, show error and restore the input
      if (mounted) {
        // Restore the input values so user can retry
        _addItemController.text = itemName;
        _addQuantityController.text = quantity;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add item: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _addItem(currentList),
            ),
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isAddingItem = false;
        });
      }
    }
  }

  // Toggle item completion with debouncing
  Future<void> _toggleItemCompletion(ShoppingItem item) async {
    // Prevent multiple simultaneous calls for this item
    if (_processingItems.contains(item.id)) return;

    setState(() {
      _processingItems.add(item.id);
    });

    try {
      final success = await StorageService.instance.updateItem(
        widget.listId,
        item.id,
        completed: !item.isCompleted,
      );

      if (!success) {
        throw Exception('Failed to update item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingItems.remove(item.id);
        });
      }
    }
  }

  // Delete item with undo functionality and debouncing
  Future<void> _deleteItemWithUndo(
    ShoppingItem item,
    ShoppingList currentList,
  ) async {
    // Prevent multiple simultaneous calls for this item
    if (_processingItems.contains(item.id)) return;

    setState(() {
      _processingItems.add(item.id);
    });

    try {
      final success = await StorageService.instance.deleteItem(
        widget.listId,
        item.id,
      );

      if (!success) {
        throw Exception('Failed to delete item');
      }

      // Show snackbar with undo option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Re-add the item
                try {
                  await StorageService.instance.addItem(widget.listId, item);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error restoring item: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingItems.remove(item.id);
        });
      }
    }
  }

  // Edit item (both name and quantity) with debouncing
  Future<void> _editItem(ShoppingItem item) async {
    // Prevent multiple simultaneous calls for this item
    if (_processingItems.contains(item.id)) return;

    setState(() {
      _processingItems.add(item.id);
    });

    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an item name';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (optional)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop({
                      'name': nameController.text.trim(),
                      'quantity':
                          quantityController.text.trim().isEmpty
                              ? null
                              : quantityController.text.trim(),
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    try {
      if (result != null) {
        final newName = result['name'];
        final newQuantity = result['quantity'];

        final success = await StorageService.instance.updateItem(
          widget.listId,
          item.id,
          name: newName,
          quantity: newQuantity,
        );

        if (!success) {
          throw Exception('Failed to update item');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingItems.remove(item.id);
        });
      }
    }
  }

  // Delete list with confirmation
  Future<void> _deleteList(ShoppingList currentList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete "${currentList.name}"?'),
            content: const Text(
              'This action cannot be undone. All items in this list will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
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

  // Show share dialog with debouncing
  Future<void> _showShareDialog(ShoppingList currentList) async {
    // Prevent multiple simultaneous calls
    if (_isProcessingListAction) return;

    // Check if user is anonymous
    if (FirebaseAuthService.isAnonymous) {
      // Show sign-in prompt dialog
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.login, size: 24),
                  const SizedBox(width: 8),
                  const Text('Sign In Required'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You need to sign in to share lists with others.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_sync,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Benefits of signing in:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('• Share lists with friends and family'),
                        const Text('• Sync lists across all your devices'),
                        const Text('• Real-time collaboration'),
                        const Text('• Never lose your lists'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Maybe Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
      );

      // Navigate to profile page if user chose to sign in
      if (shouldNavigate == true && mounted) {
        context.push('/profile');
      }
      return;
    }

    // User is authenticated, show the regular share dialog
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.share, size: 24),
                      const SizedBox(width: 8),
                      Text('Share "${currentList.name}"'),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter the email address of the person you want to share this list with:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'user@example.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'The person will be able to view and edit this list.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() => isLoading = true);
                                  await _shareList(
                                    currentList,
                                    emailController.text.trim(),
                                  );
                                  setState(() => isLoading = false);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Share'),
                    ),
                  ],
                ),
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
    return StreamBuilder<ShoppingList?>(
      stream: _listStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
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
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final list = snapshot.data;
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('List Not Found')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
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
                isAddingItem: _isAddingItem,
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
                                isProcessing: _processingItems.contains(
                                  item.id,
                                ),
                                onToggleCompleted: _toggleItemCompletion,
                                onDelete:
                                    (item) => _deleteItemWithUndo(item, list),
                                onEdit: _editItem,
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
