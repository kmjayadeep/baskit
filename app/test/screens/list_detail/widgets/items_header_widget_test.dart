import 'package:baskit/screens/list_detail/widgets/items_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows item sort menu and reports selection', (tester) async {
    ItemsSortOption? selectedSort;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemsHeaderWidget(
            itemsCount: 4,
            selectedSort: ItemsSortOption.newest,
            onSortChanged: (sort) => selectedSort = sort,
          ),
        ),
      ),
    );

    expect(find.text('Items (4)'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<ItemsSortOption>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();

    expect(selectedSort, ItemsSortOption.name);
  });
}
