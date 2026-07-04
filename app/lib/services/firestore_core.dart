import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_auth_service.dart';

/// Shared state and utilities used by all Firestore service modules.
///
/// This module is internal to the firestore service family and should not be
/// imported directly by consumers. Use [FirestoreService] instead.
class FirestoreCore {
  FirestoreCore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      return hasApps && authAvailable;
    } on FirebaseException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Enable offline persistence
  static Future<void> enableOfflinePersistence() async {
    if (!isFirebaseAvailable) return;

    try {
      _firestore.settings = const Settings(persistenceEnabled: true);
    } on FirebaseException catch (e) {
      // Silently fail; persistence is best-effort
    } catch (e) {
      // Silently fail
    }
  }

  /// Users collection reference
  static CollectionReference get usersCollection =>
      _firestore.collection('users');

  /// Global lists collection (for sharing support)
  static CollectionReference get listsCollection =>
      _firestore.collection('lists');

  /// Current authenticated user ID
  static String? get currentUserId => FirebaseAuthService.currentUser?.uid;

  /// Firestore instance (for transactions/batches)
  static FirebaseFirestore get firestore => _firestore;
}
