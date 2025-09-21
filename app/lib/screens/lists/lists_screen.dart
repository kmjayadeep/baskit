import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list_model.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_wrapper.dart';
import '../../widgets/auth/profile_picture_widget.dart';
import 'widgets/welcome_banner_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/lists_header_widget.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late Stream<List<ShoppingList>> _listsStream;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeListsStream();
  }

  // Initialize the lists stream for real-time updates
  void _initializeListsStream() {
    _listsStream = StorageService.instance.watchLists();
  }

  // Handle authentication state changes
  void _onAuthStateChanged() {
    // Reinitialize the stream when auth state changes
    if (mounted) {
      setState(() {
        _initializeListsStream();
      });
    }
  }

  // Refresh lists (pull to refresh) with debouncing
  Future<void> _refreshLists() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Force sync with Firebase if available
      await StorageService.instance.sync();

      // Refresh the stream
      if (mounted) {
        setState(() {
          _initializeListsStream();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      onAuthStateChanged: _onAuthStateChanged,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          actions: [
            AuthStatusIndicator(),
            const SizedBox(width: 8),
            ProfilePictureWidget(
              size: 36,
              onTap: () {
                context.push('/profile');
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshLists,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Welcome message
                const WelcomeBannerWidget(),
                const SizedBox(height: 24),

                // Lists content with real-time updates
                Expanded(
                  child: StreamBuilder<List<ShoppingList>>(
                    stream: _listsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
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
                          ListsHeaderWidget(
                            listsCount: lists.length,
                            onCreateList: () => context.push('/create-list'),
                          ),
                          const SizedBox(height: 16),

                          // Lists content
                          Expanded(
                            child:
                                lists.isEmpty
                                    ? EmptyStateWidget(
                                      onCreateList:
                                          () => context.push('/create-list'),
                                    )
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
            context.push('/create-list');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, ShoppingList list) {
    final color = list.displayColor;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/list/${list.id}');
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
                  Icon(list.sharingIcon, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      list.sharingText,
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
}
