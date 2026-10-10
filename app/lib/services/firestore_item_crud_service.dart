import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_item_model.dart';
import 'firestore_mappers.dart';
import 'firestore_members_service.dart';
import 'firestore_service_context.dart';
import 'permission_service.dart' show ListPermission;

class FirestoreItemCrudService {
  const FirestoreItemCrudService._();

  /// Firestore write batches are limited to 500 operations. Keep commits
  /// below that limit (450 leaves headroom) so batched writes never fail with
  /// `FAILED_PRECONDITION`.
  static const int _firestoreBatchLimit = 450;

  static Future<String?> addItemToList(String listId, ShoppingItem item) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      debugPrint('❌ Firebase not available or no current user');
      return null;
    }

    try {
      // Check if user has write permission
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) {
        return null;
      }

      final docRef = await FirestoreServiceContext.listsCollection
          .doc(listId)
          .collection('items')
          .add({
            'name': item.name,
            'quantity': item.quantity,
            'completed': item.isCompleted,
            'listItemType': item.listItemType.name,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': currentUserId,
          });

      // Update list's updatedAt timestamp
      await FirestoreServiceContext.listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_add_item',
        e,
        stackTrace,
      );
      debugPrint('Firestore error adding item [${e.code}]: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_add_item',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error adding item to list: $e');
      return null;
    }
  }

  static Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
    dynamic listItemType,
    bool clearQuantity = false,
  }) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    // Check if user has write permission
    final hasPermission = await FirestoreMembersService.hasListPermission(
      listId,
      ListPermission.write,
    );
    if (!hasPermission) {
      return false;
    }

    return updateItemInListForUser(
      listId,
      itemId,
      firestore: FirestoreServiceContext.firestoreOverride,
      name: name,
      quantity: quantity,
      completed: completed,
      listItemType: listItemType,
      clearQuantity: clearQuantity,
    );
  }

  /// Update implementation with explicit dependencies for testability.
  @visibleForTesting
  static Future<bool> updateItemInListForUser(
    String listId,
    String itemId, {
    required FirebaseFirestore firestore,
    String? name,
    String? quantity,
    bool? completed,
    dynamic listItemType,
    bool clearQuantity = false,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (clearQuantity) {
        updateData['quantity'] = FieldValue.delete();
      } else if (quantity != null) {
        updateData['quantity'] = quantity;
      }
      if (completed != null) {
        updateData['completed'] = completed;
        // Handle completedAt timestamp
        if (completed) {
          // Item is being marked as completed - set completion timestamp
          updateData['completedAt'] = FieldValue.serverTimestamp();
        } else {
          // Item is being marked as incomplete - clear completion timestamp
          updateData['completedAt'] = FieldValue.delete();
        }
      }

      if (listItemType != null) {
        updateData['listItemType'] = listItemType is ItemType
            ? listItemType.name
            : listItemType;
      }

      await firestore
          .collection('lists')
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .update(updateData);

      // Update list's updatedAt timestamp
      await firestore.collection('lists').doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_update_item',
        e,
        stackTrace,
      );
      debugPrint('Firestore error updating item [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_update_item',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error updating item: $e');
      return false;
    }
  }

  static Future<bool> deleteItemFromList(String listId, String itemId) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete permission
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.deleteItems,
      );
      if (!hasPermission) {
        return false;
      }

      await FirestoreServiceContext.listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .delete();

      // Update list's updatedAt timestamp
      await FirestoreServiceContext.listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_delete_item',
        e,
        stackTrace,
      );
      debugPrint('Firestore error deleting item [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_delete_item',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error deleting item: $e');
      return false;
    }
  }

  static Future<bool> clearCompletedItems(String listId) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete permission
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.deleteItems,
      );
      if (!hasPermission) {
        return false;
      }

      // Get all completed items
      final completedItemsSnapshot = await FirestoreServiceContext
          .listsCollection
          .doc(listId)
          .collection('items')
          .where('completed', isEqualTo: true)
          .get();

      if (completedItemsSnapshot.docs.isEmpty) {
        return true; // No completed items to clear
      }

      // Delete completed items in chunked batches: a single batch is limited
      // to 500 operations, so one batch would fail when more than ~500
      // completed items are cleared at once. The list's updatedAt timestamp
      // is updated atomically with the first commit. Each chunk commits at the
      // end of its iteration, giving a single commit point and no empty
      // trailing commit once the last chunk is reached.
      var batch = FirestoreServiceContext.firestore.batch();
      var updatedAtSet = false;
      for (
        var index = 0;
        index < completedItemsSnapshot.docs.length;
        index += _firestoreBatchLimit
      ) {
        final chunk = completedItemsSnapshot.docs
            .skip(index)
            .take(_firestoreBatchLimit)
            .toList();
        for (final itemDoc in chunk) {
          batch.delete(itemDoc.reference);
        }
        if (!updatedAtSet) {
          batch.update(FirestoreServiceContext.listsCollection.doc(listId), {
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updatedAtSet = true;
        }
        await batch.commit();
        batch = FirestoreServiceContext.firestore.batch();
      }

      debugPrint(
        '✅ Successfully cleared ${completedItemsSnapshot.docs.length} completed items',
      );
      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_clear_completed_items',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error clearing completed items [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_clear_completed_items',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error clearing completed items: $e');
      return false;
    }
  }

  static Stream<List<ShoppingItem>> getListItems(String listId) {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return Stream.value([]);
    }

    return FirestoreServiceContext.listsCollection
        .doc(listId)
        .collection('items')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => FirestoreMappers.itemFromData(doc.id, doc.data()))
                .toList();
          } catch (e, stackTrace) {
            debugPrint('Firestore error parsing items for list $listId: $e');
            FirestoreServiceContext.recordNonFatal(
              'firestore_parse_items',
              e,
              stackTrace,
            );
            return [];
          }
        });
  }
}
