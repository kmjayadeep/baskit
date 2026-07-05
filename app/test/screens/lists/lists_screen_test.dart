import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/lists/lists_screen.dart';
import 'package:baskit/screens/lists/view_models/lists_view_model.dart';
import 'package:baskit/screens/lists/widgets/lists_header_widget.dart';
import 'package:baskit/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState.initial();
}

class FakeListsViewModel extends ListsViewModel {
  FakeListsViewModel(this.initialState);

  final ListsState initialState;

  @override
  ListsState build() => initialState;

  @override
  Future<void> refreshLists() async {}
}

void main() {
  Widget buildSubject(ListsState listsState) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(FakeAuthViewModel.new),
        listsViewModelProvider.overrideWith(
          () => FakeListsViewModel(listsState),
        ),
      ],
      child: const MaterialApp(home: ListsScreen()),
    );
  }

  testWidgets('hides list header and sort controls when there are no lists', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(const ListsState.data([])));
    await tester.pumpAndSettle();

    expect(find.text('No lists yet'), findsOneWidget);
    expect(find.text('Create List'), findsOneWidget);
    expect(find.text('Your Lists (0)'), findsNothing);
    expect(find.byType(ListsHeaderWidget), findsNothing);
    expect(find.byType(PopupMenuButton<ListsSortOption>), findsNothing);
  });

  testWidgets('keeps header and sort controls for non-empty lists', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1);
    final list = ShoppingList(
      id: 'list-1',
      name: 'Groceries',
      description: '',
      color: '#4CAF50',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(buildSubject(ListsState.data([list])));
    await tester.pumpAndSettle();

    expect(find.text('Your Lists (1)'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(ListsHeaderWidget), findsOneWidget);
  });
}
