import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'firebase_auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      final hasApps = Firebase.apps.isNotEmpty;
      final authAvailable = FirebaseAuthService.isFirebaseAvailable;
      debugPrint('🔍 Firebase availability check:');
      debugPrint('   - Firebase apps: ${Firebase.apps.length}');
      debugPrint('   - Has apps: $hasApps');
      debugPrint('   - Auth available: $authAvailable');

      final result = hasApps && authAvailable;
      debugPrint('   - Final result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error checking Firebase availability: $e');
      return false;
    }
  }

  // Enable offline persistence
  static Future<void> enableOfflinePersistence() async {
    if (!isFirebaseAvailable) {
      return;
    }

    try {
      // Use the new Settings.persistenceEnabled instead of deprecated enablePersistence()
      _firestore.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Error enabling offline persistence: $e');
    }
  }

  // Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Global lists collection for sharing support
  static CollectionReference get _listsCollection =>
      _firestore.collection('lists');

  // User-specific lists collection (deprecated - keeping for migration)
  static CollectionReference _userListsCollection(String userId) {
    return _usersCollection.doc(userId).collection('lists');
  }

  // Get current user ID
  static String? get _currentUserId => FirebaseAuthService.currentUser?.uid;

  // Initialize user profile
  static Future<void> initializeUserProfile() async {
    if (!isFirebaseAvailable) {
      return;
    }

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

  // Create a new shopping list
  static Future<String?> createList(ShoppingList list) async {
    debugPrint('🔥 FirestoreService.createList called for: ${list.name}');

    if (!isFirebaseAvailable || _currentUserId == null) {
      debugPrint('❌ Firebase not available or no current user');
      debugPrint('   - Firebase available: $isFirebaseAvailable');
      debugPrint('   - Current user ID: $_currentUserId');
      return null;
    }

    debugPrint('✅ Firebase available and user authenticated');
    debugPrint('   - User ID: $_currentUserId');
    debugPrint(
      '   - List details: ${list.name}, ${list.description}, ${list.color}',
    );

    try {
      debugPrint('📝 Creating list document in Firestore...');

      // Create the list document in global collection
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

      debugPrint('✅ List document created with ID: ${docRef.id}');

      // Add items if any
      if (list.items.isNotEmpty) {
        debugPrint('📦 Adding ${list.items.length} items to list...');
        final batch = _firestore.batch();
        for (final item in list.items) {
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
        debugPrint('✅ Items added successfully');
      } else {
        debugPrint('📦 No items to add');
      }

      // Update user's list IDs
      debugPrint('👤 Updating user profile with new list ID...');
      await _usersCollection.doc(_currentUserId!).update({
        'listIds': FieldValue.arrayUnion([docRef.id]),
      });
      debugPrint('✅ User profile updated');

      debugPrint(
        '🎉 List creation completed successfully. Final ID: ${docRef.id}',
      );
      return docRef.id;
    } catch (e) {
      debugPrint('💥 Error creating list in Firestore: $e');
      debugPrint('📊 Error details: ${e.toString()}');
      if (e is FirebaseException) {
        debugPrint('🔥 Firebase error code: ${e.code}');
        debugPrint('🔥 Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Get all user lists (owned + shared)
  static Stream<List<ShoppingList>> getUserLists() {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return Stream.value([]);
    }

    // Query both owned and shared lists from global collection
    return _listsCollection
        .where('memberIds', arrayContains: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ShoppingList> lists = [];

          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Get member names for display
            final members = data['members'] as Map<String, dynamic>? ?? {};
            final memberNames =
                members.values
                    .where(
                      (member) =>
                          member is Map<String, dynamic> &&
                          member['userId'] != _currentUserId,
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
            final itemsSnapshot =
                await doc.reference
                    .collection('items')
                    .orderBy('createdAt', descending: false)
                    .get();

            final items =
                itemsSnapshot.docs.map((itemDoc) {
                  final itemData = itemDoc.data();
                  return ShoppingItem(
                    id: itemDoc.id,
                    name: itemData['name'] ?? '',
                    quantity: itemData['quantity']?.toString(),
                    isCompleted: itemData['completed'] ?? false,
                    createdAt:
                        (itemData['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                  );
                }).toList();

            lists.add(
              ShoppingList(
                id: doc.id,
                name: data['name'] ?? 'Unnamed List',
                description: data['description'] ?? '',
                color: data['color'] ?? '#2196F3',
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                updatedAt:
                    (data['updatedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                items: items,
                members: memberNames,
              ),
            );
          }

          return lists;
        });
  }

  // Get a specific list by ID
  static Stream<ShoppingList?> getListById(String listId) {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return Stream.value(null);
    }

    return _listsCollection.doc(listId).snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check if user has access to this list
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      if (!memberIds.contains(_currentUserId)) {
        return null; // User doesn't have access
      }

      // Get member names for display
      final members = data['members'] as Map<String, dynamic>? ?? {};
      final memberNames =
          members.values
              .where(
                (member) =>
                    member is Map<String, dynamic> &&
                    member['userId'] != _currentUserId,
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
      final itemsSnapshot =
          await doc.reference
              .collection('items')
              .orderBy('createdAt', descending: false)
              .get();

      final items =
          itemsSnapshot.docs.map((itemDoc) {
            final itemData = itemDoc.data();
            return ShoppingItem(
              id: itemDoc.id,
              name: itemData['name'] ?? '',
              quantity: itemData['quantity']?.toString(),
              isCompleted: itemData['completed'] ?? false,
              createdAt:
                  (itemData['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList();

      return ShoppingList(
        id: doc.id,
        name: data['name'] ?? 'Unnamed List',
        description: data['description'] ?? '',
        color: data['color'] ?? '#2196F3',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        items: items,
        members: memberNames,
      );
    });
  }

  // Update list metadata
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

  // Delete a list
  static Future<bool> deleteList(String listId) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
      final batch = _firestore.batch();

      // Delete all items in the list
      final itemsSnapshot =
          await _userListsCollection(
            _currentUserId!,
          ).doc(listId).collection('items').get();

      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      // Delete the list document
      batch.delete(_userListsCollection(_currentUserId!).doc(listId));

      await batch.commit();

      // Remove from user's list IDs
      await _usersCollection.doc(_currentUserId!).update({
        'listIds': FieldValue.arrayRemove([listId]),
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting list: $e');
      return false;
    }
  }

  // Add item to list
  static Future<String?> addItemToList(String listId, ShoppingItem item) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return null;
    }

    try {
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

  // Update item in list
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
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (quantity != null) updateData['quantity'] = quantity;
      if (completed != null) updateData['completed'] = completed;

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

  // Delete item from list
  static Future<bool> deleteItemFromList(String listId, String itemId) async {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return false;
    }

    try {
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

  // Get items stream for a list
  static Stream<List<ShoppingItem>> getListItems(String listId) {
    if (!isFirebaseAvailable || _currentUserId == null) {
      return Stream.value([]);
    }

    return _listsCollection
        .doc(listId)
        .collection('items')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ShoppingItem(
              id: doc.id,
              name: data['name'] ?? '',
              quantity: data['quantity']?.toString(),
              isCompleted: data['completed'] ?? false,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  // Migrate data from local storage
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

  // Clean up expired data (for maintenance)
  static Future<void> cleanupExpiredData() async {
    // This would typically be handled by Cloud Functions
    // For now, this is a placeholder for future implementation
  }

  // Share list with user by email
  static Future<bool> shareListWithUser(String listId, String email) async {
    debugPrint('🤝 FirestoreService.shareListWithUser called');
    debugPrint('   - List ID: $listId');
    debugPrint('   - Email: $email');

    if (!isFirebaseAvailable || _currentUserId == null) {
      debugPrint('❌ Firebase not available or no current user');
      return false;
    }

    try {
      // First, find the user by email
      debugPrint('🔍 Looking for user with email: $email');
      final userQuery =
          await _usersCollection
              .where('profile.email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        debugPrint('❌ User not found with email: $email');
        throw Exception(
          'User with email $email not found. They may need to sign up first.',
        );
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

      debugPrint('✅ Found user: $targetUserName (ID: $targetUserId)');

      // Check if user is already a member
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        debugPrint('❌ List not found: $listId');
        throw Exception('List not found');
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final members = listData['members'] as Map<String, dynamic>? ?? {};
      final memberIds = List<String>.from(listData['memberIds'] ?? []);

      if (members.containsKey(targetUserId)) {
        debugPrint('⚠️ User is already a member of this list');
        throw Exception('$targetUserName is already a member of this list');
      }

      // Add user to the list members
      debugPrint('➕ Adding user to list members...');
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
            'delete': false,
            'share': false,
          },
        },
        'memberIds': FieldValue.arrayUnion([targetUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🎉 List shared successfully with $targetUserName!');
      return true;
    } catch (e) {
      debugPrint('💥 Error sharing list: $e');
      return false;
    }
  }
}
