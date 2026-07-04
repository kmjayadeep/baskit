import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_core.dart';
import 'firestore_mappers.dart';
import 'firestore_permission_rules.dart';
import 'permission_service.dart' show ListPermission;

/// List CRUD operations for Firestore.
class FirestoreListService {
  FirestoreListService._();

  static final _core = FirestoreCore;

  /// Create a new shopping list
  static Future<String?> createList(ShoppingList list) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return null;
    }

    try {
      final docRef = await _core.listsCollection.add({
        'name': list.name,
        'description': list.description,
        'color': list.color,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': _core.currentUserId,
        'memberIds': [_core.currentUserId],
        'members': {
          _core.currentUserId!: {
            'userId': _core.currentUserId,
            'role': 'owner',
            'displayName': FirebaseAuthService.userDisplayName,
            'email': FirebaseAuthService.userEmail,
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

      if (list.items.isNotEmpty) {
        final batch = _core.firestore.batch();
        for (final item in list.items) {
          final itemRef = docRef.collection('items').doc();
          batch.set(itemRef, {
            'name': item.name,
            'quantity': item.quantity,
            'completed': item.isCompleted,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': _core.currentUserId,
          });
        }
        await batch.commit();
      }

      await _core.usersCollection.doc(_core.currentUserId!).update({
        'listIds': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error creating list [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error creating list in Firestore: $e');
      return null;
    }
  }

  /// Get all user lists (owned + shared)
  static Stream<List<ShoppingList>> getUserLists() {
    debugPrint('🔍 FirestoreService.getUserLists() called:');
    debugPrint('   - isFirebaseAvailable: ${_core.isFirebaseAvailable}');
    debugPrint('   - _currentUserId: ${_core.currentUserId}');

    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      debugPrint(
        '❌ Firebase not available or no user ID - returning empty stream',
      );
      return Stream.value([]);
    }

    debugPrint(
      '☁️ Querying Firebase for lists where memberIds contains: ${_core.currentUserId}',
    );

    return _core.listsCollection
        .where('memberIds', arrayContains: _core.currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          debugPrint(
            '📊 Firebase query returned ${snapshot.docs.length} documents',
          );

          if (snapshot.docs.isEmpty) {
            return <ShoppingList>[];
          }

          final List<Future<ShoppingList>> futures =
              snapshot.docs.map((doc) async {
                final data = doc.data() as Map<String, dynamic>;

                final itemsSnapshot = await doc.reference
                    .collection('items')
                    .orderBy('createdAt', descending: false)
                    .get();

                final items = itemsSnapshot.docs
                    .map((itemDoc) => FirestoreMappers.itemFromData(
                          itemDoc.id,
                          itemDoc.data(),
                        ))
                    .toList();

                return FirestoreMappers.listFromData(
                  id: doc.id,
                  data: data,
                  items: items,
                );
              }).toList();

          final lists = await Future.wait(futures);

          debugPrint(
            '✅ FirestoreService.getUserLists() returning ${lists.length} lists',
          );
          return lists;
        });
  }

  /// Get a specific list by ID
  static Stream<ShoppingList?> getListById(String listId) {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return Stream.value(null);
    }

    return _core.listsCollection.doc(listId).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      final memberIds = List<String>.from(data['memberIds'] ?? []);
      if (!memberIds.contains(_core.currentUserId)) {
        return null;
      }

      final itemsSnapshot = await doc.reference
          .collection('items')
          .orderBy('createdAt', descending: false)
          .get();

      final items = itemsSnapshot.docs
          .map((itemDoc) =>
              FirestoreMappers.itemFromData(itemDoc.id, itemDoc.data()))
          .toList();

      return FirestoreMappers.listFromData(
        id: doc.id,
        data: data,
        items: items,
      );
    });
  }

  /// Update list metadata
  static Future<bool> updateList(
    String listId, {
    String? name,
    String? description,
    String? color,
  }) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final listDoc = await _core.listsCollection.doc(listId).get();
      if (!listDoc.exists) return false;

      final data = listDoc.data() as Map<String, dynamic>;
      if (!FirestorePermissionRules.hasPermission(
        data,
        _core.currentUserId!,
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

      await _core.listsCollection.doc(listId).update(updateData);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error updating list [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error updating list: $e');
      return false;
    }
  }

  /// Delete a list and all its subcollections
  static Future<bool> deleteList(String listId) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.deleteList,
      );
      if (!hasPermission) {
        debugPrint('❌ User does not have permission to delete list: $listId');
        return false;
      }

      final batch = _core.firestore.batch();

      final itemsSnapshot = await _core.listsCollection
          .doc(listId)
          .collection('items')
          .get();

      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      batch.delete(_core.listsCollection.doc(listId));

      await batch.commit();

      await _core.usersCollection.doc(_core.currentUserId!).update({
        'listIds': FieldValue.arrayRemove([listId]),
      });

      debugPrint(
        '✅ Successfully deleted list and ${itemsSnapshot.docs.length} items',
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error deleting list [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error deleting list: $e');
      return false;
    }
  }
}
