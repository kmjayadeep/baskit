import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import 'firestore_item_crud_service.dart';
import 'firestore_list_crud_service.dart';
import 'firestore_members_service.dart';
import 'firestore_migration_service.dart';
import 'firestore_permission_rules.dart';
import 'firestore_service_context.dart';
import 'firestore_user_profile_service.dart';

export 'firestore_errors.dart';

class FirestoreService {
  static bool get isFirebaseAvailable =>
      FirestoreServiceContext.isFirebaseAvailable;

  static Future<void> enableOfflinePersistence() async {
    if (!isFirebaseAvailable) {
      return;
    }

    try {
      // Use the new Settings.persistenceEnabled instead of deprecated enablePersistence()
      FirestoreServiceContext.firestore.settings = const Settings(
        persistenceEnabled: true,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error enabling offline persistence [${e.code}]: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error enabling offline persistence: $e');
    }
  }

  @visibleForTesting
  static bool hasListPermissionInDataForTest(
    Map<String, dynamic> data,
    String userId,
    String permission,
  ) {
    return FirestorePermissionRules.hasPermission(data, userId, permission);
  }

  @visibleForTesting
  static bool canRemoveMemberForTest(
    Map<String, dynamic> data,
    String currentUserId,
    String targetUserId,
  ) {
    return FirestorePermissionRules.canRemoveMember(
      data,
      currentUserId,
      targetUserId,
    );
  }

  static Future<void> initializeUserProfile() {
    return FirestoreUserProfileService.initializeUserProfile();
  }

  static Future<String?> createList(ShoppingList list) {
    return FirestoreListCrudService.createList(list);
  }

  static Stream<List<ShoppingList>> getUserLists() {
    return FirestoreListCrudService.getUserLists();
  }

  static Stream<ShoppingList?> getListById(String listId) {
    return FirestoreListCrudService.getListById(listId);
  }

  static Future<bool> updateList(
    String listId, {
    String? name,
    String? description,
    String? color,
  }) {
    return FirestoreListCrudService.updateList(
      listId,
      name: name,
      description: description,
      color: color,
    );
  }

  static Future<bool> removeMemberFromList(String listId, String userId) {
    return FirestoreMembersService.removeMemberFromList(listId, userId);
  }

  static Future<bool> deleteList(String listId) {
    return FirestoreListCrudService.deleteList(listId);
  }

  static Future<bool> hasListPermission(String listId, Object permission) {
    return FirestoreMembersService.hasListPermission(listId, permission);
  }

  static Future<String?> getDefaultVoiceListId() {
    return FirestoreUserProfileService.getDefaultVoiceListId();
  }

  static Future<bool> setDefaultVoiceListId(String listId) {
    return FirestoreUserProfileService.setDefaultVoiceListId(listId);
  }

  static Future<bool> clearDefaultVoiceListId() {
    return FirestoreUserProfileService.clearDefaultVoiceListId();
  }

  static Future<String?> addItemToList(String listId, ShoppingItem item) {
    return FirestoreItemCrudService.addItemToList(listId, item);
  }

  static Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return FirestoreItemCrudService.updateItemInList(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  static Future<bool> deleteItemFromList(String listId, String itemId) {
    return FirestoreItemCrudService.deleteItemFromList(listId, itemId);
  }

  static Future<bool> clearCompletedItems(String listId) {
    return FirestoreItemCrudService.clearCompletedItems(listId);
  }

  static Stream<List<ShoppingItem>> getListItems(String listId) {
    return FirestoreItemCrudService.getListItems(listId);
  }

  static Future<void> migrateLocalData(List<ShoppingList> localLists) {
    return FirestoreMigrationService.migrateLocalData(localLists);
  }

  static Future<bool> shareListWithUser(String listId, String email) {
    return FirestoreMembersService.shareListWithUser(listId, email);
  }
}
