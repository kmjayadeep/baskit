import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../repositories/local_storage_repository.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Result class for sharing operations
class ShareResult {
  final bool success;
  final String? errorMessage;

  ShareResult.success() : success = true, errorMessage = null;
  ShareResult.error(this.errorMessage) : success = false;
}

/// Unified storage facade that provides a single interface for data operations
///
/// This service acts as a facade that:
/// - Routes operations between local and remote storage based on app state
/// - Provides a simplified, unified API for the UI layer
/// - Handles the complexity of choosing between storage backends
/// - Manages the transition between local-first and cloud-sync modes
///
/// Architecture:
/// - All CRUD operations route to LocalStorageRepository for local-first experience
/// - Cloud-only features (sharing) delegate to FirestoreService when authenticated
/// - Background sync handled separately by SyncService
///
/// Delegates to:
/// - LocalStorageRepository for all data persistence
/// - FirestoreService for cloud-only operations when authenticated
class StorageService {
  static StorageService? _instance;

  // Repository dependencies
  final LocalStorageRepository _localRepository =
      LocalStorageRepository.instance;

  /// Private constructor for singleton pattern
  StorageService._();

  /// Singleton getter
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  // ==========================================
  // INITIALIZATION
  // ==========================================

  /// Initialize the storage service and its dependencies
  Future<void> init() async {
    await _localRepository.init();
  }

  // ==========================================
  // UNIFIED DATA INTERFACE - Lists
  // ==========================================

  /// Create a new shopping list
  Future<bool> createList(ShoppingList list) async {
    return await _localRepository.upsertList(list);
  }

  /// Update an existing shopping list
  Future<bool> updateList(ShoppingList list) async {
    return await _localRepository.upsertList(list);
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    return await _localRepository.deleteList(id);
  }

  /// Get all shopping lists as a reactive stream
  Stream<List<ShoppingList>> watchLists() {
    return _localRepository.watchLists();
  }

  /// Get a specific list as a reactive stream
  Stream<ShoppingList?> watchList(String id) {
    return _localRepository.watchList(id);
  }

  // ==========================================
  // UNIFIED DATA INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    return await _localRepository.addItem(listId, item);
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? isCompleted,
  }) async {
    return await _localRepository.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      isCompleted: isCompleted,
    );
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
    return await _localRepository.deleteItem(listId, itemId);
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    return await _localRepository.clearCompleted(listId);
  }

  // ==========================================
  // CLOUD FEATURES
  // ==========================================

  /// Share a list with another user by email
  ///
  /// Routes to FirestoreService when user is authenticated.
  /// Returns appropriate error messages for different scenarios.
  Future<ShareResult> shareList(String listId, String email) async {
    // Check if user is authenticated (non-anonymous)
    if (FirebaseAuthService.currentUser == null ||
        FirebaseAuthService.isAnonymous) {
      return ShareResult.error(
        'Sign in with Google to share lists with others.',
      );
    }

    try {
      // Delegate to FirestoreService for cloud sharing functionality
      final success = await FirestoreService.shareListWithUser(listId, email);

      if (success) {
        return ShareResult.success();
      } else {
        return ShareResult.error('Failed to share list. Please try again.');
      }
    } on UserNotFoundException catch (e) {
      return ShareResult.error(
        'User with email "${e.email}" not found. Make sure they have an account.',
      );
    } on UserAlreadyMemberException catch (e) {
      return ShareResult.error(
        '${e.userName} is already a member of this list.',
      );
    } catch (e) {
      debugPrint('Error sharing list: $e');

      // Handle specific error cases
      if (e.toString().contains('List not found')) {
        return ShareResult.error('List not found. Please try again.');
      }

      return ShareResult.error(
        'Unable to share list. Check your connection and try again.',
      );
    }
  }

  // ==========================================
  // UTILITY OPERATIONS
  // ==========================================

  /// Force a manual sync/refresh of data
  ///
  /// In local-first mode: Refreshes local streams
  /// Future: Will trigger cloud synchronization when available
  Future<void> sync() async {
    _localRepository.refreshStreams();
    debugPrint('✅ Manual refresh complete');
  }

  /// Clear all user data (typically called on logout)
  Future<void> clearUserData() async {
    await _localRepository.clearAllData();
    debugPrint('🗑️ User data cleared completely');
  }

  // ==========================================
  // RESOURCE MANAGEMENT
  // ==========================================

  /// Clean up resources when service is no longer needed
  void dispose() {
    _localRepository.dispose();
  }

  /// Clean up individual list stream when no longer needed
  void disposeListStream(String listId) {
    _localRepository.disposeListStream(listId);
  }

  // ==========================================
  // TEST HELPERS
  // ==========================================

  @visibleForTesting
  Future<bool> saveListLocallyForTest(ShoppingList list) async {
    return await _localRepository.upsertList(list);
  }

  @visibleForTesting
  Future<List<ShoppingList>> getAllListsLocallyForTest() async {
    return await _localRepository.getAllListsForTest();
  }

  @visibleForTesting
  Future<ShoppingList?> getListByIdLocallyForTest(String id) async {
    return await _localRepository.getListByIdForTest(id);
  }

  @visibleForTesting
  Future<bool> deleteListLocallyForTest(String id) async {
    return await _localRepository.deleteList(id);
  }

  @visibleForTesting
  Future<bool> addItemToLocalListForTest(
    String listId,
    ShoppingItem item,
  ) async {
    return await _localRepository.addItem(listId, item);
  }

  @visibleForTesting
  Future<bool> updateItemInLocalListForTest(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? isCompleted,
  }) async {
    return await _localRepository.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      isCompleted: isCompleted,
    );
  }

  @visibleForTesting
  Future<bool> deleteItemFromLocalListForTest(
    String listId,
    String itemId,
  ) async {
    return await _localRepository.deleteItem(listId, itemId);
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
    return await _localRepository.clearAllDataForTest();
  }

  /// Get raw list data including soft-deleted items (for testing soft delete behavior)
  @visibleForTesting
  Future<ShoppingList?> getRawListByIdForTest(String id) async {
    return await _localRepository.getRawListByIdForTest(id);
  }

  /// Get all raw list data including soft-deleted items (for testing soft delete behavior)
  @visibleForTesting
  Future<List<ShoppingList>> getRawListsForTest() async {
    return await _localRepository.getRawListsForTest();
  }

  /// Reset singleton instance for testing
  @visibleForTesting
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
    LocalStorageRepository.resetInstanceForTest();
  }
}
