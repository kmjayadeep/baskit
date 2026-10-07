import 'package:baskit/models/shopping_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShoppingItem JSON compatibility', () {
    final createdAt = DateTime.utc(2026, 1, 2);
    final completedAt = DateTime.utc(2026, 1, 3);

    test('round-trips every item type and completion date', () {
      for (final type in ItemType.values) {
        final item = ShoppingItem(
          id: 'item-1',
          name: 'Milk',
          quantity: '2',
          createdAt: createdAt,
          completedAt: completedAt,
          isCompleted: true,
          listItemType: type,
        );
        final parsed = ShoppingItem.fromJson(item.toJson());
        expect(parsed.id, item.id);
        expect(parsed.name, item.name);
        expect(parsed.quantity, item.quantity);
        expect(parsed.createdAt, createdAt);
        expect(parsed.completedAt, completedAt);
        expect(parsed.isCompleted, isTrue);
        expect(parsed.listItemType, type);
      }
    });

    test('handles absent and invalid optional dates and item types', () {
      final missing = ShoppingItem.fromJson({});
      expect(missing.id, '');
      expect(missing.name, '');
      expect(missing.completedAt, isNull);
      expect(missing.listItemType, ItemType.needsPurchase);
      expect(missing.createdAt, isA<DateTime>());

      final invalid = ShoppingItem.fromJson({
        'createdAt': 'not a date',
        'completedAt': 'not a date',
        'listItemType': 'unknown',
      });
      expect(invalid.createdAt, isA<DateTime>());
      expect(invalid.completedAt, isNull);
      expect(invalid.listItemType, ItemType.needsPurchase);
    });

    test('accepts legacy DateTime completion values', () {
      final item = ShoppingItem.fromJson({
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt,
      });
      expect(item.completedAt, completedAt);
      expect(ShoppingItem.fromJson({'completedAt': 123}).completedAt, isNull);
    });

    test('copies type without changing immutable fields', () {
      final original = ShoppingItem(
        id: 'item-1',
        name: 'Milk',
        createdAt: createdAt,
        completedAt: completedAt,
      );
      final changed = original.copyWith(
        name: 'Oat milk',
        listItemType: ItemType.runOut,
        clearCompletedAt: true,
      );
      expect(changed.id, original.id);
      expect(changed.createdAt, createdAt);
      expect(changed.name, 'Oat milk');
      expect(changed.completedAt, isNull);
      expect(changed.listItemType, ItemType.runOut);
      expect(changed.toString(), contains('runOut'));
      expect(original.listItemType, ItemType.needsPurchase);
    });
  });
}
