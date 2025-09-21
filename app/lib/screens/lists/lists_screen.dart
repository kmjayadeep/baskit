import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/auth_wrapper.dart';
import '../../widgets/auth/profile_picture_widget.dart';
import 'widgets/welcome_banner_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/lists_header_widget.dart';
import 'widgets/list_card_widget.dart';
import 'view_models/lists_view_model.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsState = ref.watch(listsViewModelProvider);
    final viewModel = ref.read(listsViewModelProvider.notifier);

    return AuthWrapper(
      onAuthStateChanged: () => viewModel.onAuthStateChanged(),
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
