import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

/// Manages reactive streams and CRUD operations for shopping lists and items
class LocalStorageService {
  static const String _listsBoxName = 'shopping_lists';
  // Hive box for storing shopping lists
  late Box<ShoppingList> _listsBox;

  // Stream controllers for reactive updates
  final StreamController<List<ShoppingList>> _listsController =
      StreamController<List<ShoppingList>>.broadcast();
  final Map<String, StreamController<ShoppingList?>> _listControllers = {};

  /// Singleton private constructor
  LocalStorageService._();

  /// Singleton instance
  static LocalStorageService? _instance;

  /// Singleton getter
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  /// Initialize Hive and register type adapters
  Future<void> init() async {
    try {
      await Hive.initFlutter();
    } catch (e) {
      debugPrint('⚠️ Hive.initFlutter() failed: $e');
    }

    // Register adapters (these are safe to call multiple times)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }

    _listsBox = await Hive.openBox<ShoppingList>(_listsBoxName);
    debugPrint('🗄️ Hive initialized with ${_listsBox.length} lists');
  }

  // ==========================================
  // CORE INTERFACE - Lists
  // ==========================================

  /// Create or update a shopping list (upsert operation)
  Future<bool> upsertList(ShoppingList list) async {
    try {
      // Sort items before saving
      final sortedList = _applySortingToList(list);
      await _listsBox.put(sortedList.id, sortedList);
      debugPrint('✅ List "${sortedList.name}" saved to Hive');

      _emitListsUpdate();
      _emitListUpdate(sortedList.id, sortedList);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to save list to Hive: $e');
      return false;
    }
  }

  /// Delete a shopping list
  Future<bool> deleteList(String id) async {
    try {
      await _listsBox.delete(id);
      debugPrint('🗑️ List deleted from Hive: $id');

      _emitListsUpdate();
      _emitListUpdate(id, null);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete list from Hive: $e');
      return false;
    }
  }

  /// Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
    final lists = _listsBox.values.toList();
    // Sort by updatedAt descending (most recent first)
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    debugPrint('🔍 Retrieved ${lists.length} lists from Hive');
    return lists;
  }

  /// Get a specific list by ID
  Future<ShoppingList?> getListById(String id) async {
    final list = _listsBox.get(id);
    debugPrint('🔍 Retrieved list from Hive: ${list?.name ?? "not found"}');
    return list;
  }

  /// Watch all lists (reactive stream)
  Stream<List<ShoppingList>> watchLists() {
    // Emit current data when stream is subscribed to
    Future.microtask(() {
      if (!_listsController.isClosed) {
        _emitListsUpdate();
      }
    });

    return _listsController.stream;
  }

  /// Watch a specific list (reactive stream)
  Stream<ShoppingList?> watchList(String id) {
    // Create controller if it doesn't exist
    _listControllers[id] ??= StreamController<ShoppingList?>.broadcast();

    // Only emit current value after stream is subscribed to
    try {
      // Check if the box is available (will throw if not initialized)
      final currentList = _listsBox.get(id);

      debugPrint(
        '🔍 watchList($id) retrieved: ${currentList?.name ?? "not found"}',
      );

      // Delay emission until after StreamBuilder subscribes
      Future.microtask(() {
        if (!_listControllers[id]!.isClosed) {
          debugPrint('🔍 watchList($id) adding to stream (delayed)');
          _emitListUpdate(id, currentList);
        }
      });
    } catch (e) {
      // Service not initialized yet - that's okay, init() will call _emitListUpdate() later
      debugPrint(
        '⚠️ LocalStorageService not initialized yet for watchList($id), will emit data after init()',
      );
    }

    return _listControllers[id]!.stream;
  }

  // ==========================================
  // CORE INTERFACE - Items
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      final updatedItems = List<ShoppingItem>.from(list.items)..add(item);
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving
      final sortedList = _applySortingToList(updatedList);
      await _listsBox.put(listId, sortedList);
      debugPrint('✅ Item "${item.name}" added to list "${list.name}"');

      _emitListsUpdate();
      _emitListUpdate(listId, sortedList);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to add item: $e');
      return false;
    }
  }

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      final itemIndex = list.items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        debugPrint('❌ Item not found: $itemId');
        return false;
      }

      final updatedItems = List<ShoppingItem>.from(list.items);
      final currentItem = updatedItems[itemIndex];

      updatedItems[itemIndex] = currentItem.copyWith(
        name: name,
        quantity: quantity,
        isCompleted: completed,
        completedAt: completed == true ? DateTime.now() : null,
        clearCompletedAt: completed == false,
      );

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving
      final sortedList = _applySortingToList(updatedList);
      await _listsBox.put(listId, sortedList);
      debugPrint('✅ Item updated in list "${list.name}"');

      _emitListsUpdate();
      _emitListUpdate(listId, sortedList);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to update item: $e');
      return false;
    }
  }

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      // Check if the item exists before trying to delete it
      final itemExists = list.items.any((item) => item.id == itemId);
      if (!itemExists) {
        debugPrint('❌ Item not found: $itemId');
        return false;
      }

      final updatedItems =
          list.items.where((item) => item.id != itemId).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving
      final sortedList = _applySortingToList(updatedList);
      await _listsBox.put(listId, sortedList);
      debugPrint('🗑️ Item deleted from list "${list.name}"');

      _emitListsUpdate();
      _emitListUpdate(listId, sortedList);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete item: $e');
      return false;
    }
  }

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      final completedItems =
          list.items.where((item) => item.isCompleted).toList();
      final updatedItems =
          list.items.where((item) => !item.isCompleted).toList();

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving
      final sortedList = _applySortingToList(updatedList);
      await _listsBox.put(listId, sortedList);
      debugPrint(
        '✅ Successfully cleared ${completedItems.length} completed items',
      );

      _emitListsUpdate();
      _emitListUpdate(listId, sortedList);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to clear completed items: $e');
      return false;
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Clear all local data
  Future<void> clearAllData() async {
    try {
      await _listsBox.clear();
      debugPrint('🗑️ All local data cleared from Hive');

      _emitListsUpdate();
      // Clear all individual list streams
      for (final controller in _listControllers.values) {
        controller.add(null);
      }
    } catch (e) {
      debugPrint('❌ Failed to clear local data: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _listsController.close();
    for (final controller in _listControllers.values) {
      controller.close();
    }
    _listControllers.clear();
  }

  /// Clean up individual list stream
  void disposeListStream(String listId) {
    _listControllers[listId]?.close();
    _listControllers.remove(listId);
  }

  /// Manually refresh all streams (useful for pull-to-refresh)
  void refreshStreams() {
    _emitListsUpdate();
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Emit lists update to all subscribers
  void _emitListsUpdate() {
    final lists = _listsBox.values.toList();
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _listsController.add(lists);
  }

  /// Emit individual list update
  void _emitListUpdate(String listId, ShoppingList? list) {
    _listControllers[listId]?.add(list);
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
    return list.copyWith(items: sortedItems);
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

  /// Reset singleton instance for testing
  static void resetInstanceForTest() {
    _instance?.dispose();
    _instance = null;
  }
}
