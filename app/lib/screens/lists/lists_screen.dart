import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/auth_wrapper.dart';
import '../../widgets/auth/profile_picture_widget.dart';
import '../../widgets/whats_new_dialog.dart';
import '../../view_models/auth_view_model.dart';
import 'widgets/welcome_banner_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/lists_header_widget.dart';
import 'widgets/list_card_widget.dart';
import 'view_models/lists_view_model.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  @override
  void initState() {
    super.initState();
    // Check and show What's New dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWhatsNew();
    });
  }

  Future<void> _checkAndShowWhatsNew() async {
    // Skip in test environment to avoid issues
    if (kDebugMode &&
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }

    // Add a small delay to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      await WhatsNewService.checkAndShow(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsState = ref.watch(listsViewModelProvider);
    final viewModel = ref.read(listsViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          actions: [
            AuthStatusIndicator(),
            const SizedBox(width: 8),
            ProfilePictureWidget(
              photoURL: authState.photoURL,
              size: 36,
              onTap: () {
                context.push('/profile');
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => viewModel.refreshLists(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Welcome message
                const WelcomeBannerWidget(),
                const SizedBox(height: 24),

                // Lists content with real-time updates
                Expanded(
                  child: _buildListsContent(context, listsState, viewModel),
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

  Widget _buildListsContent(
    BuildContext context,
    ListsState state,
    ListsViewModel viewModel,
  ) {
    // Handle loading state
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Error loading lists'),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refreshLists(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final lists = state.lists;

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
                    onCreateList: () => context.push('/create-list'),
                  )
                  : ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ListCardWidget(
                          list: lists[index],
                          onTap: () => context.push('/list/${lists[index].id}'),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
