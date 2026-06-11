import 'package:baskit/extensions/shopping_list_extensions.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ShoppingList createList(List<ShoppingItem> items) {
    return ShoppingList(
      id: 'test-list',
      name: 'Test',
      description: '',
      color: '#000000',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      items: items,
    );
  }

  ShoppingItem testItem(String name, {int hoursAgo = 0}) {
    return ShoppingItem(
      id: 'id-$name-$hoursAgo',
      name: name,
      createdAt: DateTime(2026).subtract(Duration(hours: hoursAgo)),
    );
  }

  group('frequentItemNames', () {
    test('returns top items by frequency, capped at 5', () {
      final list = createList([
        testItem('Milk', hoursAgo: 0),
        testItem('Milk', hoursAgo: 1),
        testItem('Milk', hoursAgo: 2),
        testItem('Eggs', hoursAgo: 0),
        testItem('Eggs', hoursAgo: 1),
        testItem('Bread', hoursAgo: 0),
        testItem('Butter', hoursAgo: 0),
        testItem('Cheese', hoursAgo: 0),
        testItem('Apples', hoursAgo: 0),
        testItem('Oranges', hoursAgo: 0),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Milk', 'Eggs', 'Bread', 'Butter', 'Cheese']);
      expect(result.length, 5);
    });

    test('counts both active and completed items', () {
      final list = createList([
        testItem('Milk', hoursAgo: 0),
        testItem('Milk', hoursAgo: 1).copyWith(isCompleted: true),
        testItem('Eggs', hoursAgo: 0),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Milk', 'Eggs']);
    });

    test('returns empty list when no items', () {
      final list = createList([]);
      expect(list.frequentItemNames, isEmpty);
    });

    test('returns single item for list with one item', () {
      final list = createList([testItem('Milk')]);
      expect(list.frequentItemNames, ['Milk']);
    });

    test('sorts by frequency descending', () {
      final list = createList([
        testItem('C', hoursAgo: 0),
        testItem('A', hoursAgo: 0),
        testItem('A', hoursAgo: 1),
        testItem('A', hoursAgo: 2),
        testItem('B', hoursAgo: 0),
        testItem('B', hoursAgo: 1),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['A', 'B', 'C']);
    });
  });
}
