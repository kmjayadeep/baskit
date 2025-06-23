import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('🚀 StorageService.createList called for list: ${list.name}');

    // Always save locally first for offline access
    bool localSuccess = false;

    // Check Firebase availability and authentication
    debugPrint(
      '📱 Firebase available: ${FirestoreService.isFirebaseAvailable}',
    );
    debugPrint('👤 User anonymous: ${FirebaseAuthService.isAnonymous}');
    debugPrint('🔑 Current user: ${FirebaseAuthService.currentUser?.uid}');

    // If Firebase is available and user is authenticated, create in Firebase first
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      debugPrint('✅ Attempting to create list in Firebase...');
      try {
        final firebaseId = await FirestoreService.createList(list);
        debugPrint('🔥 Firebase createList returned ID: $firebaseId');

        if (firebaseId != null) {
          debugPrint('✅ Firebase creation successful, updating local copy...');
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
          debugPrint('💾 Local save after Firebase: $localSuccess');
          await _updateLastSyncTime();
          debugPrint('⏰ Sync time updated');
        } else {
          debugPrint('❌ Firebase creation returned null, saving locally only');
          // Firebase creation failed, use local UUID
          localSuccess = await _saveListLocally(list);
          debugPrint('💾 Local save (fallback): $localSuccess');
        }
      } catch (e) {
        debugPrint('💥 Firebase create failed with error: $e');
        debugPrint('📱 Saving locally as fallback...');
        localSuccess = await _saveListLocally(list);
        debugPrint('💾 Local save (error fallback): $localSuccess');
      }
    } else {
      debugPrint(
        '⚠️ Firebase not available or user anonymous, saving locally only',
      );
      // No Firebase available, just save locally
      localSuccess = await _saveListLocally(list);
      debugPrint('💾 Local save (offline): $localSuccess');
    }

    debugPrint(
      '🎯 StorageService.createList completed. Success: $localSuccess',
    );
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
    List<ShoppingList> lists = await _getAllListsLocally();

    // If Firebase is available and user is authenticated, try to sync
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        // Check if we need to migrate local data to Firebase
        if (await _shouldMigrateData()) {
          await _migrateLocalDataToFirebase(lists);
        }

        // For real-time sync, we'll return the stream in a different method
        // Here we just ensure local data is up to date
        await _syncFromFirebase();

        // Get updated local lists after sync
        lists = await _getAllListsLocally();
      } catch (e) {
        debugPrint('Firebase sync failed, using local data: $e');
      }
    }

    return lists;
  }

  // Get lists stream for real-time updates
  Stream<List<ShoppingList>> getListsStream() {
    // If Firebase is available and user is authenticated, use Firebase stream
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      return FirestoreService.getUserLists().handleError((error) {
        debugPrint('Firebase stream error: $error');
        // Fallback to local data on error
        return _getAllListsLocally();
      });
    }

    // For anonymous users or when Firebase is unavailable, return local data as stream
    return Stream.fromFuture(_getAllListsLocally());
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
    // Try local first for immediate response
    final localList = await _getListByIdLocally(id);

    // If Firebase is available, get the latest version
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      try {
        // For real-time updates, use the stream method instead
        return localList;
      } catch (e) {
        debugPrint('Firebase get failed, using local data: $e');
      }
    }

    return localList;
  }

  // Get list stream for real-time updates
  Stream<ShoppingList?> getListByIdStream(String id) {
    // If Firebase is available and user is authenticated, use Firebase stream
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      return FirestoreService.getListById(id).handleError((error) {
        debugPrint('Firebase list stream error: $error');
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
    // This would typically listen to Firebase changes and update local storage
    // For now, we rely on the stream methods for real-time updates
  }

  Future<bool> _shouldMigrateData() async {
    // Check if user just signed in and has local data but no sync history
    final lastSync = _prefs!.getInt(_lastSyncKey);
    final localLists = await _getAllListsLocally();

    return lastSync == null &&
        localLists.isNotEmpty &&
        !FirebaseAuthService.isAnonymous;
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
  Future<void> forcSync() async {
    if (FirestoreService.isFirebaseAvailable &&
        !FirebaseAuthService.isAnonymous) {
      await _syncFromFirebase();
    }
  }

  // Check sync status
  Future<DateTime?> getLastSyncTime() async {
    await init();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }
}
