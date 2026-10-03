import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/services/firestore_migration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreMigrationService', () {
    test('does nothing when Firebase is not available', () async {
      // When Firebase is not available (no mock setup), the service should
      // return early without making any Firestore calls.
      // We verify this by checking no exception is thrown.
      final localLists = <ShoppingList>[
        ShoppingList(
          id: 'local-1',
          name: 'Test List',
          description: '',
          color: '#000000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Should not throw even when Firebase is unavailable
      await expectLater(
        FirestoreMigrationService.migrateLocalData([
          ShoppingList(
            'local-1',
            'Test List',
            '',
            '#000000',
            DateTime.now(),
            DateTime.now(),
          ),
        ]),
        returnsNormally,
      );

    test('does not throw when list has items', () async {
      final listWithItems = ShoppingList(
        'local-1',
        'Groceries',
        '',
        '#FF0000',
        DateTime.now(),
        DateTime.now(),
        items: [
          ShoppingItem('item-1', 'Milk', isCompleted: false, createdAt: DateTime.now()),
          ShoppingItem('item-2', 'Bread', isCompleted: false, createdAt: DateTime.now()),
        ],
      );

      await expectLater(
        FirestoreMigrationService.migrateLocalData([listWithItems]),
        returnsNormally,
      );
    });
  });
}
