import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/shopping_list_model.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_wrapper.dart';
import '../../widgets/auth/profile_picture_widget.dart';
import 'widgets/welcome_banner_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/lists_header_widget.dart';
import 'widgets/list_card_widget.dart';

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
                                          child: ListCardWidget(
                                            list: lists[index],
                                            onTap:
                                                () => context.push(
                                                  '/list/${lists[index].id}',
                                                ),
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
}
