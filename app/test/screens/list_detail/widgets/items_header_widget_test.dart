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

    expect(find.text('4 items left'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<ItemsSortOption>));
    await tester.pumpAndSettle();

    final menuItems =
        tester
            .widgetList<CheckedPopupMenuItem<ItemsSortOption>>(
              find.byType(CheckedPopupMenuItem<ItemsSortOption>),
            )
            .toList();

    expect(menuItems, hasLength(ItemsSortOption.values.length));
    expect(
      menuItems
          .singleWhere((item) => item.value == ItemsSortOption.newest)
          .checked,
      isTrue,
    );
    expect(menuItems.where((item) => item.checked), hasLength(1));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ItemsSortOption> &&
            widget.value == ItemsSortOption.name,
      ),
    );
    await tester.pumpAndSettle();

    expect(selectedSort, ItemsSortOption.name);
  });
}
