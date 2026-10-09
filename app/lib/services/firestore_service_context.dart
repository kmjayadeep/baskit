import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporting_service.dart';
import 'firebase_auth_service.dart';

class FirestoreServiceContext {
  const FirestoreServiceContext._();

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @visibleForTesting
  static FirebaseFirestore? testFirestore;
  static FirebaseFirestore get firestoreOverride => testFirestore ?? firestore;

  @visibleForTesting
  static bool? testIsFirebaseAvailableOverride;
  static bool get isFirebaseAvailable {
    final override = testIsFirebaseAvailableOverride;
    if (override != null) return override;
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

  @visibleForTesting
  static String? testCurrentUserIdOverride;
  static String? get currentUserId =>
      testCurrentUserIdOverride ?? FirebaseAuthService.currentUser?.uid;

  static CollectionReference get usersCollection =>
      firestore.collection('users');

  static CollectionReference get listsCollection =>
      firestoreOverride.collection('lists');

  static void resetTestOverrides() {
    testFirestore = null;
    testIsFirebaseAvailableOverride = null;
    testCurrentUserIdOverride = null;
  }

  static void recordNonFatal(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    unawaited(
      CrashReportingService.recordNonFatal(
        context: context,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
