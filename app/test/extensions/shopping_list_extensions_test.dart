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

  ShoppingItem testItem(String name, {int hoursAgo = 0, bool completed = false}) {
    return ShoppingItem(
      id: 'id-$name-$hoursAgo',
      name: name,
      createdAt: DateTime(2026).subtract(Duration(hours: hoursAgo)),
      isCompleted: completed,
    );
  }

  group('frequentItemNames', () {
    test('returns top completed items by frequency, capped at 5', () {
      final list = createList([
        testItem('Milk', hoursAgo: 0, completed: true),
        testItem('Milk', hoursAgo: 1, completed: true),
        testItem('Milk', hoursAgo: 2, completed: true),
        testItem('Eggs', hoursAgo: 0, completed: true),
        testItem('Eggs', hoursAgo: 1, completed: true),
        testItem('Bread', hoursAgo: 0, completed: true),
        testItem('Butter', hoursAgo: 0, completed: true),
        testItem('Cheese', hoursAgo: 0, completed: true),
        testItem('Apples', hoursAgo: 0, completed: true),
        testItem('Oranges', hoursAgo: 0, completed: true),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Milk', 'Eggs', 'Bread', 'Butter', 'Cheese']);
      expect(result.length, 5);
    });

    test('excludes items already in the active list', () {
      final list = createList([
        testItem('Milk', hoursAgo: 0), // active — excluded
        testItem('Milk', hoursAgo: 1, completed: true),
        testItem('Milk', hoursAgo: 2, completed: true),
        testItem('Eggs', hoursAgo: 0, completed: true),
        testItem('Eggs', hoursAgo: 1, completed: true),
        testItem('Bread', hoursAgo: 0, completed: true),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Eggs', 'Bread']);
      expect(result, isNot(contains('Milk')));
    });

    test('returns empty list when no items', () {
      final list = createList([]);
      expect(list.frequentItemNames, isEmpty);
    });

    test('returns empty when all items are active', () {
      final list = createList([
        testItem('Milk'),
        testItem('Eggs'),
      ]);
      expect(list.frequentItemNames, isEmpty);
    });

    test('returns single completed item for list with one completed item', () {
      final list = createList([testItem('Milk', completed: true)]);
      expect(list.frequentItemNames, ['Milk']);
    });

    test('sorts by frequency descending', () {
      final list = createList([
        testItem('C', completed: true),
        testItem('A', completed: true),
        testItem('A', hoursAgo: 1, completed: true),
        testItem('A', hoursAgo: 2, completed: true),
        testItem('B', completed: true),
        testItem('B', hoursAgo: 1, completed: true),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['A', 'B', 'C']);
    });
  });
}
