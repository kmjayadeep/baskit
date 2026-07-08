import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/share_result.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../services/crash_reporting_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/migration_service.dart';
import 'firestore_shopping_repository.dart';
import 'local_shopping_repository.dart';
import 'shopping_repository.dart';

/// Routes shopping operations to local storage for guests and Firestore for
/// authenticated users.
class StorageShoppingRepository implements ShoppingRepository {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static bool? _useLocalOverrideForTest;

  final LocalStorageService _localStorage;
  final ShoppingRepository _localRepository;
  final ShoppingRepository _cloudRepository;
  late final MigrationService _migrationService;

  StorageShoppingRepository({
    required LocalStorageService localStorage,
    required ShoppingRepository localRepository,
    required ShoppingRepository cloudRepository,
  }) : _localStorage = localStorage,
       _localRepository = localRepository,
       _cloudRepository = cloudRepository {
    _migrationService = MigrationService(
      localStorage: _localStorage,
      cloudRepository: _cloudRepository,
    );
  }

  factory StorageShoppingRepository.instance() {
    final localStorage = LocalStorageService.instance;
    return StorageShoppingRepository(
      localStorage: localStorage,
      localRepository: LocalShoppingRepository(localStorage),
      cloudRepository: const FirestoreShoppingRepository(),
    );
  }

  bool get _useLocal =>
      _useLocalOverrideForTest ?? FirebaseAuthService.isAnonymous;

  ShoppingRepository get _activeRepository =>
      _useLocal ? _localRepository : _cloudRepository;

  @override
  Future<bool> createList(ShoppingList list) async {
    if (_useLocal) return _localRepository.createList(list);

    return _runCloudWrite('create', () async {
      await _migrationService.ensureComplete();
      return _cloudRepository.createList(list);
    });
  }

  @override
  Future<bool> updateList(ShoppingList list) {
    if (_useLocal) return _localRepository.updateList(list);
    return _runCloudWrite('update', () => _cloudRepository.updateList(list));
  }

  @override
  Future<bool> deleteList(String id) {
    if (_useLocal) return _localRepository.deleteList(id);
    return _runCloudWrite('delete', () => _cloudRepository.deleteList(id));
  }

  @override
  Stream<List<ShoppingList>> watchLists() {
    if (_useLocal) return _localRepository.watchLists();
    return _watchCloudLists();
  }

  @override
  Stream<ShoppingList?> watchList(String id) {
    if (_useLocal) return _localRepository.watchList(id);
    return _watchCloudList(id);
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    return _activeRepository.addItem(listId, item);
  }

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) {
    return _activeRepository.updateItem(
      listId,
      itemId,
      name: name,
      quantity: quantity,
      completed: completed,
    );
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    return _activeRepository.deleteItem(listId, itemId);
  }

  @override
  Future<bool> clearCompleted(String listId) {
    return _activeRepository.clearCompleted(listId);
  }

  @override
  Future<ShareResult> shareList(String listId, String email) {
    return _activeRepository.shareList(listId, email);
  }

  @override
  Future<bool> removeMember(String listId, String userId) {
    if (_useLocal) return _localRepository.removeMember(listId, userId);
    return _runCloudWrite(
      'remove member',
      () => _cloudRepository.removeMember(listId, userId),
    );
  }

  @override
  Future<void> sync() async {
    if (_useLocal) {
      await _localRepository.sync();
      debugPrint('✅ Manual refresh complete');
      return;
    }

    await _updateLastSyncTime();
    debugPrint('✅ Manual sync complete');
  }

  Future<void> clearUserData({String? migratedUserId}) async {
    await _localStorage.clearAllData();
    if (migratedUserId != null) {
      await _migrationService.clearForUserId(migratedUserId);
    } else if (!_useLocal) {
      await _migrationService.clearForCurrentUser();
    }
    debugPrint('🗑️ User data cleared completely');
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  void disposeListStream(String id) {
    _activeRepository.disposeListStream(id);
  }

  @override
  Future<void> init() async {
    await _localRepository.init();
    await _cloudRepository.init();
  }

  @override
  void dispose() {
    _localRepository.dispose();
    _cloudRepository.dispose();
  }

  Stream<List<ShoppingList>> _watchCloudLists() async* {
    try {
      await _prepareCloudUserContext();
      await _migrationService.ensureComplete();
      yield* _cloudRepository.watchLists();
    } catch (error) {
      debugPrint('❌ Firebase stream error: $error');
      yield [];
    }
  }

  Stream<ShoppingList?> _watchCloudList(String id) async* {
    try {
      await _prepareCloudUserContext();
      await _migrationService.ensureComplete();
      yield* _cloudRepository.watchList(id);
    } catch (error) {
      debugPrint('❌ Firebase list stream error: $error');
      yield null;
    }
  }

  Future<void> _prepareCloudUserContext() async {
    await FirestoreService.initializeUserProfile();
  }

  Future<bool> _runCloudWrite(
    String action,
    Future<bool> Function() operation,
  ) async {
    try {
      final success = await operation();
      if (success) await _updateLastSyncTime();
      return success;
    } catch (error, stackTrace) {
      unawaited(
        CrashReportingService.recordNonFatal(
          context: 'cloud_repository_write',
          error: error,
          stackTrace: stackTrace,
          metadata: {'operation': action.replaceAll(' ', '_')},
        ),
      );
      debugPrint('❌ Firebase $action failed: $error');
      return false;
    }
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isMigrationCompleteForTest() {
    return _migrationService.isComplete();
  }

  Future<void> markMigrationCompleteForTest() {
    return _migrationService.markComplete();
  }

  Future<void> clearLocalDataForTest() {
    return _localStorage.clearAllDataForTest();
  }

  Future<bool> saveListLocallyForTest(ShoppingList list) {
    return _localStorage.upsertList(list);
  }

  Future<List<ShoppingList>> getAllListsLocallyForTest() {
    return _localStorage.getAllListsForTest();
  }

  Future<ShoppingList?> getListByIdLocallyForTest(String id) {
    return _localStorage.getListByIdForTest(id);
  }

  static void setUseLocalOverrideForTest(bool? value) {
    _useLocalOverrideForTest = value;
  }

  static void resetOverridesForTest() {
    _useLocalOverrideForTest = null;
  }
}
