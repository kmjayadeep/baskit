import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/services/firestore_migration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Minimal mock for debugPrint to capture output
class _TestDebugPrinter {
  final List<String> messages = [];

  void call(String message) {
    messages.add(message);
  }
}

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
        FirestoreMigrationService.migrateLocalData(localLists),
        returnsNormally,
      );
    });

    test('handles empty list of local lists', () async {
      // When Firebase is not available, empty list should also return normally
      await expectLater(
        FirestoreMigrationService.migrateLocalData([]),
        returnsNormally,
      );
    });

    test('handles multiple local lists when Firebase unavailable', () async {
      final localLists = List.generate(
        10,
        (i) => ShoppingList(
          id: 'local-$i',
          name: 'List $i',
          description: 'Description $i',
          color: '#${i.toString().padLeft(6, '0')}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await expectLater(
        FirestoreMigrationService.migrateLocalData(localLists),
        returnsNormally,
      );
    });

    test('does not throw when list has items', () async {
      final listWithItems = ShoppingList(
        id: 'local-1',
        name: 'Groceries',
        description: '',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          ShoppingItem(id: 'item-1', name: 'Milk'),
          ShoppingItem(id: 'item-2', name: 'Bread'),
        ],
      );

      await expectLater(
        FirestoreMigrationService.migrateLocalData([listWithItems]),
        returnsNormally,
      );
    });
  });
}
