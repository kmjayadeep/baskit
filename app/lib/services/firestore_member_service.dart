import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_core.dart';
import 'firestore_errors.dart';
import 'firestore_permission_rules.dart';
import 'permission_service.dart' show ListPermission;

/// Members, sharing, and permissions operations for Firestore.
class FirestoreMemberService {
  FirestoreMemberService._();

  static final _core = FirestoreCore;

  /// Check if user has permission to perform action on list
  static Future<bool> hasListPermission(
    String listId,
    Object permission,
  ) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final listDoc = await _core.listsCollection.doc(listId).get();
      if (!listDoc.exists) return false;

      final data = listDoc.data() as Map<String, dynamic>;
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final userMember = members[_core.currentUserId] as Map<String, dynamic>?;

      if (userMember == null) return false;

      return FirestorePermissionRules.hasPermission(
        data,
        _core.currentUserId!,
        permission,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error checking permissions [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking permissions: $e');
      return false;
    }
  }

  /// Share list with user by email
  static Future<bool> shareListWithUser(String listId, String email) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final userQuery = await _core.usersCollection
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
      final targetUserName = targetUserProfile['displayName'] as String? ??
          targetUserProfile['email'] as String? ??
          'Unknown User';

      final listDoc = await _core.listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        throw Exception('List not found');
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final members = listData['members'] as Map<String, dynamic>? ?? {};

      if (!FirestorePermissionRules.hasPermission(
        listData,
        _core.currentUserId!,
        ListPermission.share,
      )) {
        return false;
      }

      if (members.containsKey(targetUserId)) {
        throw UserAlreadyMemberException(targetUserName);
      }

      await _core.listsCollection.doc(listId).update({
        'members.$targetUserId': {
          'userId': targetUserId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'displayName': targetUserName,
          'email': email,
          'permissions': {
            'read': true,
            'write': true,
            'delete': true,
            'share': true,
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
    } catch (e) {
      debugPrint('Error sharing list: $e');
      rethrow;
    }
  }

  /// Remove a member from a list
  static Future<bool> removeMemberFromList(String listId, String userId) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      return await _core.firestore.runTransaction((transaction) async {
        final listRef = _core.listsCollection.doc(listId);
        final snapshot = await transaction.get(listRef);

        if (!snapshot.exists) return false;

        final data = snapshot.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final members = data['members'] as Map<String, dynamic>? ?? {};

        if (ownerId == userId) return false;
        if (!members.containsKey(userId)) return false;

        if (!FirestorePermissionRules.canRemoveMember(
          data,
          _core.currentUserId!,
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
    } on FirebaseException catch (e) {
      debugPrint('Firestore error removing member [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error removing member from list: $e');
      return false;
    }
  }
}
