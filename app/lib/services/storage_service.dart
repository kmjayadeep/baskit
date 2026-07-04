import 'package:flutter/foundation.dart';

import '../models/share_result.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/firestore_shopping_repository.dart';
import '../repositories/storage_shopping_repository.dart';
import 'local_storage_service.dart';

export '../models/share_result.dart';

/// Compatibility facade for older callers that still depend on StorageService.
///
/// **Deprecated**: This class is a compatibility facade that will be removed
/// once all callers migrate to repository abstractions via
/// `shoppingRepositoryProvider`. New code should depend on
/// [StorageShoppingRepository] directly through that provider.
///
/// Remaining callers that still need migration:
/// - `main.dart` (bootstrap initialization)
/// - `FirebaseAuthService.signOut()` / `deleteAccount()` (clearUserData)
class StorageService {
  static StorageService? _instance;

  final StorageShoppingRepository _repository;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  StorageService._() : _repository = StorageShoppingRepository.instance();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() => _repository.init();

  Future<bool> createList(ShoppingList list) => _repository.createList(list);

  Future<bool> updateList(ShoppingList list) => _repository.updateList(list);

  Future<bool> deleteList(String id) => _repository.deleteList(id);

  Stream<List<ShoppingList>> watchLists() => _repository.watchLists();

  Stream<ShoppingList?> watchList(String id) => _repository.watchList(id);

  Future<bool> addItem(String listId, ShoppingItem item) {
    return _repository.addItem(listId, item);
  }

  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return _repository.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  Future<bool> deleteItem(String listId, String itemId) {
    return _repository.deleteItem(listId, itemId);
  }

  Future<bool> clearCompleted(String listId) {
    return _repository.clearCompleted(listId);
  }

  Future<ShareResult> shareList(String listId, String email) {
    return _repository.shareList(listId, email);
  }

  Future<bool> removeMember(String listId, String userId) {
    return _repository.removeMember(listId, userId);
  }

  Future<void> sync() => _repository.sync();

  Future<void> clearUserData() => _repository.clearUserData();

  Future<DateTime?> getLastSyncTime() => _repository.getLastSyncTime();

  void dispose() => _repository.dispose();

  void disposeListStream(String listId) {
    _repository.disposeListStream(listId);
  }

  @visibleForTesting
  Future<bool> saveListLocallyForTest(ShoppingList list) {
    return _repository.saveListLocallyForTest(list);
  }

  @visibleForTesting
  Future<List<ShoppingList>> getAllListsLocallyForTest() {
    return _repository.getAllListsLocallyForTest();
  }

  @visibleForTesting
  Future<ShoppingList?> getListByIdLocallyForTest(String id) {
    return _repository.getListByIdLocallyForTest(id);
  }

  @visibleForTesting
  Future<bool> deleteListLocallyForTest(String id) {
    return _localStorage.deleteList(id);
  }

  @visibleForTesting
  Future<bool> addItemToLocalListForTest(String listId, ShoppingItem item) {
    return _localStorage.addItem(listId, item);
  }

  @visibleForTesting
  Future<bool> updateItemInLocalListForTest(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return _localStorage.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @visibleForTesting
  Future<bool> deleteItemFromLocalListForTest(String listId, String itemId) {
    return _localStorage.deleteItem(listId, itemId);
  }

  @visibleForTesting
  Future<bool> isMigrationCompleteForTest() {
    return _repository.isMigrationCompleteForTest();
  }

  @visibleForTesting
  Future<void> markMigrationCompleteForTest() {
    return _repository.markMigrationCompleteForTest();
  }

  @visibleForTesting
  Future<void> clearLocalDataForTest() {
    return _repository.clearLocalDataForTest();
  }

  @visibleForTesting
  static String mapShareErrorForTest(Object error, String email) {
    return FirestoreShoppingRepository.mapShareErrorForTest(error, email);
  }

  @visibleForTesting
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
    StorageShoppingRepository.resetOverridesForTest();
    LocalStorageService.resetInstanceForTest();
  }

  @visibleForTesting
  static void setUseLocalOverrideForTest(bool? value) {
    StorageShoppingRepository.setUseLocalOverrideForTest(value);
  }
}
