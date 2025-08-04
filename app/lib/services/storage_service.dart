import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'local_storage_service.dart';

// Result class for sharing operations
class ShareResult {
  final bool success;
  final String? errorMessage;

  ShareResult.success() : success = true, errorMessage = null;
  ShareResult.error(this.errorMessage) : success = false;
}

/// Simplified StorageService - thin facade that routes between local and Firebase layers
/// Automatically handles local vs Firebase storage based on authentication state
class StorageService {
  static StorageService? _instance;

  // Service layers
  final LocalStorageService _local = LocalStorageService.instance;
  // FirestoreLayer is now static - no instance needed

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize the storage service
  Future<void> init() async {
    await _local.init();
  }

  // ==========================================
  // CORE INTERFACE - Lists
  // ==========================================

  /// Create a new shopping list
  Future<bool> createList(ShoppingList list) async {
    return await _local.upsertList(list);
  }

  /// Update an existing shopping list
  Future<bool> updateList(ShoppingList list) async {
    return await _local.upsertList(list);
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    return await _local.deleteList(id);
  }

  /// Get all shopping lists as a stream (reactive)
  Stream<List<ShoppingList>> watchLists() {
    return _local.watchLists();
  }

  /// Get a specific list as a stream (reactive)
  Stream<ShoppingList?> watchList(String id) {
    return _local.watchList(id);
  }

  // ==========================================
  // CORE INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    return await _local.addItem(listId, item);
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    return await _local.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
    return await _local.deleteItem(listId, itemId);
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    return await _local.clearCompleted(listId);
  }

  // ==========================================
  // SHARING (authenticated users only)
  // ==========================================

  /// Share a list with another user by email
  Future<ShareResult> shareList(String listId, String email) async {
    // Sharing is disabled in local-first mode for now
    return ShareResult.error(
      'Sharing is currently unavailable in local-first mode.',
    );
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Force a manual sync (for local-first users)
  Future<void> sync() async {
    // In local-first mode, refresh local streams by re-emitting current data
    _local.refreshStreams();
    debugPrint('✅ Manual refresh complete');
  }

  /// Clear all user data (called on logout)
  Future<void> clearUserData() async {
    await _local.clearAllData();
    debugPrint('🗑️ User data cleared completely');
  }

  /// Clean up resources when no longer needed
  void dispose() {
    _local.dispose();
    // FirestoreLayer is now static - no cleanup needed
  }

  /// Clean up individual list stream when no longer needed
  void disposeListStream(String listId) {
    _local.disposeListStream(listId);
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  // ==========================================
  // TEST HELPERS
  // ==========================================

  @visibleForTesting
  Future<bool> saveListLocallyForTest(ShoppingList list) async {
    return await _local.upsertList(list);
  }

  @visibleForTesting
  Future<List<ShoppingList>> getAllListsLocallyForTest() async {
    return await _local.getAllListsForTest();
  }

  @visibleForTesting
  Future<ShoppingList?> getListByIdLocallyForTest(String id) async {
    return await _local.getListByIdForTest(id);
  }

  @visibleForTesting
  Future<bool> deleteListLocallyForTest(String id) async {
    return await _local.deleteList(id);
  }

  @visibleForTesting
  Future<bool> addItemToLocalListForTest(
    String listId,
    ShoppingItem item,
  ) async {
    return await _local.addItem(listId, item);
  }

  @visibleForTesting
  Future<bool> updateItemInLocalListForTest(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    return await _local.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @visibleForTesting
  Future<bool> deleteItemFromLocalListForTest(
    String listId,
    String itemId,
  ) async {
    return await _local.deleteItem(listId, itemId);
  }

  @visibleForTesting
  Future<bool> isMigrationCompleteForTest() async {
    // Migration is no longer needed in local-first architecture
    return true;
  }

  @visibleForTesting
  Future<void> markMigrationCompleteForTest() async {
    // Migration is no longer needed in local-first architecture
    // This method is kept for test compatibility but does nothing
  }

  @visibleForTesting
  Future<void> clearLocalDataForTest() async {
    return await _local.clearAllDataForTest();
  }

  /// Get raw list data including soft-deleted items (for testing soft delete behavior)
  @visibleForTesting
  Future<ShoppingList?> getRawListByIdForTest(String id) async {
    return await _local.getRawListByIdForTest(id);
  }

  /// Get all raw list data including soft-deleted items (for testing soft delete behavior)
  @visibleForTesting
  Future<List<ShoppingList>> getRawListsForTest() async {
    return await _local.getRawListsForTest();
  }

  /// Reset singleton instance for testing
  @visibleForTesting
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
    LocalStorageService.resetInstanceForTest();
  }
}
