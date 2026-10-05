import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/utils/item_sorter.dart';
import 'package:baskit/screens/list_detail/widgets/items_header_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemSorter', () {
    test('sorts by name case-insensitively', () {
      final items = [
        _item(id: 'milk', name: 'Milk'),
        _item(id: 'apples', name: 'apples'),
        _item(id: 'bananas', name: 'Bananas'),
      ];

      final sorted = ItemSorter.sort(items, ItemsSortOption.name);

      expect(sorted.map((item) => item.id), ['apples', 'bananas', 'milk']);
    });

    test('sorts newest first and breaks created-at ties by name', () {
      final tiedCreatedAt = DateTime(2025, 1, 2);
      final items = [
        _item(id: 'tie-bananas', name: 'bananas', createdAt: tiedCreatedAt),
        _item(
          id: 'newest-carrots',
          name: 'carrots',
          createdAt: tiedCreatedAt.add(const Duration(days: 1)),
        ),
        _item(id: 'tie-apples', name: 'Apples', createdAt: tiedCreatedAt),
        _item(
          id: 'oldest-dates',
          name: 'dates',
          createdAt: tiedCreatedAt.subtract(const Duration(days: 1)),
        ),
      ];

      final sorted = ItemSorter.sort(items, ItemsSortOption.newest);

      expect(sorted.map((item) => item.id), [
        'newest-carrots',
        'tie-apples',
        'tie-bananas',
        'oldest-dates',
      ]);
    });

    test('sorts oldest first and breaks created-at ties by name', () {
      final tiedCreatedAt = DateTime(2025, 1, 2);
      final items = [
        _item(
          id: 'newest-carrots',
          name: 'carrots',
          createdAt: tiedCreatedAt.add(const Duration(days: 1)),
        ),
        _item(id: 'tie-bananas', name: 'bananas', createdAt: tiedCreatedAt),
        _item(
          id: 'oldest-dates',
          name: 'dates',
          createdAt: tiedCreatedAt.subtract(const Duration(days: 1)),
        ),
        _item(id: 'tie-apples', name: 'Apples', createdAt: tiedCreatedAt),
      ];

      final sorted = ItemSorter.sort(items, ItemsSortOption.oldest);

      expect(sorted.map((item) => item.id), [
        'oldest-dates',
        'tie-apples',
        'tie-bananas',
        'newest-carrots',
      ]);
    });

    test('does not mutate the input list', () {
      final items = [
        _item(id: 'milk', name: 'Milk'),
        _item(id: 'apples', name: 'apples'),
        _item(id: 'bananas', name: 'Bananas'),
      ];
      final originalOrder = List<ShoppingItem>.of(items);

      final sorted = ItemSorter.sort(items, ItemsSortOption.name);

      expect(sorted, isNot(same(items)));
      expect(items, originalOrder);
      expect(items.map((item) => item.id), ['milk', 'apples', 'bananas']);
    });
  });
}

ShoppingItem _item({
  required String id,
  required String name,
  DateTime? createdAt,
}) {
  return ShoppingItem(
    id: id,
    name: name,
    createdAt: createdAt ?? DateTime(2025),
  );
}
