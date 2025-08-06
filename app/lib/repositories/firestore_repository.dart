import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../services/firebase_auth_service.dart';

/// Custom exceptions for Firestore repository operations
class FirestoreRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  FirestoreRepositoryException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'FirestoreRepositoryException: $message';
}

/// Low-level data access layer for Firestore operations
///
/// This repository handles:
/// - Direct Firestore document/collection access
/// - DocumentSnapshot to model conversion
/// - Basic query execution with error handling
/// - User access validation
///
/// Does NOT handle:
/// - Business logic or permissions beyond basic user access
/// - Complex operations like sharing or user management
/// - Authentication logic (delegates to FirebaseAuthService)
class FirestoreRepository {
  final FirebaseFirestore _firestore;
  final bool _isTestMode;

  /// Constructor for dependency injection (mainly for testing)
  FirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _isTestMode = firestore != null;

  // Collection references
  CollectionReference get _listsCollection => _firestore.collection('lists');

  /// Check if Firebase is available for operations
  bool get isFirebaseAvailable {
    if (_isTestMode) return true;

    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      return hasApps && authAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get current authenticated user ID
  String? get currentUserId {
    if (_isTestMode) return null; // Tests provide userId explicitly
    return FirebaseAuthService.currentUser?.uid;
  }

  // ==========================================
  // DOCUMENT CONVERSION METHODS
  // ==========================================

  /// Convert Firestore DocumentSnapshot to ShoppingList model
  Future<ShoppingList> documentToShoppingList(DocumentSnapshot doc) async {
    try {
      if (!doc.exists) {
        throw FirestoreRepositoryException(
          'Document does not exist: ${doc.id}',
        );
      }

      final data = doc.data() as Map<String, dynamic>;

      // Extract member display names (excluding current user)
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
      throw FirestoreRepositoryException(
        'Failed to convert document to ShoppingList: ${doc.id}',
        originalError: e,
      );
    }
  }

  /// Convert Firestore DocumentSnapshot to ShoppingItem model
  ShoppingItem documentToShoppingItem(DocumentSnapshot doc) {
    try {
      if (!doc.exists) {
        throw FirestoreRepositoryException(
          'Document does not exist: ${doc.id}',
        );
      }

      final data = doc.data() as Map<String, dynamic>;

      return ShoppingItem(
        id: doc.id,
        name: data['name'] ?? '',
        quantity: data['quantity']?.toString(),
        isCompleted: data['completed'] ?? false,
        createdAt: _timestampToDateTime(data['createdAt']),
        completedAt:
            data['completedAt'] != null
                ? _timestampToDateTime(data['completedAt'])
                : null,
      );
    } catch (e) {
      throw FirestoreRepositoryException(
        'Failed to convert document to ShoppingItem: ${doc.id}',
        originalError: e,
      );
    }
  }

  // ==========================================
  // QUERY EXECUTION METHODS
  // ==========================================

  /// Execute query to get all lists for a user
  Stream<List<ShoppingList>> executeListsQuery({required String userId}) {
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
            debugPrint('✅ FirestoreRepository returning ${lists.length} lists');
            return lists;
          });
    } catch (e) {
      debugPrint('❌ Error in executeListsQuery: $e');
      return Stream.error(
        FirestoreRepositoryException(
          'Failed to execute lists query',
          originalError: e,
        ),
      );
    }
  }

  /// Execute query to get a specific list by ID
  Stream<ShoppingList?> executeListQuery({
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

        // Validate user has access to this list
        if (!validateUserAccess(doc, userId)) {
          return null;
        }

        return await documentToShoppingList(doc);
      });
    } catch (e) {
      debugPrint('❌ Error in executeListQuery: $e');
      return Stream.error(
        FirestoreRepositoryException(
          'Failed to execute list query for: $listId',
          originalError: e,
        ),
      );
    }
  }

  /// Execute query to get items for a specific list
  Stream<List<ShoppingItem>> executeItemsQuery({required String listId}) {
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
        FirestoreRepositoryException(
          'Failed to execute items query for: $listId',
          originalError: e,
        ),
      );
    }
  }

  // ==========================================
  // VALIDATION METHODS
  // ==========================================

  /// Validate that a user has access to a list document
  bool validateUserAccess(DocumentSnapshot doc, String userId) {
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final memberIds = List<String>.from(data['memberIds'] ?? []);
    return memberIds.contains(userId);
  }

  // ==========================================
  // PRIVATE HELPER METHODS
  // ==========================================

  /// Get items for a list document reference
  Future<List<ShoppingItem>> _getItemsForList(DocumentReference listRef) async {
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
      throw FirestoreRepositoryException(
        'Failed to get items for list: ${listRef.id}',
        originalError: e,
      );
    }
  }

  /// Convert Firestore Timestamp to DateTime with fallback
  DateTime _timestampToDateTime(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    }
    return DateTime.now(); // Fallback for missing timestamps
  }
}
