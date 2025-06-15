import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';

class StorageService {
  static const String _listsKey = 'shopping_lists';
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

  // Save a shopping list
  Future<bool> saveList(ShoppingList list) async {
    await init();

    final lists = await getAllLists();

    // Remove existing list with same ID if it exists
    lists.removeWhere((existingList) => existingList.id == list.id);

    // Add the new/updated list
    lists.add(list);

    // Convert to JSON and save
    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    return await _prefs!.setString(_listsKey, jsonString);
  }

  // Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
    await init();

    final jsonString = _prefs!.getString(_listsKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ShoppingList.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  // Get a specific list by ID
  Future<ShoppingList?> getListById(String id) async {
    final lists = await getAllLists();
    try {
      return lists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete a list
  Future<bool> deleteList(String id) async {
    final lists = await getAllLists();
    lists.removeWhere((list) => list.id == id);

    final listsJson = lists.map((list) => list.toJson()).toList();
    final jsonString = jsonEncode(listsJson);

    return await _prefs!.setString(_listsKey, jsonString);
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
}
