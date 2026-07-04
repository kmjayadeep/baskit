import '../models/share_result.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../services/local_storage_service.dart';
import 'shopping_repository.dart';

/// Local Hive-backed repository used for guest/local-first mode.
class LocalShoppingRepository implements ShoppingRepository {
  final LocalStorageService _localStorage;

  LocalShoppingRepository(this._localStorage);

  LocalShoppingRepository.instance()
    : _localStorage = LocalStorageService.instance;

  @override
  Future<bool> createList(ShoppingList list) => _localStorage.upsertList(list);

  @override
  Future<bool> updateList(ShoppingList list) => _localStorage.upsertList(list);

  @override
  Future<bool> deleteList(String id) => _localStorage.deleteList(id);

  @override
  Stream<List<ShoppingList>> watchLists() => _localStorage.watchLists();

  @override
  Stream<ShoppingList?> watchList(String id) => _localStorage.watchList(id);

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    return _localStorage.addItem(listId, item);
  }

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return _localStorage.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    return _localStorage.deleteItem(listId, itemId);
  }

  @override
  Future<bool> clearCompleted(String listId) {
    return _localStorage.clearCompleted(listId);
  }

  @override
  Future<ShareResult> shareList(String listId, String email) async {
    return const ShareResult.error(
      'You need to be signed in to share lists with others.',
    );
  }

  @override
  Future<bool> removeMember(String listId, String userId) {
    return _localStorage.removeMemberFromList(listId, userId);
  }

  @override
  Future<void> sync() async {
    _localStorage.refreshStreams();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  void disposeListStream(String id) {
    _localStorage.disposeListStream(id);
  }

  @override
  Future<void> init() {
    return _localStorage.init();
  }

  @override
  void dispose() {
    _localStorage.dispose();
  }
}
