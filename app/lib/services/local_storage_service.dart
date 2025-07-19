import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

/// Local storage service using SharedPreferences
/// Handles all local data operations for anonymous users
class LocalStorageService {
  static const String _listsKey = 'shopping_lists';
  static LocalStorageService? _instance;
  SharedPreferences? _prefs;

  // Stream controller for reactive updates
  StreamController<List<ShoppingList>>? _listsController;
  Stream<List<ShoppingList>>? _listsStream;

  // Stream controllers for individual lists (Map of listId -> StreamController)
  final Map<String, StreamController<ShoppingList?>>
  _individualListControllers = {};
  final Map<String, Stream<ShoppingList?>> _individualListStreams = {};

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  /// Initialize SharedPreferences and stream controllers
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _initializeListsStream();
  }

  /// Sort shopping items according to requirements:
  /// - Incomplete items at top, sorted by creation date (newest first)
  /// - Completed items at bottom, sorted by completion date (most recently completed first)
  List<ShoppingItem> _sortItems(List<ShoppingItem> items) {
    final incompleteItems = items.where((item) => !item.isCompleted).toList();
    final completedItems = items.where((item) => item.isCompleted).toList();

    // Sort incomplete items by creation date (newest first)
    incompleteItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Sort completed items by completion date (most recently completed first)
    // Fall back to creation date if completedAt is null
    completedItems.sort((a, b) {
      final aCompletedAt = a.completedAt ?? a.createdAt;
      final bCompletedAt = b.completedAt ?? b.createdAt;
      return bCompletedAt.compareTo(aCompletedAt);
    });

    // Return incomplete items first, then completed items
    return [...incompleteItems, ...completedItems];
  }

  /// Apply sorting to a shopping list
  ShoppingList _applySortingToList(ShoppingList list) {
    final sortedItems = _sortItems(list.items);
    return ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: list.updatedAt,
      items: sortedItems,
      members: list.members,
    );
  }

  /// Initialize lists stream for reactive updates
  void _initializeListsStream() {
    if (_listsController == null) {
      _listsController = StreamController<List<ShoppingList>>.broadcast();
      _listsStream = _listsController!.stream;

      // Emit initial data
      getAllLists().then((lists) {
        if (!_listsController!.isClosed) {
          _listsController!.add(lists);
        }
      });
    }
  }

  /// Trigger lists stream update
  Future<void> _updateListsStream() async {
    if (_listsController != null && !_listsController!.isClosed) {
      final lists = await getAllLists();
      _listsController!.add(lists);
    }
  }

  /// Initialize individual list stream for a specific list ID
  void _initializeIndividualListStream(String listId) {
    if (!_individualListControllers.containsKey(listId)) {
      final controller = StreamController<ShoppingList?>.broadcast();
      _individualListControllers[listId] = controller;
      _individualListStreams[listId] = controller.stream;

      // Emit initial data
      getListById(listId).then((list) {
        if (!controller.isClosed) {
          controller.add(list);
        }
      });
    }
  }

  /// Trigger individual list stream update
  Future<void> _updateIndividualListStream(String listId) async {
    final controller = _individualListControllers[listId];
    if (controller != null && !controller.isClosed) {
      final list = await getListById(listId);
      controller.add(list);
    }
  }

  /// Clean up individual list stream
  void _disposeIndividualListStream(String listId) {
    final controller = _individualListControllers[listId];
    if (controller != null) {
      controller.close();
      _individualListControllers.remove(listId);
      _individualListStreams.remove(listId);
    }
  }

  // ==========================================
  // CORE INTERFACE - Lists
  // ==========================================

  /// Create or update a shopping list
  Future<bool> upsertList(ShoppingList list) async {
    await init();

    final lists = await getAllLists();

    // Remove existing list with same ID if it exists
    lists.removeWhere((existingList) => existingList.id == list.id);

    // Add the new/updated list (sorting will be applied when displayed)
    lists.add(list);

    // Convert to JSON and save
    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    final success = await _prefs!.setString(_listsKey, jsonString);

    // Update streams if save was successful
    if (success) {
      await _updateListsStream();
      // Also update the individual list stream for this specific list
      await _updateIndividualListStream(list.id);
    }

    return success;
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    final lists = await getAllLists();
    lists.removeWhere((list) => list.id == id);

    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    final success = await _prefs!.setString(_listsKey, jsonString);

    // Update streams if delete was successful
    if (success) {
      await _updateListsStream();
      // Update the individual list stream to indicate the list no longer exists
      final controller = _individualListControllers[id];
      if (controller != null && !controller.isClosed) {
        controller.add(null);
      }
    }

    return success;
  }

  /// Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
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

  /// Get a specific list by ID
  Future<ShoppingList?> getListById(String id) async {
    final lists = await getAllLists();
    try {
      final list = lists.firstWhere((list) => list.id == id);
      // Apply sorting to the returned list for display on detail page
      return _applySortingToList(list);
    } catch (e) {
      return null;
    }
  }

  /// Get all lists as a stream (reactive)
  Stream<List<ShoppingList>> watchLists() {
    _initializeListsStream();
    return _listsStream!;
  }

  /// Get a specific list as a stream (reactive)
  Stream<ShoppingList?> watchList(String id) {
    _initializeIndividualListStream(id);
    return _individualListStreams[id]!;
  }

  // ==========================================
  // CORE INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    final list = await getListById(listId);
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

    return await upsertList(updatedList);
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    final list = await getListById(listId);
    if (list == null) return false;

    final updatedItems =
        list.items.map((item) {
          if (item.id == itemId) {
            // Determine if we're marking this item as completed
            final wasCompleted = item.isCompleted;
            final willBeCompleted = completed ?? item.isCompleted;

            // Set completedAt timestamp if the item is being marked as completed
            DateTime? completedAt = item.completedAt;
            if (!wasCompleted && willBeCompleted) {
              completedAt = DateTime.now();
            } else if (wasCompleted && !willBeCompleted) {
              // If uncompleting an item, clear the completedAt timestamp
              completedAt = null;
            }

            return ShoppingItem(
              id: item.id,
              name: name ?? item.name,
              quantity: quantity ?? item.quantity,
              isCompleted: willBeCompleted,
              createdAt: item.createdAt,
              completedAt: completedAt,
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

    return await upsertList(updatedList);
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
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

    return await upsertList(updatedList);
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    final list = await getListById(listId);
    if (list == null) return false;

    // Filter out completed items
    final remainingItems =
        list.items.where((item) => !item.isCompleted).toList();

    final updatedList = ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description,
      color: list.color,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
      items: remainingItems,
      members: list.members,
    );

    // The upsertList method will apply sorting, so no need to sort here
    final success = await upsertList(updatedList);

    if (success) {
      debugPrint(
        '✅ Successfully cleared ${list.items.length - remainingItems.length} completed items locally',
      );
    }

    return success;
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Clear all local data
  Future<void> clearAllData() async {
    await init();
    await _prefs!.remove(_listsKey);

    // Update streams to reflect cleared data
    await _updateListsStream();

    // Update all individual list streams with null (data cleared)
    for (final controller in _individualListControllers.values) {
      if (!controller.isClosed) {
        controller.add(null);
      }
    }

    debugPrint('🗑️ Local data cleared');
  }

  /// Clean up resources when no longer needed
  void dispose() {
    _listsController?.close();
    _listsController = null;
    _listsStream = null;

    // Dispose all individual list controllers
    for (final controller in _individualListControllers.values) {
      controller.close();
    }
    _individualListControllers.clear();
    _individualListStreams.clear();
  }

  /// Clean up individual list stream when no longer needed
  void disposeListStream(String listId) {
    _disposeIndividualListStream(listId);
  }

  /// Reset singleton instance for testing
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
  }

  // ==========================================
  // TEST HELPERS
  // ==========================================

  Future<List<ShoppingList>> getAllListsForTest() async {
    return await getAllLists();
  }

  Future<ShoppingList?> getListByIdForTest(String id) async {
    return await getListById(id);
  }

  Future<void> clearAllDataForTest() async {
    return await clearAllData();
  }
}
