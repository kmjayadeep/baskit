import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/share_result.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/services/local_storage_service.dart';
import 'package:baskit/services/migration_service.dart';

class FakeCloudRepository implements ShoppingRepository {
  final Map<String, Queue<bool>> createResultsByListId = {};
  final List<String> createAttempts = [];

  void queueCreateResults(String listId, List<bool> results) {
    createResultsByListId[listId] = Queue<bool>.of(results);
  }

  @override
  Future<bool> createList(ShoppingList list) async {
    createAttempts.add(list.id);
    final queuedResults = createResultsByListId[list.id];
    if (queuedResults != null && queuedResults.isNotEmpty) {
      return queuedResults.removeFirst();
    }
    return true;
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    throw UnimplementedError();
  }

  @override
  Future<bool> clearCompleted(String listId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteList(String id) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  void disposeListStream(String id) {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  Future<void> init() async {}

  @override
  Future<bool> removeMember(String listId, String userId) {
    throw UnimplementedError();
  }

  @override
  Future<ShareResult> shareList(String listId, String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> sync() async {}

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateList(ShoppingList list) {
    throw UnimplementedError();
  }

  @override
  Stream<ShoppingList?> watchList(String id) => const Stream.empty();

  @override
  Stream<List<ShoppingList>> watchLists() => const Stream.empty();
}

void main() {
  group('MigrationService production-like retry behavior', () {
    late LocalStorageService localStorage;
    late FakeCloudRepository cloudRepository;
    late MigrationService migrationService;

    setUpAll(() {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_migration_service_test',
      );
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LocalStorageService.resetInstanceForTest();
      localStorage = LocalStorageService.instance;
      await localStorage.init();
      cloudRepository = FakeCloudRepository();
      migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );
    });

    tearDown(() async {
      await localStorage.clearAllDataForTest();
      LocalStorageService.resetInstanceForTest();

      if (Hive.isBoxOpen('shopping_lists')) {
        await Hive.box<ShoppingList>('shopping_lists').clear();
        await Hive.box<ShoppingList>('shopping_lists').close();
      }
    });

    tearDownAll(() async {
      try {
        await Hive.deleteFromDisk();
      } catch (_) {
        // Ignore cleanup errors from host-side Hive tests.
      }
    });

    ShoppingList buildLocalList(String id) {
      return ShoppingList(
        id: id,
        name: 'List $id',
        description: 'Local guest list $id',
        color: '#FF5722',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    test(
      'keeps local lists and leaves migration pending after a partial failure',
      () async {
        await localStorage.upsertList(buildLocalList('list-a'));
        await localStorage.upsertList(buildLocalList('list-b'));
        cloudRepository.queueCreateResults('list-b', [false]);

        final completed = await migrationService.ensureComplete();

        expect(completed, isFalse);
        expect(await migrationService.isComplete(), isFalse);
        expect(cloudRepository.createAttempts, ['list-a', 'list-b']);
        expect(
          (await localStorage.getAllListsForTest()).map((list) => list.id),
          containsAll(['list-a', 'list-b']),
        );
      },
    );

    test(
      'retries pending local lists and clears them only after success',
      () async {
        await localStorage.upsertList(buildLocalList('list-a'));
        await localStorage.upsertList(buildLocalList('list-b'));
        cloudRepository.queueCreateResults('list-b', [false, true]);

        final firstAttempt = await migrationService.ensureComplete();
        final secondAttempt = await migrationService.ensureComplete();

        expect(firstAttempt, isFalse);
        expect(secondAttempt, isTrue);
        expect(await migrationService.isComplete(), isTrue);
        expect(cloudRepository.createAttempts, [
          'list-a',
          'list-b',
          'list-a',
          'list-b',
        ]);
        expect(await localStorage.getAllListsForTest(), isEmpty);
      },
    );

    test('clears migration status for a specified deleted user', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('migration_complete_deleted-user', true);
      await prefs.setBool('migration_complete_other-user', true);

      await migrationService.clearForUserId('deleted-user');

      expect(prefs.getBool('migration_complete_deleted-user'), isNull);
      expect(prefs.getBool('migration_complete_other-user'), isTrue);
    });
  });
}
