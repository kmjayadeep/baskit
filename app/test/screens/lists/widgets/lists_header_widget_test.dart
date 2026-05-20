import 'package:baskit/screens/lists/widgets/lists_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows sort menu instead of new list button', (tester) async {
    ListsSortOption? selectedSort;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListsHeaderWidget(
            listsCount: 3,
            selectedSort: ListsSortOption.recent,
            onSortChanged: (sort) => selectedSort = sort,
          ),
        ),
      ),
    );

    expect(find.text('Your Lists (3)'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('New List'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<ListsSortOption>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();

    expect(selectedSort, ListsSortOption.name);
  });
}
