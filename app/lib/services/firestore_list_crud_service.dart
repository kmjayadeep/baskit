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

  /// Firestore write batches are limited to 500 operations. Keep commits
  /// below that limit (450 leaves headroom) so batched writes never fail with
  /// `FAILED_PRECONDITION`.
  static const int _firestoreBatchLimit = 450;

  static Future<String?> createList(ShoppingList list) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return null;
    }

    return createListForUser(
      list,
      firestore: FirestoreServiceContext.firestore,
      userId: currentUserId,
      displayName: FirebaseAuthService.userDisplayName,
      email: FirebaseAuthService.userEmail,
      avatarUrl: FirebaseAuthService.userPhotoURL,
    );
  }

  /// Upload implementation with explicit dependencies for retry testing.
  @visibleForTesting
  static Future<String?> createListForUser(
    ShoppingList list, {
    required FirebaseFirestore firestore,
    required String userId,
    required String displayName,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      // Use the local UUID as the cloud ID so a failed/partial migration can
      // retry without creating another list. Never overwrite another owner.
      final docRef = firestore.collection('lists').doc(list.id);
      DocumentSnapshot? existing;
      try {
        existing = await docRef.get();
      } on FirebaseException catch (error) {
        // Some Firestore rules do not permit reading a document that has not
        // been created yet. The following set still needs create permission.
        if (error.code != 'permission-denied') rethrow;
      }
      if (existing != null &&
          existing.exists &&
          (existing.data() as Map<String, dynamic>)['ownerId'] != userId) {
        return null;
      }
      final isNewList = existing == null || !existing.exists;
      if (isNewList) {
        await docRef.set({
          'name': list.name,
          'description': list.description,
          'color': list.color,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'ownerId': userId,
          'memberIds': [userId], // Array for efficient querying
          'members': {
            userId: {
              'userId': userId,
              'role': 'owner',
              'displayName': displayName,
              'email': email,
              'avatarUrl': avatarUrl,
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
      }

      // If a previous attempt created the list but stopped mid-upload, only
      // upload missing items. Do not replace items edited in the cloud since.
      // Keep batches below Firestore's write limit.
      var batch = firestore.batch();
      var pending = 0;
      for (final item in list.items) {
        final itemRef = docRef.collection('items').doc(item.id);
        if (!isNewList && (await itemRef.get()).exists) continue;
        batch.set(itemRef, _itemData(item, userId));
        if (++pending == _firestoreBatchLimit) {
          await batch.commit();
          batch = firestore.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit();

      // Update user's list IDs
      await firestore.collection('users').doc(userId).update({
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

    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return Stream.value([]);
    }

    // Query both owned and shared lists from global collection
    return FirestoreServiceContext.listsCollection
        .where('memberIds', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return <ShoppingList>[];
          }

          final avatarUrls = await _avatarUrlsForMemberProfiles(
            snapshot.docs.expand(
              (doc) => _memberIdsFromData(doc.data() as Map<String, dynamic>),
            ),
          );

          // Use batch queries for better performance
          final List<Future<ShoppingList>> futures = snapshot.docs.map((
            doc,
          ) async {
            final data = _dataWithMemberAvatars(
              doc.data() as Map<String, dynamic>,
              avatarUrls,
            );

            final itemsSnapshot = await doc.reference
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

          var data = doc.data() as Map<String, dynamic>;

          // Check if user has access to this list
          final memberIds = List<String>.from(data['memberIds'] ?? []);
          if (!memberIds.contains(currentUserId)) {
            return null; // User doesn't have access
          }

          final itemsSnapshot = await doc.reference
              .collection('items')
              .orderBy('createdAt', descending: false)
              .get();

          final items = _itemsFromSnapshot(itemsSnapshot);
          final avatarUrls = await _avatarUrlsForMemberProfiles(
            _memberIdsFromData(data),
          );
          data = _dataWithMemberAvatars(data, avatarUrls);

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
      final listDoc = await FirestoreServiceContext.listsCollection
          .doc(listId)
          .get();
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

      // Use batches to delete (chunks required below; see loop).
      var batch = FirestoreServiceContext.firestore.batch();

      // First, get all items in the subcollection
      final itemsSnapshot = await FirestoreServiceContext.listsCollection
          .doc(listId)
          .collection('items')
          .get();

      // Delete the main list document, then remove items in chunked batches.
      // A single Firestore batch is limited to 500 operations, so one batch
      // per list would fail for lists with more than ~500 items. Each chunk
      // commits at the end of its iteration, so there is a single commit point
      // and no empty trailing commit once the last chunk is reached.
      batch.delete(FirestoreServiceContext.listsCollection.doc(listId));

      for (
        var index = 0;
        index < itemsSnapshot.docs.length;
        index += _firestoreBatchLimit
      ) {
        final chunk = itemsSnapshot.docs
            .skip(index)
            .take(_firestoreBatchLimit)
            .toList();
        for (final itemDoc in chunk) {
          batch.delete(itemDoc.reference);
        }
        await batch.commit();
        batch = FirestoreServiceContext.firestore.batch();
      }

      // Remove from user's list IDs after successful deletion.
      // This is best-effort: if it fails the document is already gone,
      // so the stale listId will be cleaned up on the next getUserLists call
      // (which rebuilds memberIds from the document members map).
      try {
        await FirestoreServiceContext.usersCollection.doc(currentUserId).update(
          {
            'listIds': FieldValue.arrayRemove([listId]),
          },
        );
      } catch (e, stackTrace) {
        FirestoreServiceContext.recordNonFatal(
          'firestore_delete_list_user_update',
          e,
          stackTrace,
        );
        debugPrint(
          '⚠️ Failed to remove listId $listId from user $currentUserId after '
          'successful batch delete: $e',
        );
      }

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
      'listItemType': item.listItemType.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    };
  }

  static Iterable<String> _memberIdsFromData(Map<String, dynamic> data) {
    final members = data['members'] as Map<String, dynamic>? ?? {};
    if (members.isNotEmpty) {
      return members.keys;
    }

    return List<String>.from(data['memberIds'] as List? ?? []);
  }

  static Future<Map<String, String>> _avatarUrlsForMemberProfiles(
    Iterable<String> memberIds,
  ) async {
    final uniqueIds = memberIds.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) {
      return const {};
    }

    final avatarUrls = <String, String>{};
    for (var index = 0; index < uniqueIds.length; index += 10) {
      final chunk = uniqueIds.skip(index).take(10).toList();
      final snapshot = await FirestoreServiceContext.usersCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .limit(10)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final photoUrl = (profile['photoURL'] as String?)?.trim();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          avatarUrls[doc.id] = photoUrl;
        }
      }
    }

    return avatarUrls;
  }

  static Map<String, dynamic> _dataWithMemberAvatars(
    Map<String, dynamic> data,
    Map<String, String> avatarUrls,
  ) {
    if (avatarUrls.isEmpty) {
      return data;
    }

    final members = data['members'] as Map<String, dynamic>?;
    if (members == null || members.isEmpty) {
      return data;
    }

    final enrichedMembers = <String, dynamic>{};
    for (final entry in members.entries) {
      final memberData = entry.value;
      if (memberData is! Map<String, dynamic>) {
        enrichedMembers[entry.key] = memberData;
        continue;
      }

      final enrichedMember = Map<String, dynamic>.from(memberData);
      final existingAvatarUrl = (enrichedMember['avatarUrl'] as String?)
          ?.trim();
      final profileAvatarUrl = avatarUrls[entry.key];
      if ((existingAvatarUrl == null || existingAvatarUrl.isEmpty) &&
          profileAvatarUrl != null) {
        enrichedMember['avatarUrl'] = profileAvatarUrl;
      }
      enrichedMembers[entry.key] = enrichedMember;
    }

    return {...data, 'members': enrichedMembers};
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
