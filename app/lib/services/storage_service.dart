import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'local_storage_service.dart';
import 'firestore_layer.dart';
import 'firebase_auth_service.dart';

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
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _migrationCompleteKey = 'migration_complete_';
  static StorageService? _instance;

  // Service layers
  final LocalStorageService _local = LocalStorageService.instance;
  final FirestoreLayer _firebase = FirestoreLayer.instance;

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
    _firebase.dispose();
  }

  /// Clean up individual list stream when no longer needed
  void disposeListStream(String listId) {
    _local.disposeListStream(listId);
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Get migration key for current user
  String get _currentUserMigrationKey {
    final userId = FirebaseAuthService.currentUser?.uid ?? 'anonymous';
    return '$_migrationCompleteKey$userId';
  }

  /// Check if migration has been completed for current user
  Future<bool> _isMigrationComplete() async {
    if (FirebaseAuthService.isAnonymous) {
      return true; // Anonymous users don't need migration
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_currentUserMigrationKey) ?? false;
  }

  /// Mark migration as complete for current user
  Future<void> _markMigrationComplete() async {
    if (!FirebaseAuthService.isAnonymous) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_currentUserMigrationKey, true);
    }
  }

  /// Ensure migration is complete for authenticated users
  Future<void> _ensureMigrationComplete() async {
    if (FirebaseAuthService.isAnonymous || await _isMigrationComplete()) {
      return; // No migration needed
    }

    debugPrint('🔄 Starting migration of local data to Firebase...');

    try {
      // Get local lists
      final localLists = await _local.getAllLists();

      if (localLists.isNotEmpty) {
        // Migrate each list to Firebase
        for (final list in localLists) {
          try {
            final success = await _firebase.createList(list);
            if (success) {
              debugPrint('✅ Migrated list "${list.name}" to Firebase');
            } else {
              debugPrint('❌ Failed to migrate list "${list.name}"');
            }
          } catch (e) {
            debugPrint('❌ Error migrating list "${list.name}": $e');
          }
        }

        debugPrint(
          '✅ Migration completed: ${localLists.length} lists processed',
        );
      }

      // Mark migration as complete
      await _markMigrationComplete();
      await _updateLastSyncTime();

      // Clear local data after successful migration
      await _local.clearAllData();
      debugPrint('🗑️ Local data cleared after migration');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      // Don't mark as complete if migration failed
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check sync status
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

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
    return await _isMigrationComplete();
  }

  @visibleForTesting
  Future<void> markMigrationCompleteForTest() async {
    return await _markMigrationComplete();
  }

  @visibleForTesting
  Future<void> clearLocalDataForTest() async {
    return await _local.clearAllDataForTest();
  }

  /// Reset singleton instance for testing
  @visibleForTesting
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
    LocalStorageService.resetInstanceForTest();
  }
}
