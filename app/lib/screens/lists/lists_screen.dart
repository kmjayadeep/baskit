import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Baskit! 🛒',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and share shopping lists with friends and family',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lists section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Lists',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.go('/create-list');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New List'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lists grid/list
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: 6, // Mock data
                itemBuilder: (context, index) {
                  return _buildListCard(context, index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/create-list');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, int index) {
    final mockLists = [
      {'name': 'Groceries', 'items': 12, 'color': Colors.green},
      {'name': 'Hardware Store', 'items': 5, 'color': Colors.orange},
      {'name': 'Party Supplies', 'items': 8, 'color': Colors.purple},
      {'name': 'Weekly Shopping', 'items': 15, 'color': Colors.blue},
      {'name': 'Pharmacy', 'items': 3, 'color': Colors.red},
      {'name': 'Office Supplies', 'items': 7, 'color': Colors.teal},
    ];

    final list = mockLists[index % mockLists.length];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.go('/list/${index + 1}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: list['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      list['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${list['items']} items',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.6, // Mock progress
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  list['color'] as Color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
