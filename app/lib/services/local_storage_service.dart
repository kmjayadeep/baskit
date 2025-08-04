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

  /// Delete a shopping list (soft delete using deletedAt timestamp)
  Future<bool> deleteList(String id) async {
    final list = _listsBox.get(id);
    if (list == null) {
      debugPrint(
        '🗑️ List deleted from Hive: $id',
      ); // Keep same log for test compatibility
      _emitListsUpdate();
      _emitListUpdate(id, null);
      return true; // Return true for non-existent lists (idempotent behavior)
    }

    try {
      // Soft delete: mark with deletedAt timestamp
      final deletedList = list.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _listsBox.put(id, deletedList);
      debugPrint(
        '🗑️ List deleted from Hive: $id',
      ); // Keep same log for test compatibility

      _emitListsUpdate();
      _emitListUpdate(
        id,
        null,
      ); // Emit null to indicate list is no longer available

      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete list from Hive: $e');
      return false;
    }
  }

  /// Get all shopping lists (excluding soft-deleted ones)
  Future<List<ShoppingList>> getAllLists() async {
    final lists = _getActiveLists();
    debugPrint('🔍 Retrieved ${lists.length} lists from Hive');
    return lists;
  }

  /// Helper method to get active (non-deleted) lists, sorted by updatedAt
  List<ShoppingList> _getActiveLists() {
    final allLists = _listsBox.values.toList();
    // Filter out soft-deleted lists
    final activeLists =
        allLists.where((list) => list.deletedAt == null).toList();
    // Sort by updatedAt descending (most recent first)
    activeLists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return activeLists;
  }

  /// Get a specific list by ID (returns null if soft-deleted, filters out deleted items)
  Future<ShoppingList?> getListById(String id) async {
    final list = _listsBox.get(id);
    // Return null if list doesn't exist or is soft-deleted
    if (list == null || list.deletedAt != null) {
      debugPrint('🔍 Retrieved list from Hive: not found');
      return null;
    }
    debugPrint('🔍 Retrieved list from Hive: ${list.name}');
    // Filter out soft-deleted items for UI display
    return _applySortingAndFilteringForDisplay(list);
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

      // Filter out soft-deleted lists
      final activeList = (currentList?.deletedAt == null) ? currentList : null;

      debugPrint(
        '🔍 watchList($id) retrieved: ${activeList?.name ?? "not found"}',
      );

      // Delay emission until after StreamBuilder subscribes
      Future.microtask(() {
        if (!_listControllers[id]!.isClosed) {
          debugPrint('🔍 watchList($id) adding to stream (delayed)');
          _emitListUpdate(id, activeList);
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

  /// Delete an item from a shopping list (soft delete using deletedAt timestamp)
  Future<bool> deleteItem(String listId, String itemId) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      // Find the item to delete
      final itemIndex = list.items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        debugPrint('❌ Item not found: $itemId');
        return false;
      }

      // Soft delete: mark with deletedAt timestamp
      final updatedItems = List<ShoppingItem>.from(list.items);
      final currentItem = updatedItems[itemIndex];
      updatedItems[itemIndex] = currentItem.copyWith(deletedAt: DateTime.now());

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving (will filter out deleted items)
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

  /// Clear all completed items from a list (soft delete using deletedAt timestamp)
  Future<bool> clearCompleted(String listId) async {
    final list = _listsBox.get(listId);
    if (list == null) {
      debugPrint('❌ List not found: $listId');
      return false;
    }

    try {
      // Find completed items that aren't already soft-deleted
      final completedItems =
          list.items
              .where((item) => item.isCompleted && item.deletedAt == null)
              .toList();

      if (completedItems.isEmpty) {
        debugPrint('✅ Successfully cleared 0 completed items');
        return true;
      }

      // Soft delete all completed items
      final updatedItems =
          list.items.map((item) {
            if (item.isCompleted && item.deletedAt == null) {
              return item.copyWith(deletedAt: DateTime.now());
            }
            return item;
          }).toList();

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sort items before saving (will filter out deleted items)
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

  /// Emit lists update to all subscribers (excluding soft-deleted lists)
  void _emitListsUpdate() {
    final activeLists = _getActiveLists();
    _listsController.add(activeLists);
  }

  /// Emit individual list update
  void _emitListUpdate(String listId, ShoppingList? list) {
    _listControllers[listId]?.add(list);
  }

  /// Sort shopping items according to requirements:
  /// - Incomplete items at top, sorted by creation date (newest first)
  /// - Completed items at bottom, sorted by completion date (most recently completed first)
  /// - Preserves soft-deleted items in storage but filters them for display
  List<ShoppingItem> _sortItems(List<ShoppingItem> items) {
    // Separate active and soft-deleted items
    final activeItems = items.where((item) => item.deletedAt == null).toList();
    final deletedItems = items.where((item) => item.deletedAt != null).toList();

    final incompleteItems =
        activeItems.where((item) => !item.isCompleted).toList();
    final completedItems =
        activeItems.where((item) => item.isCompleted).toList();

    // Sort incomplete items by creation date (newest first)
    incompleteItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Sort completed items by completion date (most recently completed first)
    // Fall back to creation date if completedAt is null
    completedItems.sort((a, b) {
      final aCompletedAt = a.completedAt ?? a.createdAt;
      final bCompletedAt = b.completedAt ?? b.createdAt;
      return bCompletedAt.compareTo(aCompletedAt);
    });

    // Return active items first (for UI display), then preserve deleted items (for sync)
    return [...incompleteItems, ...completedItems, ...deletedItems];
  }

  /// Apply sorting to a shopping list for storage (preserves ALL items including soft-deleted)
  ShoppingList _applySortingToList(ShoppingList list) {
    final sortedItems = _sortItems(list.items);
    return list.copyWith(items: sortedItems);
  }

  /// Apply sorting and filtering for UI display (only active items)
  ShoppingList _applySortingAndFilteringForDisplay(ShoppingList list) {
    final activeItems = _getActiveItems(list.items);
    final sortedActiveItems = _sortItems(activeItems);
    return list.copyWith(items: sortedActiveItems);
  }

  /// Get only active (non-deleted) items from a list for UI display
  List<ShoppingItem> _getActiveItems(List<ShoppingItem> items) {
    return items.where((item) => item.deletedAt == null).toList();
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

  /// Get raw list data including soft-deleted items (for testing soft delete behavior)
  Future<ShoppingList?> getRawListByIdForTest(String id) async {
    return _listsBox.get(id);
  }

  /// Get all raw list data including soft-deleted items (for testing soft delete behavior)
  Future<List<ShoppingList>> getRawListsForTest() async {
    final lists = _listsBox.values.toList();
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lists;
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
