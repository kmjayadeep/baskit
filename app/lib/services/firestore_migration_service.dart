import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shopping_list_model.dart';
import 'firestore_list_crud_service.dart';
import 'firestore_service_context.dart';

class FirestoreMigrationService {
  const FirestoreMigrationService._();

  static Future<void> migrateLocalData(List<ShoppingList> localLists) async {
    if (!FirestoreServiceContext.isFirebaseAvailable ||
        FirestoreServiceContext.currentUserId == null) {
      return;
    }

    try {
      for (final list in localLists) {
        await FirestoreListCrudService.createList(list);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore error migrating data [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error migrating local data: $e');
    }
  }
}
