import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'firebase_auth_service.dart';

/// Custom exceptions for FirestoreLayer operations
class FirestoreLayerException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  FirestoreLayerException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'FirestoreLayerException: $message';
}

/// Low-level abstraction layer for Firestore operations
/// Handles DocumentSnapshot conversion, basic error handling, and direct Firebase operations
class FirestoreLayer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get _listsCollection =>
      _firestore.collection('lists');

  // Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      return hasApps && authAvailable;
    } catch (e) {
      return false;
    }
  }

  // Get current user ID
  static String? get currentUserId => FirebaseAuthService.currentUser?.uid;

  /// Convert Firestore DocumentSnapshot to ShoppingList
  static Future<ShoppingList> documentToShoppingList(
    DocumentSnapshot doc,
  ) async {
    try {
      if (!doc.exists) {
        throw FirestoreLayerException('Document does not exist: ${doc.id}');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Get member names for display (excluding current user)
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final memberNames =
          members.values
              .where(
                (member) =>
                    member is Map<String, dynamic> &&
                    member['userId'] != currentUserId,
              )
              .map(
                (member) =>
                    member['displayName'] as String? ??
                    member['email'] as String? ??
                    'Unknown',
              )
              .toList()
              .cast<String>();

      // Get items for this list
      final items = await _getItemsForList(doc.reference);

      return ShoppingList(
        id: doc.id,
        name: data['name'] ?? 'Unnamed List',
        description: data['description'] ?? '',
        color: data['color'] ?? '#2196F3',
        createdAt: _timestampToDateTime(data['createdAt']),
        updatedAt: _timestampToDateTime(data['updatedAt']),
        items: items,
        members: memberNames,
      );
    } catch (e) {
      throw FirestoreLayerException(
        'Failed to convert document to ShoppingList: ${doc.id}',
        originalError: e,
      );
    }
  }

  /// Convert Firestore DocumentSnapshot to ShoppingItem
  static ShoppingItem documentToShoppingItem(DocumentSnapshot doc) {
    try {
      if (!doc.exists) {
        throw FirestoreLayerException('Document does not exist: ${doc.id}');
      }

      final data = doc.data() as Map<String, dynamic>;

      return ShoppingItem(
        id: doc.id,
        name: data['name'] ?? '',
        quantity: data['quantity']?.toString(),
        isCompleted: data['completed'] ?? false,
        createdAt: _timestampToDateTime(data['createdAt']),
        completedAt: _timestampToDateTime(data['completedAt']),
      );
    } catch (e) {
      throw FirestoreLayerException(
        'Failed to convert document to ShoppingItem: ${doc.id}',
        originalError: e,
      );
    }
  }

  /// Get items for a list document reference
  static Future<List<ShoppingItem>> _getItemsForList(
    DocumentReference listRef,
  ) async {
    try {
      final itemsSnapshot =
          await listRef
              .collection('items')
              .orderBy('createdAt', descending: false)
              .get();

      return itemsSnapshot.docs
          .map((itemDoc) => documentToShoppingItem(itemDoc))
          .toList();
    } catch (e) {
      throw FirestoreLayerException(
        'Failed to get items for list: ${listRef.id}',
        originalError: e,
      );
    }
  }

  /// Convert Firestore Timestamp to DateTime with fallback
  static DateTime _timestampToDateTime(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    }
    return DateTime.now(); // Fallback for missing timestamps
  }

  /// Validate user access to a list document
  static bool validateUserAccess(DocumentSnapshot doc, String userId) {
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final memberIds = List<String>.from(data['memberIds'] ?? []);
    return memberIds.contains(userId);
  }

  /// Execute query with error handling and user validation
  static Stream<List<ShoppingList>> executeListsQuery({
    required String userId,
  }) {
    if (!isFirebaseAvailable) {
      debugPrint('❌ Firebase not available - returning empty stream');
      return Stream.value([]);
    }

    try {
      return _listsCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            debugPrint(
              '📊 Firebase query returned ${snapshot.docs.length} documents',
            );

            if (snapshot.docs.isEmpty) {
              return <ShoppingList>[];
            }

            // Convert documents to ShoppingList objects in parallel
            final futures =
                snapshot.docs
                    .map((doc) => documentToShoppingList(doc))
                    .toList();

            final lists = await Future.wait(futures);
            debugPrint('✅ FirestoreLayer returning ${lists.length} lists');
            return lists;
          });
    } catch (e) {
      debugPrint('❌ Error in executeListsQuery: $e');
      return Stream.error(
        FirestoreLayerException(
          'Failed to execute lists query',
          originalError: e,
        ),
      );
    }
  }

  /// Execute single list query with error handling
  static Stream<ShoppingList?> executeListQuery({
    required String listId,
    required String userId,
  }) {
    if (!isFirebaseAvailable) {
      return Stream.value(null);
    }

    try {
      return _listsCollection.doc(listId).snapshots().asyncMap((doc) async {
        if (!doc.exists) {
          return null;
        }

        // Validate user access
        if (!validateUserAccess(doc, userId)) {
          return null;
        }

        return await documentToShoppingList(doc);
      });
    } catch (e) {
      debugPrint('❌ Error in executeListQuery: $e');
      return Stream.error(
        FirestoreLayerException(
          'Failed to execute list query for: $listId',
          originalError: e,
        ),
      );
    }
  }

  /// Execute items query for a specific list
  static Stream<List<ShoppingItem>> executeItemsQuery({
    required String listId,
  }) {
    if (!isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      return _listsCollection
          .doc(listId)
          .collection('items')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => documentToShoppingItem(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error in executeItemsQuery: $e');
      return Stream.error(
        FirestoreLayerException(
          'Failed to execute items query for: $listId',
          originalError: e,
        ),
      );
    }
  }
}
