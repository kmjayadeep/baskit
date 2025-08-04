import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('ShoppingList Model Tests', () {
    late DateTime now;
    late ShoppingList testList;
    late List<ShoppingItem> testItems;

    setUp(() {
      now = DateTime.now();
      testItems = [
        ShoppingItem(
          id: '1',
          name: 'Active Item 1',
          quantity: '1',
          isCompleted: false,
          createdAt: now,
        ),
        ShoppingItem(
          id: '2',
          name: 'Completed Item',
          quantity: '1',
          isCompleted: true,
          createdAt: now,
        ),
        ShoppingItem(
          id: '3',
          name: 'Soft Deleted Item',
          quantity: '1',
          isCompleted: false,
          createdAt: now,
          deletedAt: now, // This item is soft-deleted
        ),
      ];

      testList = ShoppingList(
        id: 'test-list',
        name: 'Test List',
        description: 'Test Description',
        color: '#FF0000',
        createdAt: now,
        updatedAt: now,
        items: testItems,
      );
    });

    group('Soft Delete Filtering', () {
      test('activeItems should exclude soft-deleted items', () {
        // Should return only items without deletedAt
        expect(testList.activeItems.length, equals(2));
        expect(
          testList.activeItems.map((item) => item.id),
          containsAll(['1', '2']),
        );
        expect(
          testList.activeItems.map((item) => item.id),
          isNot(contains('3')),
        );
      });

      test('totalItemsCount should count only active items', () {
        // This would have caught the bug where totalItemsCount included deleted items
        expect(testList.totalItemsCount, equals(2)); // Not 3!
      });

      test('completedItemsCount should count only active completed items', () {
        expect(testList.completedItemsCount, equals(1)); // Only item '2'
      });
    });

    group('Progress Calculations', () {
      test('completionProgress should be based on active items only', () {
        // 1 completed out of 2 active = 0.5
        expect(testList.completionProgress, equals(0.5));
      });

      test('completionProgress should handle edge cases', () {
        final emptyList = testList.copyWith(items: []);
        expect(emptyList.completionProgress, equals(0.0));

        final allDeletedList = testList.copyWith(
          items: [
            ShoppingItem(
              id: 'deleted',
              name: 'Deleted',
              quantity: '1',
              isCompleted: false,
              createdAt: now,
              deletedAt: now,
            ),
          ],
        );
        expect(allDeletedList.completionProgress, equals(0.0));
      });
    });

    group('toString Representation', () {
      test('toString should show active items count', () {
        final stringRep = testList.toString();
        // Should show 2 active items, not 3 total items
        expect(stringRep, contains('items: 2'));
      });
    });

    group('JSON Serialization with Soft Deletes', () {
      test('should preserve deletedAt in JSON serialization', () {
        final json = testList.toJson();
        final reconstructed = ShoppingList.fromJson(json);

        expect(reconstructed.items.length, equals(3)); // All items preserved
        expect(
          reconstructed.activeItems.length,
          equals(2),
        ); // Only active shown
        expect(reconstructed.totalItemsCount, equals(2)); // Count only active
      });
    });
  });
}
