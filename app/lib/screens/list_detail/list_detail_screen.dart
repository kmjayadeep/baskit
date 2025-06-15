import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListDetailScreen extends StatelessWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Add share functionality
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
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
              color: Colors.green.shade50,
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
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Groceries',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '7 of 12 items completed',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 7 / 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 12),
                // Active users
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '3 active users',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
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
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add new item...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Add item logic
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 12, // Mock data
              itemBuilder: (context, index) {
                return _buildItemTile(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, int index) {
    final mockItems = [
      {'name': 'Milk', 'quantity': '2 liters', 'completed': true},
      {'name': 'Bread', 'quantity': '1 loaf', 'completed': true},
      {'name': 'Eggs', 'quantity': '12 pieces', 'completed': false},
      {'name': 'Apples', 'quantity': '1 kg', 'completed': true},
      {'name': 'Chicken', 'quantity': '500g', 'completed': false},
      {'name': 'Rice', 'quantity': '2 kg', 'completed': true},
      {'name': 'Tomatoes', 'quantity': '500g', 'completed': false},
      {'name': 'Onions', 'quantity': '1 kg', 'completed': true},
      {'name': 'Cheese', 'quantity': '200g', 'completed': false},
      {'name': 'Yogurt', 'quantity': '4 cups', 'completed': true},
      {'name': 'Bananas', 'quantity': '6 pieces', 'completed': false},
      {'name': 'Pasta', 'quantity': '500g', 'completed': true},
    ];

    final item = mockItems[index % mockItems.length];
    final isCompleted = item['completed'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            // TODO: Toggle item completion
          },
        ),
        title: Text(
          item['name'] as String,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          item['quantity'] as String,
          style: TextStyle(color: isCompleted ? Colors.grey : Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            // TODO: Handle item actions
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
