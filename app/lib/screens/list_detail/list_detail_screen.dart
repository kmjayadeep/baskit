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
  ShoppingList? _list;
  bool _isLoading = true;
  final _addItemController = TextEditingController();
  final _addQuantityController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _addItemController.dispose();
    _addQuantityController.dispose();
    super.dispose();
  }

  // Load list from storage
  Future<void> _loadList() async {
    try {
      final list = await StorageService.instance.getListById(widget.listId);
      if (mounted) {
        setState(() {
          _list = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Convert hex string to Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  // Add new item
  Future<void> _addItem() async {
    final itemName = _addItemController.text.trim();
    final quantity = _addQuantityController.text.trim();

    if (itemName.isEmpty || _list == null) return;

    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: itemName,
      quantity: quantity.isEmpty ? null : quantity,
      createdAt: DateTime.now(),
    );

    final updatedItems = [..._list!.items, newItem];
    final updatedList = _list!.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    try {
      await StorageService.instance.saveList(updatedList);
      setState(() {
        _list = updatedList;
      });
      _addItemController.clear();
      _addQuantityController.clear();
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
    if (_list == null) return;

    final updatedItem = item.copyWith(
      isCompleted: !item.isCompleted,
      completedAt: !item.isCompleted ? DateTime.now() : null,
    );

    final updatedItems =
        _list!.items.map((i) => i.id == item.id ? updatedItem : i).toList();
    final updatedList = _list!.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    try {
      await StorageService.instance.saveList(updatedList);
      setState(() {
        _list = updatedList;
      });
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
  Future<void> _deleteItemWithUndo(ShoppingItem item) async {
    if (_list == null) return;

    // Store the original state for undo
    final originalItems = List<ShoppingItem>.from(_list!.items);
    final itemIndex = _list!.items.indexWhere((i) => i.id == item.id);

    // Remove the item immediately
    final updatedItems = _list!.items.where((i) => i.id != item.id).toList();
    final updatedList = _list!.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    try {
      await StorageService.instance.saveList(updatedList);
      setState(() {
        _list = updatedList;
      });

      // Show snackbar with undo option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Restore the item
              final restoredList = _list!.copyWith(
                items: originalItems,
                updatedAt: DateTime.now(),
              );

              try {
                await StorageService.instance.saveList(restoredList);
                setState(() {
                  _list = restoredList;
                });
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

  // Edit item dialog
  Future<void> _showEditItemDialog(ShoppingItem item) async {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (optional)',
                    border: OutlineInputBorder(),
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
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true && _list != null) {
      final updatedItem = item.copyWith(
        name: nameController.text.trim(),
        quantity:
            quantityController.text.trim().isEmpty
                ? null
                : quantityController.text.trim(),
      );

      final updatedItems =
          _list!.items.map((i) => i.id == item.id ? updatedItem : i).toList();
      final updatedList = _list!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      try {
        await StorageService.instance.saveList(updatedList);
        setState(() {
          _list = updatedList;
        });
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

    nameController.dispose();
    quantityController.dispose();
  }

  // Handle menu actions
  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit list screen
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete List'),
                content: Text(
                  'Are you sure you want to delete "${_list?.name}"? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        );

        if (confirmed == true && _list != null) {
          try {
            await StorageService.instance.deleteList(_list!.id);
            if (mounted) {
              context.go('/lists');
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
        break;
      case 'members':
        // TODO: Navigate to manage members screen (future feature)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member management coming soon!')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_list == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/lists'),
          ),
        ),
        body: const Center(child: Text('List not found')),
      );
    }

    final listColor = _hexToColor(_list!.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_list!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lists'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Add share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit List'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'members',
                    child: ListTile(
                      leading: Icon(Icons.people),
                      title: Text('Manage Members'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete List',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
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
              color: listColor.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                        _list!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_list!.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _list!.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${_list!.completedItemsCount} of ${_list!.totalItemsCount} items completed',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _list!.completionProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(listColor),
                ),
              ],
            ),
          ),

          // Add item section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _addItemController,
                    decoration: const InputDecoration(
                      hintText: 'Add new item...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _addQuantityController,
                    decoration: const InputDecoration(
                      hintText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addItem, child: const Text('Add')),
              ],
            ),
          ),

          // Items list
          Expanded(
            child:
                _list!.items.isEmpty
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first item above',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _list!.items.length,
                      itemBuilder: (context, index) {
                        final item = _list!.items[index];
                        return _buildItemTile(item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(ShoppingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => _toggleItemCompletion(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle:
            item.quantity != null
                ? Text(
                  item.quantity!,
                  style: TextStyle(
                    color: item.isCompleted ? Colors.grey : Colors.grey[600],
                  ),
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditItemDialog(item),
              tooltip: 'Edit item',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteItemWithUndo(item),
              tooltip: 'Delete item',
            ),
          ],
        ),
      ),
    );
  }
}
