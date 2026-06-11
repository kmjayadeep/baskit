import 'package:baskit/extensions/shopping_list_extensions.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ShoppingList _createList(List<ShoppingItem> items) {
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

  ShoppingItem _item(String name, {int hoursAgo = 0}) {
    return ShoppingItem(
      id: 'id-$name-${hoursAgo}',
      name: name,
      createdAt: DateTime(2026).subtract(Duration(hours: hoursAgo)),
    );
  }

  group('frequentItemNames', () {
    test('returns top items by frequency, capped at 5', () {
      final list = _createList([
        _item('Milk', hoursAgo: 0),
        _item('Milk', hoursAgo: 1),
        _item('Milk', hoursAgo: 2),
        _item('Eggs', hoursAgo: 0),
        _item('Eggs', hoursAgo: 1),
        _item('Bread', hoursAgo: 0),
        _item('Butter', hoursAgo: 0),
        _item('Cheese', hoursAgo: 0),
        _item('Apples', hoursAgo: 0),
        _item('Oranges', hoursAgo: 0),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Milk', 'Eggs', 'Bread', 'Butter', 'Cheese']);
      expect(result.length, 5);
    });

    test('counts both active and completed items', () {
      final list = _createList([
        _item('Milk', hoursAgo: 0),
        _item('Milk', hoursAgo: 1).copyWith(isCompleted: true),
        _item('Eggs', hoursAgo: 0),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['Milk', 'Eggs']);
    });

    test('returns empty list when no items', () {
      final list = _createList([]);
      expect(list.frequentItemNames, isEmpty);
    });

    test('returns single item for list with one item', () {
      final list = _createList([_item('Milk')]);
      expect(list.frequentItemNames, ['Milk']);
    });

    test('sorts by frequency descending', () {
      final list = _createList([
        _item('C', hoursAgo: 0),
        _item('A', hoursAgo: 0),
        _item('A', hoursAgo: 1),
        _item('A', hoursAgo: 2),
        _item('B', hoursAgo: 0),
        _item('B', hoursAgo: 1),
      ]);

      final result = list.frequentItemNames;
      expect(result, ['A', 'B', 'C']);
    });
  });
}
