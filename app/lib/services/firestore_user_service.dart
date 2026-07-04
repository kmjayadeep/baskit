import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_service.dart';
import 'firestore_core.dart';
import 'permission_service.dart' show ListPermission;

/// User profile and contact lookup operations for Firestore.
class FirestoreUserService {
  FirestoreUserService._();

  static final _core = FirestoreCore;

  /// Initialize user profile in Firestore
  static Future<void> initializeUserProfile() async {
    if (!_core.isFirebaseAvailable) return;

    final user = FirebaseAuthService.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _core.usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        await _core.usersCollection.doc(user.uid).set({
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
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error initializing user profile [${e.code}]: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error initializing user profile: $e');
    }
  }

  /// Get the user's default voice list for Alexa.
  static Future<String?> getDefaultVoiceListId() async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return null;
    }

    try {
      final userDoc =
          await _core.usersCollection.doc(_core.currentUserId!).get();
      final data = userDoc.data() as Map<String, dynamic>?;
      final voiceSettings = data?['voiceSettings'] as Map<String, dynamic>?;
      return voiceSettings?['defaultListId'] as String?;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error getting default voice list [${e.code}]: ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('Unexpected error getting default voice list: $e');
      return null;
    }
  }

  /// Set the user's default voice list for Alexa.
  static Future<bool> setDefaultVoiceListId(String listId) async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      final hasPermission = await FirestoreMemberService.hasListPermission(
        listId,
        ListPermission.write,
      );
      if (!hasPermission) return false;

      await _core.usersCollection.doc(_core.currentUserId!).set({
        'voiceSettings': {'defaultListId': listId},
      }, SetOptions(merge: true));
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error setting default voice list [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error setting default voice list: $e');
      return false;
    }
  }

  /// Clear the user's default voice list for Alexa.
  static Future<bool> clearDefaultVoiceListId() async {
    if (!_core.isFirebaseAvailable || _core.currentUserId == null) {
      return false;
    }

    try {
      await _core.usersCollection.doc(_core.currentUserId!).update({
        'voiceSettings.defaultListId': FieldValue.delete(),
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error clearing default voice list [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error clearing default voice list: $e');
      return false;
    }
  }
}
