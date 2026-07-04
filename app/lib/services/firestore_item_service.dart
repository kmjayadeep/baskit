import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_item_model.dart';
import 'firestore_core.dart';
import 'firestore_mappers.dart';
import 'permission_service.dart' show ListPermission;

/// Item CRUD operations for Firestore.
class FirestoreItemService {
  FirestoreItemService._();

  static final _core = FirestoreCore;

  /// Add item to list
  static Future<String?> addItemToList(String listId, ShoppingItem item) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      debugPrint('❌ Firebase not available or no current user');
      return null;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) return null;

      final docRef = await _core.listsCollection
          .doc(listId)
          .collection('items')
          .add({
            'name': item.name,
            'quantity': item.quantity,
            'completed': item.isCompleted,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': _core.currentUserId,
          });

      await _core.listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error adding item [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error adding item to list: $e');
      return null;
    }
  }

  /// Update item in list (with permission check)
  static Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) return false;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (quantity != null) updateData['quantity'] = quantity;
      if (completed != null) {
        updateData['completed'] = completed;
        if (completed) {
          updateData['completedAt'] = FieldValue.serverTimestamp();
        } else {
          updateData['completedAt'] = FieldValue.delete();
        }
      }

      await _core.listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .update(updateData);

      await _core.listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error updating item [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error updating item: $e');
      return false;
    }
  }

  /// Delete item from list (with permission check)
  static Future<bool> deleteItemFromList(String listId, String itemId) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.deleteItems,
      );
      if (!hasPermission) return false;

      await _core.listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .delete();

      await _core.listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error deleting item [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error deleting item: $e');
      return false;
    }
  }

  /// Clear completed items from list (with permission check)
  static Future<bool> clearCompletedItems(String listId) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.deleteItems,
      );
      if (!hasPermission) return false;

      final completedItemsSnapshot = await _core.listsCollection
          .doc(listId)
          .collection('items')
          .where('completed', isEqualTo: true)
          .get();

      if (completedItemsSnapshot.docs.isEmpty) {
        return true;
      }

      final batch = _core.firestore.batch();

      for (final itemDoc in completedItemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      batch.update(_core.listsCollection.doc(listId), {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint(
        '✅ Successfully cleared ${completedItemsSnapshot.docs.length} completed items',
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error clearing completed items [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error clearing completed items: $e');
      return false;
    }
  }

  /// Get items stream for a list
  static Stream<List<ShoppingItem>> getListItems(String listId) {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return Stream.value([]);
    }

    return _core.listsCollection
        .doc(listId)
        .collection('items')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FirestoreMappers.itemFromData(doc.id, doc.data()))
              .toList();
        });
  }
}
