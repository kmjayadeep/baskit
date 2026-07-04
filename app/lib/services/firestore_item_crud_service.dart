import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_item_model.dart';
import 'firestore_mappers.dart';
import 'firestore_members_service.dart';
import 'firestore_service_context.dart';
import 'permission_service.dart' show ListPermission;

class FirestoreItemCrudService {
  const FirestoreItemCrudService._();

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
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': currentUserId,
          });

      // Update list's updatedAt timestamp
      await FirestoreServiceContext.listsCollection.doc(listId).update({
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

  static Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      // Check if user has write permission
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) {
        return false;
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (quantity != null) updateData['quantity'] = quantity;
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

      await FirestoreServiceContext.listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .update(updateData);

      // Update list's updatedAt timestamp
      await FirestoreServiceContext.listsCollection.doc(listId).update({
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
    } on FirebaseException catch (e) {
      debugPrint('Firestore error deleting item [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
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
      final completedItemsSnapshot =
          await FirestoreServiceContext.listsCollection
              .doc(listId)
              .collection('items')
              .where('completed', isEqualTo: true)
              .get();

      if (completedItemsSnapshot.docs.isEmpty) {
        return true; // No completed items to clear
      }

      // Use batch to delete all completed items atomically
      final batch = FirestoreServiceContext.firestore.batch();

      for (final itemDoc in completedItemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      // Update list's updatedAt timestamp
      batch.update(FirestoreServiceContext.listsCollection.doc(listId), {
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
          return snapshot.docs
              .map((doc) => FirestoreMappers.itemFromData(doc.id, doc.data()))
              .toList();
        });
  }
}
