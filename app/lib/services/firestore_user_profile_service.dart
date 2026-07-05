import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_service.dart';
import 'firestore_members_service.dart';
import 'firestore_service_context.dart';
import 'permission_service.dart' show ListPermission;

class FirestoreUserProfileService {
  const FirestoreUserProfileService._();

  static Future<void> initializeUserProfile() async {
    if (!FirestoreServiceContext.isFirebaseAvailable) {
      return;
    }

    final user = FirebaseAuthService.currentUser;
    if (user == null) return;

    try {
      final userRef = FirestoreServiceContext.usersCollection.doc(user.uid);
      final userDoc = await userRef.get();
      final profileData = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isAnonymous': user.isAnonymous,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userDoc.exists) {
        await userRef.set({
          'profile': {
            ...profileData,
            'createdAt': FieldValue.serverTimestamp(),
          },
          'listIds': [],
          'sharedIds': [],
        });
      } else {
        await userRef.set({'profile': profileData}, SetOptions(merge: true));
      }

      try {
        await _syncCurrentUserMembershipProfile(
          userId: user.uid,
          displayName: user.displayName,
          email: user.email,
          avatarUrl: user.photoURL,
        );
      } catch (e, stackTrace) {
        FirestoreServiceContext.recordNonFatal(
          'firestore_sync_member_profile',
          e,
          stackTrace,
        );
        debugPrint('Unable to sync member profile fields: $e');
      }
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_initialize_user_profile',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error initializing user profile [${e.code}]: ${e.message}',
      );
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_initialize_user_profile',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error initializing user profile: $e');
    }
  }

  static Future<void> _syncCurrentUserMembershipProfile({
    required String userId,
    required String? displayName,
    required String? email,
    required String? avatarUrl,
  }) async {
    final normalizedAvatarUrl = avatarUrl?.trim();
    final normalizedDisplayName = displayName?.trim();
    final normalizedEmail = email?.trim();

    if ((normalizedAvatarUrl == null || normalizedAvatarUrl.isEmpty) &&
        (normalizedDisplayName == null || normalizedDisplayName.isEmpty) &&
        (normalizedEmail == null || normalizedEmail.isEmpty)) {
      return;
    }

    final listsSnapshot =
        await FirestoreServiceContext.listsCollection
            .where('memberIds', arrayContains: userId)
            .get();

    var batch = FirestoreServiceContext.firestore.batch();
    var writeCount = 0;
    var hasPendingWrites = false;

    for (final doc in listsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final memberData = members[userId];
      if (memberData is! Map<String, dynamic>) {
        continue;
      }

      final updatedMember = updatedMemberProfileData(
        memberData,
        displayName: normalizedDisplayName,
        email: normalizedEmail,
        avatarUrl: normalizedAvatarUrl,
      );
      if (updatedMember == null) {
        continue;
      }

      if (writeCount == 450) {
        await batch.commit();
        batch = FirestoreServiceContext.firestore.batch();
        writeCount = 0;
        hasPendingWrites = false;
      }

      batch.set(doc.reference, {
        'members': {userId: updatedMember},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      writeCount++;
      hasPendingWrites = true;
    }

    if (hasPendingWrites) {
      await batch.commit();
    }
  }

  @visibleForTesting
  static Map<String, dynamic>? updatedMemberProfileData(
    Map<String, dynamic> memberData, {
    required String? displayName,
    required String? email,
    required String? avatarUrl,
  }) {
    final updatedMember = Map<String, dynamic>.from(memberData);
    var memberChanged = false;

    final existingAvatarUrl = (updatedMember['avatarUrl'] as String?)?.trim();
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        existingAvatarUrl != avatarUrl) {
      updatedMember['avatarUrl'] = avatarUrl;
      memberChanged = true;
    }

    final existingDisplayName =
        (updatedMember['displayName'] as String?)?.trim();
    if (displayName != null &&
        displayName.isNotEmpty &&
        (existingDisplayName == null ||
            existingDisplayName.isEmpty ||
            existingDisplayName == 'Unknown User')) {
      updatedMember['displayName'] = displayName;
      memberChanged = true;
    }

    final existingEmail = (updatedMember['email'] as String?)?.trim();
    if (email != null &&
        email.isNotEmpty &&
        (existingEmail == null || existingEmail.isEmpty)) {
      updatedMember['email'] = email;
      memberChanged = true;
    }

    return memberChanged ? updatedMember : null;
  }

  static Future<String?> getDefaultVoiceListId() async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return null;
    }

    try {
      final userDoc =
          await FirestoreServiceContext.usersCollection
              .doc(currentUserId)
              .get();
      final data = userDoc.data() as Map<String, dynamic>?;
      final voiceSettings = data?['voiceSettings'] as Map<String, dynamic>?;
      return voiceSettings?['defaultListId'] as String?;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_get_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error getting default voice list [${e.code}]: ${e.message}',
      );
      return null;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_get_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error getting default voice list: $e');
      return null;
    }
  }

  static Future<bool> setDefaultVoiceListId(String listId) async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMembersService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) {
        return false;
      }

      await FirestoreServiceContext.usersCollection.doc(currentUserId).set({
        'voiceSettings': {'defaultListId': listId},
      }, SetOptions(merge: true));
      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_set_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error setting default voice list [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_set_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error setting default voice list: $e');
      return false;
    }
  }

  static Future<bool> clearDefaultVoiceListId() async {
    final currentUserId = FirestoreServiceContext.currentUserId;
    if (!FirestoreServiceContext.isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    try {
      await FirestoreServiceContext.usersCollection.doc(currentUserId).update({
        'voiceSettings.defaultListId': FieldValue.delete(),
      });
      return true;
    } on FirebaseException catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_clear_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint(
        'Firestore error clearing default voice list [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e, stackTrace) {
      FirestoreServiceContext.recordNonFatal(
        'firestore_clear_default_voice_list',
        e,
        stackTrace,
      );
      debugPrint('Unexpected error clearing default voice list: $e');
      return false;
    }
  }
}
