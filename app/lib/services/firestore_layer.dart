import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import 'firestore_service.dart';

/// Firestore layer that provides a clean interface around FirestoreService
/// Handles all Firebase operations for authenticated users
class FirestoreLayer {
  static FirestoreLayer? _instance;
  static Future<bool> Function(ShoppingList list)? _createListOverrideForTest;
  static Future<bool> Function(ShoppingList list)? _updateListOverrideForTest;
  static Future<bool> Function(String id)? _deleteListOverrideForTest;
  static Future<bool> Function(String listId, String email)?
  _shareListOverrideForTest;

  FirestoreLayer._();

  static FirestoreLayer get instance {
    _instance ??= FirestoreLayer._();
    return _instance!;
  }

  // ==========================================
  // CORE INTERFACE - Lists
  // ==========================================

  /// Create a new shopping list
  Future<bool> createList(ShoppingList list) async {
    final override = _createListOverrideForTest;
    if (override != null) {
      return override(list);
    }

    try {
      final firebaseId = await FirestoreService.createList(list);
      return firebaseId != null;
    } catch (e) {
      debugPrint('❌ Firebase create failed: $e');
      return false;
    }
  }

  /// Update an existing shopping list
  Future<bool> updateList(ShoppingList list) async {
    final override = _updateListOverrideForTest;
    if (override != null) {
      return override(list);
    }

    try {
      return await FirestoreService.updateList(
        list.id,
        name: list.name,
        description: list.description,
        color: list.color,
      );
    } catch (e) {
      debugPrint('❌ Firebase update failed: $e');
      return false;
    }
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    final override = _deleteListOverrideForTest;
    if (override != null) {
      return override(id);
    }

    try {
      return await FirestoreService.deleteList(id);
    } catch (e) {
      debugPrint('❌ Firebase delete failed: $e');
      return false;
    }
  }

  /// Get all shopping lists as a stream (reactive)
  Stream<List<ShoppingList>> watchLists() {
    try {
      return FirestoreService.getUserLists();
    } catch (e) {
      debugPrint('❌ Firebase stream error: $e');
      return Stream.value([]);
    }
  }

  /// Get a specific list as a stream (reactive)
  Stream<ShoppingList?> watchList(String id) {
    try {
      return FirestoreService.getListById(id);
    } catch (e) {
      debugPrint('❌ Firebase list stream error: $e');
      return Stream.value(null);
    }
  }

  // ==========================================
  // CORE INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    try {
      final firebaseItemId = await FirestoreService.addItemToList(listId, item);
      return firebaseItemId != null;
    } catch (e) {
      debugPrint('❌ Firebase add item failed: $e');
      return false;
    }
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    try {
      return await FirestoreService.updateItemInList(
        listId,
        itemId,
        name: name,
        quantity: quantity,
        completed: completed,
      );
    } catch (e) {
      debugPrint('❌ Firebase update item failed: $e');
      return false;
    }
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
    try {
      return await FirestoreService.deleteItemFromList(listId, itemId);
    } catch (e) {
      debugPrint('❌ Firebase delete item failed: $e');
      return false;
    }
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    try {
      return await FirestoreService.clearCompletedItems(listId);
    } catch (e) {
      debugPrint('❌ Firebase clear completed items failed: $e');
      return false;
    }
  }

  // ==========================================
  // SHARING (authenticated users only)
  // ==========================================

  /// Share a list with another user by email
  Future<bool> shareList(String listId, String email) async {
    final override = _shareListOverrideForTest;
    if (override != null) {
      return override(listId, email);
    }

    try {
      return await FirestoreService.shareListWithUser(listId, email);
    } on UserNotFoundException {
      rethrow;
    } on UserAlreadyMemberException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Firebase share failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // MEMBER OPERATIONS
  // ==========================================

  /// Remove a member from a list
  Future<bool> removeMemberFromList(String listId, String userId) async {
    try {
      return await FirestoreService.removeMemberFromList(listId, userId);
    } catch (e) {
      debugPrint('❌ Firebase remove member failed: $e');
      return false;
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Initialize Firebase services if needed
  Future<void> init() async {
    // Firebase initialization is handled elsewhere
    // This method exists for interface consistency
  }

  /// Clean up resources (no-op for Firebase)
  void dispose() {
    // Firebase streams are managed by the Firebase SDK
    // This method exists for interface consistency
  }

  /// Clean up individual list stream (no-op for Firebase)
  void disposeListStream(String listId) {
    // Firebase streams are managed by the Firebase SDK
    // This method exists for interface consistency
  }

  @visibleForTesting
  static void setCreateListOverrideForTest(
    Future<bool> Function(ShoppingList list)? override,
  ) {
    _createListOverrideForTest = override;
  }

  @visibleForTesting
  static void setUpdateListOverrideForTest(
    Future<bool> Function(ShoppingList list)? override,
  ) {
    _updateListOverrideForTest = override;
  }

  @visibleForTesting
  static void setDeleteListOverrideForTest(
    Future<bool> Function(String id)? override,
  ) {
    _deleteListOverrideForTest = override;
  }

  @visibleForTesting
  static void setShareListOverrideForTest(
    Future<bool> Function(String listId, String email)? override,
  ) {
    _shareListOverrideForTest = override;
  }

  @visibleForTesting
  static void resetOverridesForTest() {
    _createListOverrideForTest = null;
    _updateListOverrideForTest = null;
    _deleteListOverrideForTest = null;
    _shareListOverrideForTest = null;
  }
}
