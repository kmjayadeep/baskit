import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../services/storage_service.dart' show ShareResult;

/// Abstract repository interface for shopping lists and items
///
/// This interface defines all data operations for shopping lists and items,
/// abstracting away the underlying storage implementation (local vs Firebase).
/// ViewModels should depend on this interface rather than concrete implementations.
abstract class ShoppingRepository {
  // ==========================================
  // LIST OPERATIONS
  // ==========================================

  /// Create a new shopping list
  Future<bool> createList(ShoppingList list);

  /// Update an existing shopping list
  Future<bool> updateList(ShoppingList list);

  /// Delete a shopping list by ID
  Future<bool> deleteList(String id);

  /// Watch all shopping lists (reactive stream)
  Stream<List<ShoppingList>> watchLists();

  /// Watch a specific shopping list by ID (reactive stream)
  Stream<ShoppingList?> watchList(String id);

  // ==========================================
  // ITEM OPERATIONS
  // ==========================================

  /// Add an item to a shopping list
  Future<bool> addItem(String listId, ShoppingItem item);

  /// Update an item in a shopping list
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  });

  /// Delete an item from a shopping list
  Future<bool> deleteItem(String listId, String itemId);

  /// Clear all completed items from a list
  Future<bool> clearCompleted(String listId);

  // ==========================================
  // SHARING OPERATIONS
  // ==========================================

  /// Share a list with another user by email
  Future<ShareResult> shareList(String listId, String email);

  // ==========================================
  // MEMBER OPERATIONS
  // ==========================================

  /// Remove a member from a list
  Future<bool> removeMember(String listId, String userId);

  // ==========================================
  // SYNC & STREAM MANAGEMENT
  // ==========================================

  /// Force synchronization with remote storage
  Future<void> sync();

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTime();

  /// Dispose/cleanup list stream for a specific list ID
  void disposeListStream(String id);

  // ==========================================
  // LIFECYCLE
  // ==========================================

  /// Initialize the repository
  Future<void> init();

  /// Dispose/cleanup all resources
  void dispose();
}
