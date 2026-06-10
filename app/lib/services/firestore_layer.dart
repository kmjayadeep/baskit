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

    final firebaseId = await FirestoreService.createList(list);
    return firebaseId != null;
  }

  /// Update an existing shopping list
  Future<bool> updateList(ShoppingList list) async {
    final override = _updateListOverrideForTest;
    if (override != null) {
      return override(list);
    }

    return await FirestoreService.updateList(
      list.id,
      name: list.name,
      description: list.description,
      color: list.color,
    );
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    final override = _deleteListOverrideForTest;
    if (override != null) {
      return override(id);
    }

    return await FirestoreService.deleteList(id);
  }

  /// Get all shopping lists as a stream (reactive)
  Stream<List<ShoppingList>> watchLists() {
    return FirestoreService.getUserLists();
  }

  /// Get a specific list as a stream (reactive)
  Stream<ShoppingList?> watchList(String id) {
    return FirestoreService.getListById(id);
  }

  // ==========================================
  // CORE INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    final firebaseItemId = await FirestoreService.addItemToList(listId, item);
    return firebaseItemId != null;
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    return await FirestoreService.updateItemInList(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
    return await FirestoreService.deleteItemFromList(listId, itemId);
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    return await FirestoreService.clearCompletedItems(listId);
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

    return await FirestoreService.shareListWithUser(listId, email);
  }

  // ==========================================
  // MEMBER OPERATIONS
  // ==========================================

  /// Remove a member from a list
  Future<bool> removeMemberFromList(String listId, String userId) async {
    return await FirestoreService.removeMemberFromList(listId, userId);
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
