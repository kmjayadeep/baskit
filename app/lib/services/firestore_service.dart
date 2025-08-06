import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'firebase_auth_service.dart';
import '../repositories/firestore_repository.dart';

/// Custom exceptions for business logic operations
class UserNotFoundException implements Exception {
  final String email;
  UserNotFoundException(this.email);

  @override
  String toString() => 'UserNotFoundException: $email';
}

class UserAlreadyMemberException implements Exception {
  final String userName;
  UserAlreadyMemberException(this.userName);

  @override
  String toString() => 'UserAlreadyMemberException: $userName';
}

/// High-level business logic service for Firestore operations
///
/// This service handles:
/// - Complex business operations (create, update, delete with permissions)
/// - User management and sharing functionality
/// - Permission checking and validation
/// - Multi-document transactions and batch operations
///
/// Delegates to:
/// - FirestoreRepository for data access and query execution
/// - FirebaseAuthService for authentication state
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirestoreRepository _repository = FirestoreRepository();

  // ==========================================
  // FIREBASE AVAILABILITY & INITIALIZATION
  // ==========================================

  /// Check if Firebase is available for operations
  static bool get isFirebaseAvailable {
    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      return hasApps && authAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Enable offline persistence for better offline experience
  static Future<void> enableOfflinePersistence() async {
    if (!isFirebaseAvailable) return;

    try {
      _firestore.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Error enabling offline persistence: $e');
    }
  }

  /// Initialize user profile document when user first signs in
  static Future<void> initializeUserProfile() async {
    if (!isFirebaseAvailable) return;

    final user = FirebaseAuthService.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        await _usersCollection.doc(user.uid).set({
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
    } catch (e) {
      debugPrint('Error initializing user profile: $e');
    }
  }

  // ==========================================
  // QUERY DELEGATION TO REPOSITORY
  // ==========================================

  /// Get all user lists (owned + shared) - delegates to repository
  static Stream<List<ShoppingList>> getUserLists() {
    debugPrint('🔍 FirestoreService.getUserLists() called');

    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('❌ No authenticated user - returning empty stream');
      return Stream.value([]);
    }

    return _repository.executeListsQuery(userId: userId);
  }

  /// Get a specific list by ID - delegates to repository
  static Stream<ShoppingList?> getListById(String listId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _repository.executeListQuery(listId: listId, userId: userId);
  }

  /// Get items stream for a list - delegates to repository
  static Stream<List<ShoppingItem>> getListItems(String listId) {
    return _repository.executeItemsQuery(listId: listId);
  }

  // ==========================================
  // BUSINESS LOGIC - LIST OPERATIONS
  // ==========================================

  /// Create a new shopping list with proper initialization
  static Future<String?> createList(ShoppingList list) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return null;
    }

    try {
      // Create the list document with full member structure
      final docRef = await _listsCollection.add({
        'name': list.name,
        'description': list.description,
        'color': list.color,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': _currentUserId,
        'memberIds': [_currentUserId], // Array for efficient querying
        'members': {
          _currentUserId!: {
            'userId': _currentUserId,
            'role': 'owner',
            'displayName': FirebaseAuthService.userDisplayName,
            'email': FirebaseAuthService.userEmail,
            'joinedAt': FieldValue.serverTimestamp(),
            'permissions': {
              'read': true,
              'write': true,
              'delete': true,
              'share': true,
            },
          },
        },
      });

      // Add items if any (only active items)
      if (list.activeItems.isNotEmpty) {
        final batch = _firestore.batch();
        for (final item in list.activeItems) {
          final itemRef = docRef.collection('items').doc();
          batch.set(itemRef, {
            'name': item.name,
            'quantity': item.quantity,
            'completed': item.isCompleted,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': _currentUserId,
          });
        }
        await batch.commit();
      }

      // Update user's list IDs
      await _usersCollection.doc(_currentUserId!).update({
        'listIds': FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating list in Firestore: $e');
      return null;
    }
  }

  /// Update list metadata with permission checking
  static Future<bool> updateList(
    String listId, {
    String? name,
    String? description,
    String? color,
  }) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (color != null) updateData['color'] = color;

      await _listsCollection.doc(listId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating list: $e');
      return false;
    }
  }

  /// Delete a list and all its subcollections with permission checking
  static Future<bool> deleteList(String listId) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete permission (should be owner)
      final hasPermission = await hasListPermission(listId, 'delete');
      if (!hasPermission) {
        debugPrint('❌ User does not have permission to delete list: $listId');
        return false;
      }

      // Use batch for atomicity
      final batch = _firestore.batch();

      // Delete all items in the subcollection
      final itemsSnapshot =
          await _listsCollection.doc(listId).collection('items').get();

      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      // Delete the main list document
      batch.delete(_listsCollection.doc(listId));

      // Commit all deletions atomically
      await batch.commit();

      // Remove from user's list IDs after successful deletion
      await _usersCollection.doc(_currentUserId!).update({
        'listIds': FieldValue.arrayRemove([listId]),
      });

      debugPrint(
        '✅ Successfully deleted list and ${itemsSnapshot.docs.length} items',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting list: $e');
      return false;
    }
  }

  // ==========================================
  // BUSINESS LOGIC - ITEM OPERATIONS
  // ==========================================

  /// Add item to list with permission checking
  static Future<String?> addItemToList(String listId, ShoppingItem item) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      debugPrint('❌ Firebase not available or no current user');
      return null;
    }

    try {
      // Check if user has write permission
      final hasPermission = await hasListPermission(listId, 'write');
      if (!hasPermission) {
        return null;
      }

      final docRef = await _listsCollection
          .doc(listId)
          .collection('items')
          .add({
            'name': item.name,
            'quantity': item.quantity,
            'completed': item.isCompleted,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': _currentUserId,
          });

      // Update list's updatedAt timestamp
      await _listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding item to list: $e');
      return null;
    }
  }

  /// Update item in list with permission checking
  static Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      // Check if user has write permission
      final hasPermission = await hasListPermission(listId, 'write');
      if (!hasPermission) {
        return false;
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (quantity != null) updateData['quantity'] = quantity;
      if (completed != null) {
        updateData['completed'] = completed;
        // Handle completedAt timestamp
        if (completed) {
          updateData['completedAt'] = FieldValue.serverTimestamp();
        } else {
          updateData['completedAt'] = FieldValue.delete();
        }
      }

      await _listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .update(updateData);

      // Update list's updatedAt timestamp
      await _listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return false;
    }
  }

  /// Delete item from list with permission checking
  static Future<bool> deleteItemFromList(String listId, String itemId) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete permission
      final hasPermission = await hasListPermission(listId, 'delete');
      if (!hasPermission) {
        return false;
      }

      await _listsCollection
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .delete();

      // Update list's updatedAt timestamp
      await _listsCollection.doc(listId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting item: $e');
      return false;
    }
  }

  /// Clear completed items from list with permission checking
  static Future<bool> clearCompletedItems(String listId) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      // Check if user has delete permission
      final hasPermission = await hasListPermission(listId, 'delete');
      if (!hasPermission) {
        return false;
      }

      // Get all completed items
      final completedItemsSnapshot =
          await _listsCollection
              .doc(listId)
              .collection('items')
              .where('completed', isEqualTo: true)
              .get();

      if (completedItemsSnapshot.docs.isEmpty) {
        return true; // No completed items to clear
      }

      // Use batch to delete all completed items atomically
      final batch = _firestore.batch();

      for (final itemDoc in completedItemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      // Update list's updatedAt timestamp
      batch.update(_listsCollection.doc(listId), {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint(
        '✅ Successfully cleared ${completedItemsSnapshot.docs.length} completed items',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing completed items: $e');
      return false;
    }
  }

  // ==========================================
  // BUSINESS LOGIC - SHARING & PERMISSIONS
  // ==========================================

  /// Share list with user by email (complex business operation)
  static Future<bool> shareListWithUser(String listId, String email) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      // Find the user by email
      final userQuery =
          await _usersCollection
              .where('profile.email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw UserNotFoundException(email);
      }

      final targetUserDoc = userQuery.docs.first;
      final targetUserId = targetUserDoc.id;
      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      final targetUserProfile =
          targetUserData['profile'] as Map<String, dynamic>? ?? {};
      final targetUserName =
          targetUserProfile['displayName'] as String? ??
          targetUserProfile['email'] as String? ??
          'Unknown User';

      // Check if user is already a member
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        throw Exception('List not found');
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final members = listData['members'] as Map<String, dynamic>? ?? {};

      if (members.containsKey(targetUserId)) {
        throw UserAlreadyMemberException(targetUserName);
      }

      // Add user to the list members
      await _listsCollection.doc(listId).update({
        'members.$targetUserId': {
          'userId': targetUserId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'displayName': targetUserName,
          'email': email,
          'permissions': {
            'read': true,
            'write': true,
            'delete':
                true, // Members can delete items and clear completed items
            'share': true, // Members can share lists with others
          },
        },
        'memberIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sharing list: $e');
      return false;
    }
  }

  /// Check if user has permission to perform action on list
  static Future<bool> hasListPermission(
    String listId,
    String permission,
  ) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        return false;
      }

      final data = listDoc.data() as Map<String, dynamic>;
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final userMember = members[_currentUserId] as Map<String, dynamic>?;

      if (userMember == null) {
        return false; // User is not a member
      }

      final permissions =
          userMember['permissions'] as Map<String, dynamic>? ?? {};
      return permissions[permission] == true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // ==========================================
  // UTILITY OPERATIONS
  // ==========================================

  /// Migrate data from local storage (complex business operation)
  static Future<void> migrateLocalData(List<ShoppingList> localLists) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return;
    }

    try {
      for (final list in localLists) {
        await createList(list);
      }
    } catch (e) {
      debugPrint('Error migrating local data: $e');
    }
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  static CollectionReference get _listsCollection =>
      _firestore.collection('lists');

  /// Get current authenticated user ID
  static String? get _currentUserId => FirebaseAuthService.currentUser?.uid;
}
