import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_auth_service.dart';

class FirestoreServiceContext {
  const FirestoreServiceContext._();

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static bool get isFirebaseAvailable {
    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      final result = hasApps && authAvailable;
      return result;
    } on FirebaseException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static CollectionReference get usersCollection =>
      firestore.collection('users');

  static CollectionReference get listsCollection =>
      firestore.collection('lists');

  static String? get currentUserId => FirebaseAuthService.currentUser?.uid;
}
