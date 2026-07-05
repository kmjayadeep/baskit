import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_mappers.dart';
import 'firestore_members_service.dart';
import 'firestore_permission_rules.dart';
import 'firestore_service_context.dart';
import 'permission_service.dart' show ListPermission;

class FirestoreListCrudService {
  const FirestoreListCrudService._();

  static Future<String?> createList(ShoppingList list) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return null;
    }

    try {
      // Create the list document in global collection
      final docRef = await FirestoreServiceContext.listsCollection.add({
        'name': list.name,
        'description': list.description,
        'color': list.color,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': currentUserId,
        'memberIds': [currentUserId], // Array for efficient querying
        'members': {
          currentUserId: {
            'userId': currentUserId,
            'role': 'owner',
            'displayName': FirebaseAuthService.userDisplayName,
            'email': FirebaseAuthService.userEmail,
            'avatarUrl': FirebaseAuthService.userPhotoURL,
            'joinedAt': FieldValue.serverTimestamp(),
            'permissions': {
              'read': true,
              'write': true,
              'delete': true,
              'share': true,
            },
          },
        },
      });

      // Add items if any
      if (list.items.isNotEmpty) {
        final batch = FirestoreServiceContext.firestore.batch();
        for (final item in list.items) {
          final itemRef = docRef.collection('items').doc();
          batch.set(itemRef, _itemData(item, currentUserId));
        }
        await batch.commit();
      }

      // Update user's list IDs
      await FirestoreServiceContext.usersCollection.doc(currentUserId).update({
        'listIds': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_create_list',
        e,
        stackTrace,
      );
      debugPrint('Firestore error creating list [${e.code}]: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_create_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error creating list in Firestore: $e');
      return null;
    }
  }

  static Stream<List<ShoppingList>> getUserLists() {
    final currentUserId = FirestoreServiceContext.currentUserId;
    debugPrint('🔍 FirestoreService.getUserLists() called:');
    debugPrint(
      '   - isFirebaseAvailable: ${FirestoreServiceContext.isFirebaseAvailable}',
    );
    debugPrint('   - _currentUserId: $currentUserId');

    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      debugPrint(
        '❌ Firebase not available or no user ID - returning empty stream',
      );
      return Stream.value([]);
    }

    debugPrint(
      '☁️ Querying Firebase for lists where memberIds contains: $currentUserId',
    );

    // Query both owned and shared lists from global collection
    return FirestoreServiceContext.listsCollection
        .where('memberIds', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          debugPrint(
            '📊 Firebase query returned ${snapshot.docs.length} documents',
          );

          if (snapshot.docs.isEmpty) {
            return <ShoppingList>[];
          }

          // Use batch queries for better performance
          final List<Future<ShoppingList>> futures =
              snapshot.docs.map((doc) async {
                final data = doc.data() as Map<String, dynamic>;

                final itemsSnapshot =
                    await doc.reference
                        .collection('items')
                        .orderBy('createdAt', descending: false)
                        .get();

                final items = _itemsFromSnapshot(itemsSnapshot);

                return FirestoreMappers.listFromData(
                  id: doc.id,
                  data: data,
                  items: items,
                );
              }).toList();

          // Wait for all lists to be processed in parallel
          final lists = await Future.wait(futures);

          debugPrint(
            '✅ FirestoreService.getUserLists() returning ${lists.length} lists',
          );
          return lists;
        });
  }

  static Stream<ShoppingList?> getListById(String listId) {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return Stream.value(null);
    }

    return FirestoreServiceContext.listsCollection
        .doc(listId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) {
            return null;
          }

          final data = doc.data() as Map<String, dynamic>;

          // Check if user has access to this list
          final memberIds = List<String>.from(data['memberIds'] ?? []);
          if (!memberIds.contains(currentUserId)) {
            return null; // User doesn't have access
          }

          final itemsSnapshot =
              await doc.reference
                  .collection('items')
                  .orderBy('createdAt', descending: false)
                  .get();

          final items = _itemsFromSnapshot(itemsSnapshot);

          return FirestoreMappers.listFromData(
            id: doc.id,
            data: data,
            items: items,
          );
        });
  }

  static Future<bool> updateList(
    String listId, {
    String? name,
    String? description,
    String? color,
  }) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      final listDoc =
          await FirestoreServiceContext.listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        return false;
      }

      final data = listDoc.data() as Map<String, dynamic>;
      if (!FirestorePermissionRules.hasPermission(
        data,
        currentUserId,
        ListPermission.write,
      )) {
        return false;
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (color != null) updateData['color'] = color;

      await FirestoreServiceContext.listsCollection
          .doc(listId)
          .update(updateData);
      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_update_list',
        e,
        stackTrace,
      );
      debugPrint('Firestore error updating list [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_update_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error updating list: $e');
      return false;
    }
  }

  static Future<bool> deleteList(String listId) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete-list permission (owner only)
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.deleteList,
      );
      if (!hasPermission) {
        debugPrint('❌ User does not have permission to delete list: $listId');
        return false;
      }

      // Use batch to ensure atomicity
      final batch = FirestoreServiceContext.firestore.batch();

      // First, get all items in the subcollection
      final itemsSnapshot =
          await FirestoreServiceContext.listsCollection
              .doc(listId)
              .collection('items')
              .get();

      // Add all item deletions to the batch
      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      // Delete the main list document
      batch.delete(FirestoreServiceContext.listsCollection.doc(listId));

      // Commit all deletions atomically
      await batch.commit();

      // Remove from user's list IDs after successful deletion
      await FirestoreServiceContext.usersCollection.doc(currentUserId).update({
        'listIds': FieldValue.arrayRemove([listId]),
      });

      debugPrint(
        '✅ Successfully deleted list and ${itemsSnapshot.docs.length} items',
      );
      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_delete_list',
        e,
        stackTrace,
      );
      debugPrint('Firestore error deleting list [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_delete_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error deleting list: $e');
      return false;
    }
  }

  static Map<String, dynamic> _itemData(
    ShoppingItem item,
    String currentUserId,
  ) {
    return {
      'name': item.name,
      'quantity': item.quantity,
      'completed': item.isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    };
  }

  static List<ShoppingItem> _itemsFromSnapshot(QuerySnapshot itemsSnapshot) {
    return itemsSnapshot.docs
        .map(
          (itemDoc) => FirestoreMappers.itemFromData(
            itemDoc.id,
            itemDoc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
