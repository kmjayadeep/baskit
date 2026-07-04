import 'package:flutter/foundation.dart';

import '../models/share_result.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../services/firestore_service.dart';
import 'shopping_repository.dart';

/// Cloud-backed shopping repository for authenticated users.
class FirestoreShoppingRepository implements ShoppingRepository {
  static Future<bool> Function(ShoppingList list)? _createListOverrideForTest;
  static Future<bool> Function(ShoppingList list)? _updateListOverrideForTest;
  static Future<bool> Function(String id)? _deleteListOverrideForTest;
  static Future<bool> Function(String listId, String email)?
  _shareListOverrideForTest;

  const FirestoreShoppingRepository();

  @override
  Future<bool> createList(ShoppingList list) async {
    final override = _createListOverrideForTest;
    if (override != null) return override(list);

    final id = await FirestoreService.createList(list);
    return id != null;
  }

  @override
  Future<bool> updateList(ShoppingList list) {
    final override = _updateListOverrideForTest;
    if (override != null) return override(list);

    return FirestoreService.updateList(
      list.id,
      name: list.name,
      description: list.description,
      color: list.color,
    );
  }

  @override
  Future<bool> deleteList(String id) {
    final override = _deleteListOverrideForTest;
    if (override != null) return override(id);

    return FirestoreService.deleteList(id);
  }

  @override
  Stream<List<ShoppingList>> watchLists() {
    return FirestoreService.getUserLists();
  }

  @override
  Stream<ShoppingList?> watchList(String id) {
    return FirestoreService.getListById(id);
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) async {
    final id = await FirestoreService.addItemToList(listId, item);
    return id != null;
  }

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return FirestoreService.updateItemInList(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    return FirestoreService.deleteItemFromList(listId, itemId);
  }

  @override
  Future<bool> clearCompleted(String listId) {
    return FirestoreService.clearCompletedItems(listId);
  }

  @override
  Future<ShareResult> shareList(String listId, String email) async {
    try {
      final override = _shareListOverrideForTest;
      final success =
          override != null
              ? await override(listId, email)
              : await FirestoreService.shareListWithUser(listId, email);
      if (success) return const ShareResult.success();
      return const ShareResult.error('Failed to share list. Please try again.');
    } catch (error) {
      return ShareResult.error(_mapShareError(error, email));
    }
  }

  @override
  Future<bool> removeMember(String listId, String userId) {
    return FirestoreService.removeMemberFromList(listId, userId);
  }

  @override
  Future<void> sync() async {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  void disposeListStream(String id) {}

  @override
  Future<void> init() async {}

  @override
  void dispose() {}

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

  static String mapShareErrorForTest(Object error, String email) {
    return _mapShareError(error, email);
  }

  static String _mapShareError(Object error, String email) {
    if (error is UserNotFoundException) return _userNotFoundMessage(email);
    if (error is UserAlreadyMemberException) {
      return 'This user is already a member of this list.';
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('not found') ||
        errorString.contains('usernotfoundexception')) {
      return _userNotFoundMessage(email);
    }
    if (errorString.contains('already a member') ||
        errorString.contains('useralreadymemberexception')) {
      return 'This user is already a member of this list.';
    }

    return 'Unable to share list with $email.\n\nPlease make sure they have the app installed and try again.';
  }

  static String _userNotFoundMessage(String email) {
    return 'User with email $email not found.\n\nMake sure they have signed up for the app first, then try sharing again.';
  }
}
