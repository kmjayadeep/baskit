import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list.dart';
import '../../models/shopping_item.dart';
import '../../services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeListStream();
  }

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    super.dispose();
  }

  // Initialize the list stream for real-time updates
  void _initializeListStream() {
    _listStream = StorageService.instance.getListByIdStream(widget.listId);
  }

  // Convert hex string to Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  // Add new item
  Future<void> _addItem(ShoppingList currentList) async {
    final itemName = _addItemController.text.trim();
    final quantity = _addQuantityController.text.trim();

    if (itemName.isEmpty) return;

    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: itemName,
      quantity: quantity.isEmpty ? null : quantity,
      createdAt: DateTime.now(),
    );

    try {
      final success = await StorageService.instance.addItemToList(
        widget.listId,
        newItem,
      );

      if (success) {
        _addItemController.clear();
        _addQuantityController.clear();
      } else {
        throw Exception('Failed to add item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Toggle item completion
  Future<void> _toggleItemCompletion(ShoppingItem item) async {
    try {
      final success = await StorageService.instance.updateItemInList(
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
    }
  }

  // Delete item with undo functionality
  Future<void> _deleteItemWithUndo(
    ShoppingItem item,
    ShoppingList currentList,
  ) async {
    try {
      final success = await StorageService.instance.deleteItemFromList(
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
                  await StorageService.instance.addItemToList(
                    widget.listId,
                    item,
                  );
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
    }
  }

  // Edit item name
  Future<void> _editItemName(ShoppingItem item) async {
    final controller = TextEditingController(text: item.name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != item.name) {
      try {
        final success = await StorageService.instance.updateItemInList(
          widget.listId,
          item.id,
          name: newName,
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
      }
    }
  }

  // Edit item quantity
  Future<void> _editItemQuantity(ShoppingItem item) async {
    final controller = TextEditingController(text: item.quantity ?? '');
    final newQuantity = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Quantity'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (newQuantity != null && newQuantity != item.quantity) {
      try {
        final success = await StorageService.instance.updateItemInList(
          widget.listId,
          item.id,
          quantity: newQuantity.isEmpty ? null : newQuantity,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShoppingList?>(
      stream: _listStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error loading list'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeListStream();
                      });
                    },
                    child: const Text('Retry'),
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
            body: const Center(child: Text('This list could not be found.')),
          );
        }

        final listColor = _hexToColor(list.color);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/lists');
              },
            ),
            title: Text(list.name),
            backgroundColor: listColor.withValues(alpha: 0.1),
            actions: [
              PopupMenuButton(
                itemBuilder:
                    (context) => [
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
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // List info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: listColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: listColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            list.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (list.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        list.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${list.completedItemsCount} of ${list.totalItemsCount} items completed',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: list.completionProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(listColor),
                    ),
                  ],
                ),
              ),

              // Add item section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _addItemController,
                      decoration: const InputDecoration(
                        hintText: 'Add new item...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.add),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addItem(list),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addQuantityController,
                            decoration: const InputDecoration(
                              hintText: 'Quantity (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.format_list_numbered),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addItem(list),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _addItem(list),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: listColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child:
                    list.items.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items yet',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first item to get started',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.items.length,
                          itemBuilder: (context, index) {
                            final item = list.items[index];
                            return _buildItemCard(item, list);
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(ShoppingItem item, ShoppingList list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => _toggleItemCompletion(item),
          activeColor: _hexToColor(list.color),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey[600] : null,
          ),
        ),
        subtitle:
            item.quantity != null
                ? Text(
                  'Quantity: ${item.quantity}',
                  style: TextStyle(
                    color:
                        item.isCompleted ? Colors.grey[500] : Colors.grey[600],
                  ),
                )
                : null,
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit_name',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_quantity',
                  child: Row(
                    children: [
                      Icon(Icons.format_list_numbered),
                      SizedBox(width: 8),
                      Text('Edit Quantity'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            switch (value) {
              case 'edit_name':
                _editItemName(item);
                break;
              case 'edit_quantity':
                _editItemQuantity(item);
                break;
              case 'delete':
                _deleteItemWithUndo(item, list);
                break;
            }
          },
        ),
      ),
    );
  }
}
