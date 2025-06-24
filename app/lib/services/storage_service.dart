import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';
import 'package:flutter/foundation.dart';

// Result class for sharing operations
class ShareResult {
  final bool success;
  final String? errorMessage;

  ShareResult.success() : success = true, errorMessage = null;
  ShareResult.error(this.errorMessage) : success = false;
}

class StorageService {
  static const String _listsKey = 'shopping_lists';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Create a new shopping list
  Future<bool> createList(ShoppingList list) async {
    await init();

    // Always save locally first for offline access
    bool localSuccess = false;

    // If Firebase is available and user is authenticated, create in Firebase first
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        final firebaseId = await FirestoreService.createList(list);

        if (firebaseId != null) {
          // Create updated list with Firebase ID
          final updatedList = ShoppingList(
            id: firebaseId,
            name: list.name,
            description: list.description,
            color: list.color,
            createdAt: list.createdAt,
            updatedAt: DateTime.now(),
            items: list.items,
            members: list.members,
          );
          localSuccess = await _saveListLocally(updatedList);
          await _updateLastSyncTime();
        } else {
          // Firebase creation failed, use local UUID
          localSuccess = await _saveListLocally(list);
        }
      } catch (e) {
        debugPrint('Firebase create failed with error: $e');
        localSuccess = await _saveListLocally(list);
      }
    } else {
      // No Firebase available, just save locally
      localSuccess = await _saveListLocally(list);
    }

    return localSuccess;
  }

  // Save a shopping list (for updating existing lists)
  Future<bool> saveList(ShoppingList list) async {
    await init();

    // Always save locally first for offline access
    final localSuccess = await _saveListLocally(list);

    // If Firebase is available and user is authenticated, sync to cloud
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        // For existing lists, always try to update
        await FirestoreService.updateList(
          list.id,
          name: list.name,
          description: list.description,
          color: list.color,
        );
        await _updateLastSyncTime();
      } catch (e) {
        debugPrint('Firebase sync failed, saved locally: $e');
      }
    }

    return localSuccess;
  }

  // Save list locally only
  Future<bool> _saveListLocally(ShoppingList list) async {
    await init();

    final lists = await _getAllListsLocally();

    // Remove existing list with same ID if it exists
    lists.removeWhere((existingList) => existingList.id == list.id);

    // Add the new/updated list
    lists.add(list);

    // Convert to JSON and save
    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    return await _prefs!.setString(_listsKey, jsonString);
  }

  // Get all shopping lists (with Firebase sync)
  Future<List<ShoppingList>> getAllLists() async {
    await init();

    // Start with local lists for immediate display
    List<ShoppingList> localLists = await _getAllListsLocally();

    // If Firebase is available and user is authenticated, merge with Firebase data
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        // Check if we need to migrate local data to Firebase
        if (await _shouldMigrateData()) {
          await _migrateLocalDataToFirebase(localLists);
        }

        // Get Firebase lists and merge with local
        final firebaseListsStream = FirestoreService.getUserLists();
        final firebaseLists = await firebaseListsStream.first;

        // Merge Firebase and local lists
        final mergedLists = await _mergeListsWithLocal(firebaseLists);

        // Cache Firebase lists locally for offline access
        for (final list in firebaseLists) {
          await _saveListLocally(list);
        }

        debugPrint('📱 Local-first ready: ${mergedLists.length} lists total');
        debugPrint('   - ${firebaseLists.length} Firebase lists');
        debugPrint(
          '   - ${mergedLists.length - firebaseLists.length} local-only lists',
        );

        return mergedLists;
      } catch (e) {
        debugPrint('Firebase sync failed, using local data: $e');
      }
    }

    return localLists;
  }

  // Get lists stream for real-time updates
  Stream<List<ShoppingList>> getListsStream() async* {
    // Always start with local data for immediate display
    yield await _getAllListsLocally();

    // If Firebase is available and user is authenticated, enhance with Firebase data
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      // Migrate local data if needed
      final localLists = await _getAllListsLocally();
      if (await _shouldMigrateData()) {
        await _migrateLocalDataToFirebase(localLists);
      }

      // Set up Firebase stream with local caching
      await for (final firebaseLists in FirestoreService.getUserLists()) {
        try {
          // Merge Firebase lists with local lists
          final mergedLists = await _mergeListsWithLocal(firebaseLists);

          // Cache Firebase lists locally for offline access
          for (final list in firebaseLists) {
            await _saveListLocally(list);
          }

          yield mergedLists;
        } catch (e) {
          debugPrint('Firebase stream error: $e');
          // On error, fall back to local data
          yield await _getAllListsLocally();
        }
      }
    }
  }

  // Get local lists only
  Future<List<ShoppingList>> _getAllListsLocally() async {
    await init();

    final jsonString = _prefs!.getString(_listsKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ShoppingList.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error parsing local lists: $e');
      return [];
    }
  }

  // Get a specific list by ID (with Firebase sync)
  Future<ShoppingList?> getListById(String id) async {
    // If Firebase is available and user is authenticated, get from Firebase first
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        // Get the list from Firebase (this will handle shared lists properly)
        final firebaseStream = FirestoreService.getListById(id);
        final firebaseList = await firebaseStream.first;

        if (firebaseList != null) {
          // Save to local storage for offline access
          await _saveListLocally(firebaseList);
          return firebaseList;
        }
      } catch (e) {
        debugPrint('Firebase get failed: $e, falling back to local');
      }
    }

    // Fallback to local storage (for offline access or anonymous users)
    return await _getListByIdLocally(id);
  }

  // Get list stream for real-time updates
  Stream<ShoppingList?> getListByIdStream(String id) {
    // If Firebase is available and user is authenticated, use Firebase stream with local caching
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      return FirestoreService.getListById(id)
          .map((firebaseList) {
            // Cache the list locally for offline access (especially important for shared lists)
            if (firebaseList != null) {
              _saveListLocally(firebaseList);
            }
            return firebaseList;
          })
          .handleError((error) {
            debugPrint('Firebase list stream error: $error');
            // Fallback to local data - ensures shared lists work offline
            return _getListByIdLocally(id);
          });
    }

    // For anonymous users, return local data as stream
    return Stream.fromFuture(_getListByIdLocally(id));
  }

  // Get local list by ID
  Future<ShoppingList?> _getListByIdLocally(String id) async {
    final lists = await _getAllListsLocally();
    try {
      return lists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete a list (local + Firebase)
  Future<bool> deleteList(String id) async {
    // Delete from Firebase first if available
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        await FirestoreService.deleteList(id);
      } catch (e) {
        debugPrint('Firebase delete failed: $e');
      }
    }

    // Delete locally
    final lists = await _getAllListsLocally();
    lists.removeWhere((list) => list.id == id);

    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    return await _prefs!.setString(_listsKey, jsonString);
  }

  // Add item to list
  Future<bool> addItemToList(String listId, ShoppingItem item) async {
    // Get current list
    final list = await getListById(listId);
    if (list == null) return false;

    // Add to Firebase if available
    String? firebaseItemId;
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        firebaseItemId = await FirestoreService.addItemToList(listId, item);
      } catch (e) {
        debugPrint('Firebase add item failed: $e');
      }
    }

    // Add to local list
    final updatedItem = ShoppingItem(
      id: firebaseItemId ?? item.id,
      name: item.name,
      quantity: item.quantity,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
    );

    final updatedList = ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
      items: [...list.items, updatedItem],
      members: list.members,
    );

    return await _saveListLocally(updatedList);
  }

  // Update item in list
  Future<bool> updateItemInList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    // Update in Firebase if available
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        await FirestoreService.updateItemInList(
          listId,
          itemId,
          name: name,
          quantity: quantity,
          completed: completed,
        );
      } catch (e) {
        debugPrint('Firebase update item failed: $e');
      }
    }

    // Update locally
    final list = await getListById(listId);
    if (list == null) return false;

    final updatedItems =
        list.items.map((item) {
          if (item.id == itemId) {
            return ShoppingItem(
              id: item.id,
              name: name ?? item.name,
              quantity: quantity ?? item.quantity,
              isCompleted: completed ?? item.isCompleted,
              createdAt: item.createdAt,
            );
          }
          return item;
        }).toList();

    final updatedList = ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
      items: updatedItems,
      members: list.members,
    );

    return await _saveListLocally(updatedList);
  }

  // Delete item from list
  Future<bool> deleteItemFromList(String listId, String itemId) async {
    // Delete from Firebase if available
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        await FirestoreService.deleteItemFromList(listId, itemId);
      } catch (e) {
        debugPrint('Firebase delete item failed: $e');
      }
    }

    // Delete locally
    final list = await getListById(listId);
    if (list == null) return false;

    final updatedItems = list.items.where((item) => item.id != itemId).toList();

    final updatedList = ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
      items: updatedItems,
      members: list.members,
    );

    return await _saveListLocally(updatedList);
  }

  // Share list with user by email
  Future<ShareResult> shareListWithUser(String listId, String email) async {
    // If Firebase is available and user is authenticated, share in Firebase
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        final success = await FirestoreService.shareListWithUser(listId, email);
        if (success) {
          // After successful sharing, sync the updated list locally to ensure
          // the new member info is immediately available offline
          await _syncSingleListFromFirebase(listId);
          return ShareResult.success();
        } else {
          return ShareResult.error('Failed to share list. Please try again.');
        }
      } catch (e) {
        // Handle specific error cases with user-friendly messages
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('not found') ||
            errorString.contains('usernotfoundexception')) {
          return ShareResult.error(
            'User with email $email not found.\n\nMake sure they have signed up for the app first, then try sharing again.',
          );
        }

        if (errorString.contains('already a member') ||
            errorString.contains('useralreadymemberexception')) {
          return ShareResult.error(
            'This user is already a member of this list.',
          );
        }

        // Default error for any other case
        return ShareResult.error(
          'Unable to share list with $email.\n\nPlease make sure they have the app installed and try again.',
        );
      }
    } else {
      return ShareResult.error(
        'You need to be signed in to share lists with others.',
      );
    }
  }

  // Sync a single list from Firebase to local storage
  Future<void> _syncSingleListFromFirebase(String listId) async {
    if (!FirestoreService.isFirebaseAvailable ||
        FirebaseAuthService.isAnonymous) {
      return;
    }

    try {
      final firebaseListStream = FirestoreService.getListById(listId);
      final firebaseList = await firebaseListStream.first;

      if (firebaseList != null) {
        await _saveListLocally(firebaseList);
        debugPrint(
          '✅ Synced shared list "${firebaseList.name}" to local storage',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to sync single list: $e');
    }
  }

  // Clear all lists (for testing/reset)
  Future<bool> clearAllLists() async {
    await init();
    return await _prefs!.remove(_listsKey);
  }

  // Get lists count
  Future<int> getListsCount() async {
    final lists = await getAllLists();
    return lists.length;
  }

  // Sync methods
  Future<void> _syncFromFirebase() async {
    if (!FirestoreService.isFirebaseAvailable ||
        FirebaseAuthService.isAnonymous) {
      return;
    }

    try {
      debugPrint('🔄 Starting Firebase sync for local-first operation...');

      // Get all user lists (owned + shared) from Firebase
      final firebaseListsStream = FirestoreService.getUserLists();
      final firebaseLists = await firebaseListsStream.first;

      if (firebaseLists.isNotEmpty) {
        // Get current local lists
        final localLists = await _getAllListsLocally();

        // Sync each Firebase list to local storage
        for (final firebaseList in firebaseLists) {
          await _saveListLocally(firebaseList);
        }

        // Remove local lists that no longer exist in Firebase (in case user was removed from shared lists)
        final firebaseListIds = firebaseLists.map((list) => list.id).toSet();
        final listsToRemove =
            localLists
                .where(
                  (localList) =>
                      !firebaseListIds.contains(localList.id) &&
                      localList
                          .members
                          .isNotEmpty, // Only remove shared lists, keep personal ones for offline creation
                )
                .toList();

        for (final listToRemove in listsToRemove) {
          await _removeListFromLocal(listToRemove.id);
          debugPrint(
            '🗑️ Removed local list ${listToRemove.name} (no longer accessible)',
          );
        }

        debugPrint('✅ Synced ${firebaseLists.length} lists to local storage');
        debugPrint(
          '📱 Local-first sync complete - shared lists now available offline',
        );
      }

      await _updateLastSyncTime();
    } catch (e) {
      debugPrint('❌ Firebase sync failed: $e');
    }
  }

  // Remove a specific list from local storage
  Future<void> _removeListFromLocal(String listId) async {
    final lists = await _getAllListsLocally();
    lists.removeWhere((list) => list.id == listId);

    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);
    await _prefs!.setString(_listsKey, jsonString);
  }

  // Merge Firebase lists with local lists to ensure all data is visible
  Future<List<ShoppingList>> _mergeListsWithLocal(
    List<ShoppingList> firebaseLists,
  ) async {
    final localLists = await _getAllListsLocally();
    final firebaseListIds = firebaseLists.map((list) => list.id).toSet();

    // Start with Firebase lists (they are the source of truth for synced data)
    final mergedLists = List<ShoppingList>.from(firebaseLists);

    // Add local-only lists (lists created offline that haven't been synced yet)
    for (final localList in localLists) {
      if (!firebaseListIds.contains(localList.id)) {
        // This is a local-only list, add it to the merged list
        mergedLists.add(localList);
      }
    }

    return mergedLists;
  }

  Future<bool> _shouldMigrateData() async {
    // Always migrate local data when user signs in and has local lists
    if (FirebaseAuthService.isAnonymous) return false;

    final localLists = await _getAllListsLocally();
    if (localLists.isEmpty) return false;

    // Check if we have any local lists that aren't in Firebase yet
    try {
      final firebaseListsStream = FirestoreService.getUserLists();
      final firebaseLists = await firebaseListsStream.first;
      final firebaseListIds = firebaseLists.map((list) => list.id).toSet();

      // If we have local lists that aren't in Firebase, we should migrate
      final hasUnsynced = localLists.any(
        (list) => !firebaseListIds.contains(list.id),
      );
      return hasUnsynced;
    } catch (e) {
      // If we can't check Firebase, assume we should migrate
      return true;
    }
  }

  Future<void> _migrateLocalDataToFirebase(
    List<ShoppingList> localLists,
  ) async {
    try {
      await FirestoreService.migrateLocalData(localLists);
      await _updateLastSyncTime();
      debugPrint('✅ Migrated ${localLists.length} lists to Firebase');
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Force sync with Firebase (for manual refresh)
  Future<void> forceSync() async {
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      debugPrint('🔄 Manual sync requested - syncing shared lists...');
      await _syncFromFirebase();
      debugPrint('✅ Manual sync complete');
    } else {
      debugPrint(
        '⚠️ Sync unavailable - Firebase not available or user anonymous',
      );
    }
  }

  // Legacy method name for compatibility
  Future<void> forcSync() => forceSync();

  // Check sync status
  Future<DateTime?> getLastSyncTime() async {
    await init();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }
}
