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
      final userDoc =
          await FirestoreServiceContext.usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        await FirestoreServiceContext.usersCollection.doc(user.uid).set({
          'profile': {
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isAnonymous': user.isAnonymous,
          },
          'listIds': [],
          'sharedIds': [],
        });
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
