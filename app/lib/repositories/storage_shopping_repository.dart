import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../services/storage_service.dart';
import 'shopping_repository.dart';

/// Concrete implementation of ShoppingRepository using StorageService
///
/// This adapter wraps the existing StorageService and provides it through
/// the repository interface. This allows ViewModels to depend on the abstract
/// repository interface while using the same underlying storage logic.
class StorageShoppingRepository implements ShoppingRepository {
  final StorageService _storageService;

  /// Create repository with a StorageService instance
  StorageShoppingRepository(this._storageService);

  /// Create repository with the default StorageService singleton
  StorageShoppingRepository.instance()
    : _storageService = StorageService.instance;

  // ==========================================
  // LIST OPERATIONS
  // ==========================================

  @override
  Future<bool> createList(ShoppingList list) {
    return _storageService.createList(list);
  }

  @override
  Future<bool> updateList(ShoppingList list) {
    return _storageService.updateList(list);
  }

  @override
  Future<bool> deleteList(String id) {
    return _storageService.deleteList(id);
  }

  @override
  Stream<List<ShoppingList>> watchLists() {
    return _storageService.watchLists();
  }

  @override
  Stream<ShoppingList?> watchList(String id) {
    return _storageService.watchList(id);
  }

  // ==========================================
  // ITEM OPERATIONS
  // ==========================================

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    return _storageService.addItem(listId, item);
  }

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return _storageService.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    return _storageService.deleteItem(listId, itemId);
  }

  @override
  Future<bool> clearCompleted(String listId) {
    return _storageService.clearCompleted(listId);
  }

  // ==========================================
  // SHARING OPERATIONS
  // ==========================================

  @override
  Future<ShareResult> shareList(String listId, String email) {
    return _storageService.shareList(listId, email);
  }

  // ==========================================
  // MEMBER OPERATIONS
  // ==========================================

  @override
  Future<bool> removeMember(String listId, String userId) {
    return _storageService.removeMember(listId, userId);
  }

  // ==========================================
  // SYNC & STREAM MANAGEMENT
  // ==========================================

  @override
  Future<void> sync() {
    return _storageService.sync();
  }

  @override
  Future<DateTime?> getLastSyncTime() {
    return _storageService.getLastSyncTime();
  }

  @override
  void disposeListStream(String id) {
    _storageService.disposeListStream(id);
  }

  // ==========================================
  // LIFECYCLE
  // ==========================================

  @override
  Future<void> init() {
    return _storageService.init();
  }

  @override
  void dispose() {
    // StorageService doesn't currently have a dispose method
    // If needed in future, we can add it here
  }
}
