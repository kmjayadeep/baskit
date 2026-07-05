import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_errors.dart';
import 'firestore_permission_rules.dart';
import 'firestore_service_context.dart';
import 'permission_service.dart' show ListPermission;

class FirestoreMembersService {
  const FirestoreMembersService._();

  static Future<bool> removeMemberFromList(String listId, String userId) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      return await FirestoreServiceContext.firestore.runTransaction((
        transaction,
      ) async {
        final listRef = FirestoreServiceContext.listsCollection.doc(listId);
        final snapshot = await transaction.get(listRef);

        if (!snapshot.exists) {
          return false;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final members = data['members'] as Map<String, dynamic>? ?? {};

        if (ownerId == userId) {
          return false;
        }

        if (!members.containsKey(userId)) {
          return false;
        }

        if (!FirestorePermissionRules.canRemoveMember(
          data,
          currentUserId,
          userId,
        )) {
          return false;
        }

        transaction.update(listRef, {
          'members.$userId': FieldValue.delete(),
          'memberIds': FieldValue.arrayRemove([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_remove_member',
        e,
        stackTrace,
      );
      debugPrint('Firestore error removing member [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_remove_member',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error removing member from list: $e');
      return false;
    }
  }

  static Future<bool> hasListPermission(
    String listId,
    Object permission,
  ) async {
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
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final userMember = members[currentUserId] as Map<String, dynamic>?;

      if (userMember == null) {
        return false; // User is not a member
      }

      return FirestorePermissionRules.hasPermission(
        data,
        currentUserId,
        permission,
      );
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_check_permissions',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error checking permissions [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_check_permissions',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error checking permissions: $e');
      return false;
    }
  }

  static Future<bool> shareListWithUser(String listId, String email) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      // First, find the user by email
      final userQuery =
          await FirestoreServiceContext.usersCollection
              .where('profile.email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw UserNotFoundException(email);
      }

      final targetUserDoc = userQuery.docs.first;
      final targetUserId = targetUserDoc.id;
      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      final targetUserProfile =
          targetUserData['profile'] as Map<String, dynamic>? ?? {};
      final targetUserName =
          targetUserProfile['displayName'] as String? ??
          targetUserProfile['email'] as String? ??
          'Unknown User';
      final targetUserAvatarUrl = targetUserProfile['photoURL'] as String?;

      // Check if user is already a member
      final listDoc =
          await FirestoreServiceContext.listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        throw Exception('List not found');
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final members = listData['members'] as Map<String, dynamic>? ?? {};

      if (!FirestorePermissionRules.hasPermission(
        listData,
        currentUserId,
        ListPermission.share,
      )) {
        return false;
      }

      if (members.containsKey(targetUserId)) {
        throw UserAlreadyMemberException(targetUserName);
      }

      // Add user to the list members
      await FirestoreServiceContext.listsCollection.doc(listId).update({
        'members.$targetUserId': {
          'userId': targetUserId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'displayName': targetUserName,
          'email': email,
          'avatarUrl': targetUserAvatarUrl,
          'permissions': {
            'read': true,
            'write': true,
            'delete':
                true, // Members can delete items and clear completed items
            'share': true, // Members can share lists with others
          },
        },
        'memberIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on UserNotFoundException {
      rethrow;
    } on UserAlreadyMemberException {
      rethrow;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_share_list',
        e,
        stackTrace,
      );
      debugPrint('Error sharing list: $e');
      rethrow;
    }
  }
}
