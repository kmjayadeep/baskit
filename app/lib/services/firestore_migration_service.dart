import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_list_model.dart';
import 'firestore_core.dart';
import 'firestore_list_service.dart';

/// Migration helpers for moving local data to Firestore.
class FirestoreMigrationService {
  FirestoreMigrationService._();

  /// Migrate data from local storage to Firestore.
  static Future<void> migrateLocalData(List<ShoppingList> localLists) async {
    if (!FirestoreCore.isFirebaseAvailable || FirestoreCore.currentUserId == null) {
      return;
    }

    try {
      for (final list in localLists) {
        await FirestoreListService.createList(list);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore error migrating data [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error migrating local data: $e');
    }
  }
}
