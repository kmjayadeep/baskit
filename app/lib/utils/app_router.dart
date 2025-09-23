import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/lists/lists_screen.dart';
import '../screens/lists/list_form_screen.dart';
import '../screens/list_detail/list_detail_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/lists',
    routes: [
      // Main App Routes
      GoRoute(
        path: '/lists',
        name: 'lists',
        builder: (context, state) => const ListsScreen(),
      ),
      GoRoute(
        path: '/create-list',
        name: 'create-list',
        builder: (context, state) => const ListFormScreen(),
      ),
      GoRoute(
        path: '/list/:id',
        name: 'list-detail',
        builder: (context, state) {
          final listId = state.pathParameters['id']!;
          return ListDetailScreen(listId: listId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // Error handling
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'The page you are looking for does not exist.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/lists'),
                  child: const Text('Go to Lists'),
                ),
              ],
            ),
          ),
        ),
  );
}
