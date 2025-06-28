import 'dart:convert';
import 'dart:async';
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
  static const String _migrationCompleteKey = 'migration_complete_';
  static StorageService? _instance;
  SharedPreferences? _prefs;

  // Stream controller for anonymous users
  StreamController<List<ShoppingList>>? _localListsController;
  Stream<List<ShoppingList>>? _localListsStream;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  // Initialize SharedPreferences and stream controller
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _initializeLocalListsStream();
  }

  // Initialize local lists stream for anonymous users
  void _initializeLocalListsStream() {
    if (_localListsController == null) {
      _localListsController = StreamController<List<ShoppingList>>.broadcast();
      _localListsStream = _localListsController!.stream;

      // Emit initial data
      _getAllListsLocally().then((lists) {
        if (!_localListsController!.isClosed) {
          _localListsController!.add(lists);
        }
      });
    }
  }

  // Trigger local lists stream update
  Future<void> _updateLocalListsStream() async {
    if (_localListsController != null && !_localListsController!.isClosed) {
      final lists = await _getAllListsLocally();
      _localListsController!.add(lists);
    }
  }

  // Dispose resources
  void dispose() {
    _localListsController?.close();
    _localListsController = null;
    _localListsStream = null;
  }

  // Get migration key for current user
  String get _currentUserMigrationKey {
    final userId = FirebaseAuthService.currentUser?.uid ?? 'anonymous';
    return '$_migrationCompleteKey$userId';
  }

  // Check if migration has been completed for current user
  Future<bool> _isMigrationComplete() async {
    await init();
    if (FirebaseAuthService.isAnonymous) {
      return true; // Anonymous users don't need migration
    }
    return _prefs!.getBool(_currentUserMigrationKey) ?? false;
  }

  // Mark migration as complete for current user
  Future<void> _markMigrationComplete() async {
    await init();
    if (!FirebaseAuthService.isAnonymous) {
      await _prefs!.setBool(_currentUserMigrationKey, true);
    }
  }

  // Create a new shopping list
  Future<bool> createList(ShoppingList list) async {
    await init();

    final isAnonymous = FirebaseAuthService.isAnonymous;
    final currentUser = FirebaseAuthService.currentUser;

    debugPrint('🔍 StorageService.createList() called:');
    debugPrint('   - isAnonymous: $isAnonymous');
    debugPrint('   - currentUser exists: ${currentUser != null}');
    debugPrint('   - currentUser.uid: ${currentUser?.uid}');
    debugPrint('   - list name: ${list.name}');

    if (isAnonymous) {
      debugPrint('📱 Creating list locally for anonymous user');
      // Anonymous users: save locally only
      return await _saveListLocally(list);
    } else {
      debugPrint('☁️ Creating list in Firebase for authenticated user');
      // Authenticated users: create in Firebase and let offline persistence handle local caching
      try {
        // Ensure migration is complete first
        await _ensureMigrationComplete();

        final firebaseId = await FirestoreService.createList(list);
        if (firebaseId != null) {
          await _updateLastSyncTime();
          debugPrint('✅ List created in Firebase: $firebaseId');
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('❌ Firebase create failed: $e');
        return false;
      }
    }
  }

  // Save a shopping list (for updating existing lists)
  Future<bool> saveList(ShoppingList list) async {
    await init();

    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: save locally only
      return await _saveListLocally(list);
    } else {
      // Authenticated users: update in Firebase
      try {
        await FirestoreService.updateList(
          list.id,
          name: list.name,
          description: list.description,
          color: list.color,
        );
        await _updateLastSyncTime();
        return true;
      } catch (e) {
        debugPrint('❌ Firebase update failed: $e');
        return false;
      }
    }
  }

  // Save list locally only (for anonymous users)
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

    final success = await _prefs!.setString(_listsKey, jsonString);

    // Update stream if save was successful
    if (success) {
      await _updateLocalListsStream();
    }

    return success;
  }

  // Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
    await init();

    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: return local lists only
      return await _getAllListsLocally();
    } else {
      // Authenticated users: ensure migration and get from Firebase
      try {
        await _ensureMigrationComplete();

        // Get from Firebase (offline persistence handles caching)
        final firebaseListsStream = FirestoreService.getUserLists();
        final firebaseLists = await firebaseListsStream.first;

        debugPrint('📱 Loaded ${firebaseLists.length} lists from Firebase');
        return firebaseLists;
      } catch (e) {
        debugPrint('❌ Firebase failed, returning empty list: $e');
        return [];
      }
    }
  }

  // Get lists stream for real-time updates
  Stream<List<ShoppingList>> getListsStream() {
    final isAnonymous = FirebaseAuthService.isAnonymous;
    final currentUser = FirebaseAuthService.currentUser;

    debugPrint('🔍 StorageService.getListsStream() called:');
    debugPrint('   - isAnonymous: $isAnonymous');
    debugPrint('   - currentUser exists: ${currentUser != null}');
    debugPrint('   - currentUser.uid: ${currentUser?.uid}');
    debugPrint('   - currentUser.isAnonymous: ${currentUser?.isAnonymous}');

    if (isAnonymous) {
      debugPrint('📱 Using local storage for anonymous user');
      // Ensure stream is initialized
      _initializeLocalListsStream();
      // Anonymous users: return local data as stream
      return _localListsStream!;
    } else {
      debugPrint('☁️ Using Firebase for authenticated user');
      // Authenticated users: use Firebase stream with migration
      return _getAuthenticatedListsStream();
    }
  }

  // Get authenticated users stream with migration
  Stream<List<ShoppingList>> _getAuthenticatedListsStream() async* {
    try {
      // Ensure migration is complete before starting stream
      await _ensureMigrationComplete();

      // Use Firebase stream (offline persistence handles local caching)
      yield* FirestoreService.getUserLists();
    } catch (e) {
      debugPrint('❌ Firebase stream error: $e');
      yield [];
    }
  }

  // Get local lists only
  Future<List<ShoppingList>> _getAllListsLocally() async {
    await init();

    debugPrint('🔍 _getAllListsLocally() called');
    final jsonString = _prefs!.getString(_listsKey);

    if (jsonString == null) {
      debugPrint('📱 No local lists found in SharedPreferences');
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final lists =
          jsonList.map((json) => ShoppingList.fromJson(json)).toList();
      debugPrint(
        '✅ _getAllListsLocally() returning ${lists.length} local lists',
      );
      return lists;
    } catch (e) {
      debugPrint('❌ Error parsing local lists: $e');
      return [];
    }
  }

  // Get a specific list by ID
  Future<ShoppingList?> getListById(String id) async {
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: get from local storage
      return await _getListByIdLocally(id);
    } else {
      // Authenticated users: get from Firebase
      try {
        await _ensureMigrationComplete();

        final firebaseStream = FirestoreService.getListById(id);
        return await firebaseStream.first;
      } catch (e) {
        debugPrint('❌ Firebase get failed: $e');
        return null;
      }
    }
  }

  // Get list stream for real-time updates
  Stream<ShoppingList?> getListByIdStream(String id) {
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: return local data as stream
      return Stream.fromFuture(_getListByIdLocally(id));
    } else {
      // Authenticated users: use Firebase stream
      return _getAuthenticatedListStream(id);
    }
  }

  // Get authenticated list stream with migration
  Stream<ShoppingList?> _getAuthenticatedListStream(String id) async* {
    try {
      await _ensureMigrationComplete();
      yield* FirestoreService.getListById(id);
    } catch (e) {
      debugPrint('❌ Firebase list stream error: $e');
      yield null;
    }
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

  // Delete a list
  Future<bool> deleteList(String id) async {
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: delete locally
      return await _deleteListLocally(id);
    } else {
      // Authenticated users: delete from Firebase
      try {
        await FirestoreService.deleteList(id);
        return true;
      } catch (e) {
        debugPrint('❌ Firebase delete failed: $e');
        return false;
      }
    }
  }

  // Delete list locally
  Future<bool> _deleteListLocally(String id) async {
    final lists = await _getAllListsLocally();
    lists.removeWhere((list) => list.id == id);

    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    final success = await _prefs!.setString(_listsKey, jsonString);

    // Update stream if delete was successful
    if (success) {
      await _updateLocalListsStream();
    }

    return success;
  }

  // Add item to list
  Future<bool> addItemToList(String listId, ShoppingItem item) async {
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: update local list
      return await _addItemToLocalList(listId, item);
    } else {
      // Authenticated users: add to Firebase
      try {
        final firebaseItemId = await FirestoreService.addItemToList(
          listId,
          item,
        );
        return firebaseItemId != null;
      } catch (e) {
        debugPrint('❌ Firebase add item failed: $e');
        return false;
      }
    }
  }

  // Add item to local list
  Future<bool> _addItemToLocalList(String listId, ShoppingItem item) async {
    final list = await _getListByIdLocally(listId);
    if (list == null) return false;

    final updatedList = ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
      items: [...list.items, item],
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
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: update local list
      return await _updateItemInLocalList(
        listId,
        itemId,
        name: name,
        quantity: quantity,
        completed: completed,
      );
    } else {
      // Authenticated users: update in Firebase
      try {
        return await FirestoreService.updateItemInList(
          listId,
          itemId,
          name: name,
          quantity: quantity,
          completed: completed,
        );
      } catch (e) {
        debugPrint('❌ Firebase update item failed: $e');
        return false;
      }
    }
  }

  // Update item in local list
  Future<bool> _updateItemInLocalList(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    final list = await _getListByIdLocally(listId);
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
    if (FirebaseAuthService.isAnonymous) {
      // Anonymous users: update local list
      return await _deleteItemFromLocalList(listId, itemId);
    } else {
      // Authenticated users: delete from Firebase
      try {
        return await FirestoreService.deleteItemFromList(listId, itemId);
      } catch (e) {
        debugPrint('❌ Firebase delete item failed: $e');
        return false;
      }
    }
  }

  // Delete item from local list
  Future<bool> _deleteItemFromLocalList(String listId, String itemId) async {
    final list = await _getListByIdLocally(listId);
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

  // Share list with user by email (authenticated users only)
  Future<ShareResult> shareListWithUser(String listId, String email) async {
    if (FirebaseAuthService.isAnonymous) {
      return ShareResult.error(
        'You need to be signed in to share lists with others.',
      );
    }

    try {
      final success = await FirestoreService.shareListWithUser(listId, email);
      if (success) {
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
        return ShareResult.error('This user is already a member of this list.');
      }

      // Default error for any other case
      return ShareResult.error(
        'Unable to share list with $email.\n\nPlease make sure they have the app installed and try again.',
      );
    }
  }

  // Ensure migration is complete for authenticated users
  Future<void> _ensureMigrationComplete() async {
    if (FirebaseAuthService.isAnonymous || await _isMigrationComplete()) {
      return; // No migration needed
    }

    debugPrint('🔄 Starting migration of local data to Firebase...');

    try {
      // Get local lists
      final localLists = await _getAllListsLocally();

      if (localLists.isNotEmpty) {
        // Migrate each list to Firebase
        for (final list in localLists) {
          try {
            final firebaseId = await FirestoreService.createList(list);
            if (firebaseId != null) {
              debugPrint('✅ Migrated list "${list.name}" to Firebase');
            } else {
              debugPrint('❌ Failed to migrate list "${list.name}"');
            }
          } catch (e) {
            debugPrint('❌ Error migrating list "${list.name}": $e');
          }
        }

        debugPrint(
          '✅ Migration completed: ${localLists.length} lists processed',
        );
      }

      // Mark migration as complete
      await _markMigrationComplete();
      await _updateLastSyncTime();

      // Clear local data after successful migration
      await _clearLocalData();
      debugPrint('🗑️ Local data cleared after migration');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      // Don't mark as complete if migration failed
    }
  }

  // Clear all local data (used on logout and after migration)
  Future<void> _clearLocalData() async {
    await init();
    await _prefs!.remove(_listsKey);
    await _prefs!.remove(_lastSyncKey);
    // Update stream to reflect cleared data
    await _updateLocalListsStream();
    debugPrint('🗑️ Local data cleared');
  }

  // Clear all data for current user (used on logout)
  Future<void> clearUserData() async {
    await init();

    // Clear local lists
    await _clearLocalData();

    // Clear migration status for current user
    if (!FirebaseAuthService.isAnonymous) {
      await _prefs!.remove(_currentUserMigrationKey);
    }

    // Reset stream controller for new user state
    _resetStreamController();

    debugPrint('🗑️ User data cleared completely');
  }

  // Reset stream controller (used when user state changes)
  void _resetStreamController() {
    _localListsController?.close();
    _localListsController = null;
    _localListsStream = null;
    _initializeLocalListsStream();
  }

  // Clear all lists (for testing/reset)
  Future<bool> clearAllLists() async {
    if (FirebaseAuthService.isAnonymous) {
      await _clearLocalData();
      return true;
    } else {
      // For authenticated users, this would require deleting from Firebase
      // which is not implemented for safety reasons
      return false;
    }
  }

  // Get lists count
  Future<int> getListsCount() async {
    final lists = await getAllLists();
    return lists.length;
  }

  // Force sync with Firebase (for manual refresh)
  Future<void> forceSync() async {
    if (!FirebaseAuthService.isAnonymous) {
      debugPrint(
        '🔄 Manual sync requested - Firebase offline persistence handles sync automatically',
      );
      await _updateLastSyncTime();
      debugPrint('✅ Manual sync complete');
    } else {
      debugPrint('🔄 Manual refresh requested for anonymous user');
      // For anonymous users, refresh the local lists stream
      await _updateLocalListsStream();
      debugPrint('✅ Manual refresh complete');
    }
  }

  // Update last sync time
  Future<void> _updateLastSyncTime() async {
    await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Check sync status
  Future<DateTime?> getLastSyncTime() async {
    await init();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // Test helper methods (only for testing)
  @visibleForTesting
  Future<bool> saveListLocallyForTest(ShoppingList list) async {
    return await _saveListLocally(list);
  }

  @visibleForTesting
  Future<List<ShoppingList>> getAllListsLocallyForTest() async {
    return await _getAllListsLocally();
  }

  @visibleForTesting
  Future<ShoppingList?> getListByIdLocallyForTest(String id) async {
    return await _getListByIdLocally(id);
  }

  @visibleForTesting
  Future<bool> deleteListLocallyForTest(String id) async {
    return await _deleteListLocally(id);
  }

  @visibleForTesting
  Future<bool> addItemToLocalListForTest(
    String listId,
    ShoppingItem item,
  ) async {
    return await _addItemToLocalList(listId, item);
  }

  @visibleForTesting
  Future<bool> updateItemInLocalListForTest(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    return await _updateItemInLocalList(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @visibleForTesting
  Future<bool> deleteItemFromLocalListForTest(
    String listId,
    String itemId,
  ) async {
    return await _deleteItemFromLocalList(listId, itemId);
  }

  @visibleForTesting
  Future<bool> isMigrationCompleteForTest() async {
    return await _isMigrationComplete();
  }

  @visibleForTesting
  Future<void> markMigrationCompleteForTest() async {
    return await _markMigrationComplete();
  }

  @visibleForTesting
  Future<void> clearLocalDataForTest() async {
    return await _clearLocalData();
  }

  // Reset singleton instance for testing
  @visibleForTesting
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
  }
}
