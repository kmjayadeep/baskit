import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_wrapper.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late Stream<List<ShoppingList>> _listsStream;

  @override
  void initState() {
    super.initState();
    _initializeListsStream();
  }

  // Initialize the lists stream for real-time updates
  void _initializeListsStream() {
    _listsStream = StorageService.instance.getListsStream();
  }

  // Refresh lists (pull to refresh)
  Future<void> _refreshLists() async {
    // Force sync with Firebase if available
    await StorageService.instance.forcSync();

    // Refresh the stream
    setState(() {
      _initializeListsStream();
    });
  }

  // Convert hex string back to Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          AuthStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLists,
        child: Padding(
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

              // Lists content with real-time updates
              Expanded(
                child: StreamBuilder<List<ShoppingList>>(
                  stream: _listsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text('Error loading lists'),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshLists,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final lists = snapshot.data ?? [];

                    return Column(
                      children: [
                        // Lists section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Lists (${lists.length})',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
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

                        // Lists content
                        Expanded(
                          child:
                              lists.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    itemCount: lists.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildListCard(
                                          context,
                                          lists[index],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/create-list');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, ShoppingList list) {
    final color = _hexToColor(list.color);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.go('/list/${list.id}');
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
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${list.items.length} items',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (list.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  list.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: list.completionProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${list.completedItemsCount}/${list.totalItemsCount} done',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getSharingIcon(list),
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _buildSharingText(list),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSharingText(ShoppingList list) {
    // Note: Now list.members contains display names, not IDs
    // We don't need to filter since the current user's name is not included in members anymore
    final otherMembers = list.members;

    if (otherMembers.isEmpty) {
      return 'Private';
    } else if (otherMembers.length == 1) {
      return 'Shared with ${otherMembers[0]}';
    } else if (otherMembers.length == 2) {
      return 'Shared with ${otherMembers[0]} and ${otherMembers[1]}';
    } else {
      return 'Shared with ${otherMembers.length} people';
    }
  }

  IconData _getSharingIcon(ShoppingList list) {
    // Use the member names list directly since it excludes current user
    final otherMembers = list.members;

    if (otherMembers.isEmpty) {
      return Icons.lock;
    } else if (otherMembers.length == 1) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }
}
