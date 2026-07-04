import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/firestore_shopping_repository.dart';
import 'package:baskit/repositories/storage_shopping_repository.dart';
import 'package:baskit/services/storage_service.dart';
import 'package:baskit/services/firestore_errors.dart';

void main() {
  group('Share List Flow Integration Tests', () {
    late StorageService storageService;
    late StorageShoppingRepository repository;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_share_list_test',
      );
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(MemberRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ListMemberAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetInstanceForTest();
      storageService = StorageService.instance;
      await storageService.init();
      repository = StorageShoppingRepository.instance();
    });

    tearDown(() async {
      await storageService.clearLocalDataForTest();
      StorageService.resetInstanceForTest();
      FirestoreShoppingRepository.resetOverridesForTest();

      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    tearDownAll(() async {
      try {
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('shares a list with a user by email via mock', () async {
      String? capturedEmail;
      String? capturedListId;

      // Override Firestore to capture the share call
      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        email,
      ) async {
        capturedEmail = email;
        capturedListId = listId;
        return true;
      });

      // Set local-only mode to false so cloud path is used
      StorageShoppingRepository.setUseLocalOverrideForTest(false);

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final testList = ShoppingList(
        id: 'list-share-1',
        name: 'Shareable List',
        description: 'Test list for sharing',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create the list first (will go through override)
      await repository.createList(testList);

      // Now share the list
      final result = await repository.shareList(
        testList.id,
        'friend@example.com',
      );

      expect(result.success, isTrue);
      expect(capturedListId, equals(testList.id));
      expect(capturedEmail, equals('friend@example.com'));
    });

    test('share returns error for user not found', () async {
      // Override share to throw UserNotFoundException
      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        email,
      ) async {
        throw UserNotFoundException(email);
      });

      StorageShoppingRepository.setUseLocalOverrideForTest(false);

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await repository.shareList(
        'list-share-2',
        'missing@example.com',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!, contains('not found'));
      expect(result.errorMessage!, contains('missing@example.com'));
    });

    test('share returns error for already a member', () async {
      // Override share to throw UserAlreadyMemberException
      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        email,
      ) async {
        throw UserAlreadyMemberException('Test User');
      });

      StorageShoppingRepository.setUseLocalOverrideForTest(false);

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await repository.shareList(
        'list-share-3',
        'existing@example.com',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!, 'This user is already a member of this list.');
    });

    test('share returns generic error for unknown failures', () async {
      // Override share to throw a generic exception
      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        email,
      ) async {
        throw Exception('Network error');
      });

      StorageShoppingRepository.setUseLocalOverrideForTest(false);

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await repository.shareList(
        'list-share-4',
        'fallback@example.com',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!, contains('Unable to share list'));
      expect(result.errorMessage!, contains('fallback@example.com'));
    });
  });
}
