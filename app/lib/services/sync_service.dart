import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../repositories/local_storage_repository.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';

/// Sync state enumeration for tracking synchronization status
enum SyncState { idle, syncing, synced, error }

/// Action to take during synchronization based on timestamp comparison
enum SyncAction { noAction, useLocal, useRemote, mergeRequired }

/// Core synchronization service implementing local-first architecture
/// Manages bidirectional sync between local Hive storage and Firebase
class SyncService with WidgetsBindingObserver {
  static SyncService? _instance;

  // Dependencies
  final LocalStorageRepository _localRepo = LocalStorageRepository.instance;

  // Subscription management
  StreamSubscription<List<ShoppingList>>? _localListsSubscription;
  StreamSubscription<List<ShoppingList>>? _remoteListsSubscription;
  final Map<String, StreamSubscription<ShoppingList?>> _localListSubscriptions =
      {};
  StreamSubscription<User?>? _authStateSubscription;

  // State management
  final ValueNotifier<SyncState> _syncStateNotifier = ValueNotifier(
    SyncState.idle,
  );
  String? _lastErrorMessage;

  // App lifecycle tracking
  bool _wasAppPaused = false;

  /// Private constructor for singleton pattern
  SyncService._();

  /// Singleton getter
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  /// Initialize the sync service and start listening to auth changes
  /// Should be called once during app startup
  void initialize() {
    debugPrint('🔄 Initializing SyncService...');

    // Register app lifecycle observer for resume sync
    WidgetsBinding.instance.addObserver(this);

    // Listen to authentication state changes
    _authStateSubscription = FirebaseAuthService.authStateChanges.listen(
      (user) async {
        final isAuthenticated =
            user != null && !FirebaseAuthService.isAnonymous;
        final userType =
            FirebaseAuthService.isAnonymous ? 'anonymous' : 'signed-in';
        debugPrint(
          '🔄 Auth state changed - isAuthenticated: $isAuthenticated ($userType)',
        );

        if (isAuthenticated) {
          // Ensure user profile exists for authenticated users (including existing sessions)
          await FirestoreService.initializeUserProfile();
          // User signed in (non-anonymous) - start sync
          await startSync();
        } else {
          // User signed out or is anonymous - stop sync (local-only mode)
          stopSync();
        }
      },
      onError: (error) {
        debugPrint('❌ Error in auth state stream: $error');
      },
    );

    debugPrint('✅ SyncService initialized');
  }

  /// Dispose of the sync service and cancel all subscriptions
  void dispose() {
    debugPrint('🔄 Disposing SyncService...');

    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    stopSync();
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _syncStateNotifier.dispose();
    debugPrint('✅ SyncService disposed');
  }

  // ==========================================
  // BIDIRECTIONAL SYNC IMPLEMENTATION
  // ==========================================

  /// BIDIRECTIONAL SYNC ARCHITECTURE:
  ///
  /// 1. LOCAL-TO-FIREBASE: Watches local Hive changes and pushes to Firebase
  ///    - Handles creation, updates, and soft deletes
  ///    - Maintains ID consistency between local and Firebase
  ///
  /// 2. FIREBASE-TO-LOCAL: Watches Firebase changes and merges with local data
  ///    - Includes shared lists from other users
  ///    - Uses sophisticated conflict resolution (mergeLists)
  ///    - Handles new lists, updates, and deletions
  ///
  /// 3. CONFLICT RESOLUTION: Granular merge strategy
  ///    - List properties: newest timestamp wins
  ///    - Items: individual item-level merging with timestamp comparison
  ///    - Soft deletes: proper propagation and cleanup
  ///
  /// This ensures eventual consistency across all devices and users while
  /// preserving local-first behavior with immediate UI responsiveness.

  // ==========================================
  // SYNC LIFECYCLE MANAGEMENT
  // ==========================================

  /// Start bidirectional synchronization
  /// Should be called when user is authenticated
  Future<void> startSync() async {
    if (FirebaseAuthService.currentUser == null) {
      debugPrint('🔄 Cannot start sync - user not authenticated');
      return;
    }

    if (_localListsSubscription != null) {
      debugPrint('🔄 Sync already running');
      return;
    }

    debugPrint('🔄 Starting bidirectional sync...');
    _updateSyncState(SyncState.syncing);

    try {
      await _startLocalToFirebaseSync();
      await _startFirebaseToLocalSync();
      debugPrint('✅ Bidirectional sync started successfully');
      _updateSyncState(SyncState.synced);
    } catch (e) {
      debugPrint('❌ Failed to start sync: $e');
      _updateSyncState(SyncState.error, e.toString());
    }
  }

  /// Stop all synchronization operations
  void stopSync() {
    debugPrint('🔄 Stopping sync...');

    _localListsSubscription?.cancel();
    _localListsSubscription = null;

    _remoteListsSubscription?.cancel();
    _remoteListsSubscription = null;

    for (final subscription in _localListSubscriptions.values) {
      subscription.cancel();
    }
    _localListSubscriptions.clear();

    _updateSyncState(SyncState.idle);
    debugPrint('✅ Sync stopped');
  }

  /// Start local-to-Firebase synchronization
  Future<void> _startLocalToFirebaseSync() async {
    final userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Subscribe to local lists changes (including deleted ones for proper sync)
    _localListsSubscription = _localRepo.watchAllListsIncludingDeleted().listen(
      (localLists) async {
        debugPrint(
          '🔄 Local lists changed, syncing ${localLists.length} lists to Firebase (including deleted)',
        );
        await _syncLocalListsToFirebase(localLists, userId);
      },
      onError: (error) {
        debugPrint('❌ Error in local lists stream: $error');
        _updateSyncState(SyncState.error, error.toString());
      },
    );
  }

  /// Start Firebase-to-local synchronization
  Future<void> _startFirebaseToLocalSync() async {
    final userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Subscribe to Firebase lists changes (includes owned + shared lists)
    _remoteListsSubscription = FirestoreService.getUserLists().listen(
      (remoteLists) async {
        debugPrint(
          '☁️ Firebase lists changed, merging ${remoteLists.length} lists with local data',
        );
        await _syncFirebaseListsToLocal(remoteLists);
      },
      onError: (error) {
        debugPrint('❌ Error in Firebase lists stream: $error');
        _updateSyncState(SyncState.error, error.toString());
      },
    );
  }

  /// Sync local lists to Firebase
  Future<void> _syncLocalListsToFirebase(
    List<ShoppingList> localLists,
    String userId,
  ) async {
    for (final localList in localLists) {
      try {
        // Handle deleted lists
        if (localList.deletedAt != null) {
          await _handleDeletedList(localList, userId);
          continue;
        }

        // Handle active lists - create or update
        await _handleActiveList(localList, userId);
      } catch (e) {
        debugPrint('❌ Failed to sync list ${localList.id}: $e');
        // Continue with other lists rather than failing completely
      }
    }
  }

  /// Handle syncing a deleted list to Firebase
  Future<void> _handleDeletedList(ShoppingList localList, String userId) async {
    debugPrint('🗑️ Syncing deleted list ${localList.id} to Firebase');

    try {
      // Delete from Firebase
      await FirestoreService.deleteList(localList.id);

      // Permanently remove from local storage (hard delete)
      await _localRepo.permanentlyDeleteList(localList.id);

      debugPrint('✅ Successfully deleted list ${localList.id}');
    } catch (e) {
      debugPrint('❌ Failed to delete list ${localList.id}: $e');
      rethrow;
    }
  }

  /// Sync Firebase lists to local storage with conflict resolution
  Future<void> _syncFirebaseListsToLocal(List<ShoppingList> remoteLists) async {
    try {
      // Get current local lists
      final localLists = await _localRepo.getAllLists();

      // Create maps for efficient lookup
      final Map<String, ShoppingList> localListsMap = {
        for (final list in localLists) list.id: list,
      };
      final Map<String, ShoppingList> remoteListsMap = {
        for (final list in remoteLists) list.id: list,
      };

      // Process each remote list
      for (final remoteList in remoteLists) {
        final localList = localListsMap[remoteList.id];

        if (localList == null) {
          // New list from Firebase - could be a shared list or new list from another device
          debugPrint('📥 Adding new list from Firebase: ${remoteList.name}');
          await _localRepo.upsertList(remoteList);
        } else {
          // List exists locally - merge using conflict resolution
          debugPrint('🔄 Merging list: ${remoteList.name}');
          final mergedList = mergeLists(
            localList: localList,
            remoteList: remoteList,
          );

          // Only update if the merged result is different from local
          if (_shouldUpdateLocal(localList, mergedList)) {
            debugPrint('💾 Updating local list: ${mergedList.name}');
            await _localRepo.upsertList(mergedList);
          } else {
            debugPrint('✅ Local list is up to date: ${localList.name}');
          }
        }
      }

      // Handle lists that exist locally but not in Firebase (potential deletions)
      for (final localList in localLists) {
        if (!remoteListsMap.containsKey(localList.id) &&
            localList.deletedAt == null) {
          // List exists locally but not remotely - could be:
          // 1. Deleted by another user/device
          // 2. Local-only list not yet synced
          // 3. Sharing permission revoked

          // For now, we'll be conservative and keep local lists
          // TODO: In future, we could add more sophisticated logic here
          debugPrint(
            '⚠️ Local list ${localList.name} not found in Firebase - keeping local version',
          );
        }
      }

      debugPrint('✅ Firebase-to-local sync completed successfully');
    } catch (e) {
      debugPrint('❌ Failed to sync Firebase lists to local: $e');
      // Don't rethrow - we want to continue with other sync operations
    }
  }

  /// Check if the local list should be updated with the merged result
  bool _shouldUpdateLocal(ShoppingList localList, ShoppingList mergedList) {
    // Check if any significant properties have changed
    return localList.name != mergedList.name ||
        localList.description != mergedList.description ||
        localList.color != mergedList.color ||
        localList.updatedAt != mergedList.updatedAt ||
        localList.deletedAt != mergedList.deletedAt ||
        !_areItemListsEqual(localList.items, mergedList.items);
  }

  /// Compare two item lists for equality
  bool _areItemListsEqual(List<ShoppingItem> list1, List<ShoppingItem> list2) {
    if (list1.length != list2.length) return false;

    // Create map for efficient comparison
    final map2 = {for (final item in list2) item.id: item};

    // Check if all items in list1 exist and are equal in list2
    for (final item1 in list1) {
      final item2 = map2[item1.id];
      if (item2 == null || !_areItemsEqual(item1, item2)) {
        return false;
      }
    }

    return true;
  }

  /// Compare two items for equality
  bool _areItemsEqual(ShoppingItem item1, ShoppingItem item2) {
    return item1.id == item2.id &&
        item1.name == item2.name &&
        item1.isCompleted == item2.isCompleted &&
        item1.createdAt == item2.createdAt &&
        item1.deletedAt == item2.deletedAt;
  }

  /// Handle syncing an active list to Firebase
  Future<void> _handleActiveList(ShoppingList localList, String userId) async {
    debugPrint('📝 Syncing active list ${localList.id} to Firebase');

    try {
      // Create or update the list in Firebase using the same ID
      final result = await FirestoreService.createList(localList);

      if (result != null) {
        debugPrint('✅ Successfully synced list ${localList.id} to Firebase');
        // IDs are now consistent - no mapping needed!
        // Note: createList() already handles items, so no additional item sync needed
      } else {
        debugPrint(
          '⚠️ createList returned null for ${localList.id} - trying update instead',
        );
        // createList returned null, might be Firebase unavailable or list already exists
        // Try updating instead
        throw Exception('createList returned null - attempting update');
      }
    } catch (e) {
      // If creation fails, the document might already exist - try updating instead
      debugPrint('⚠️ Create failed for ${localList.id}, attempting update: $e');

      try {
        // Update list metadata
        final updateSuccess = await FirestoreService.updateList(
          localList.id,
          name: localList.name,
          description: localList.description,
          color: localList.color,
        );

        if (updateSuccess) {
          debugPrint(
            '✅ Successfully updated list metadata ${localList.id} in Firebase',
          );

          // Now sync the items
          await _syncListItemsToFirebase(localList);
          debugPrint('✅ Successfully synced items for list ${localList.id}');
        } else {
          debugPrint('❌ Failed to update list ${localList.id} in Firebase');
        }
      } catch (updateError) {
        debugPrint('❌ Failed to sync list ${localList.id}: $updateError');
        // Don't rethrow - we want to continue syncing other lists
      }
    }
  }

  /// Sync all items in a list to Firebase
  Future<void> _syncListItemsToFirebase(ShoppingList localList) async {
    debugPrint(
      '📝 Syncing ${localList.items.length} items for list ${localList.id}',
    );

    try {
      // Sync all active items (non-deleted)
      for (final item in localList.activeItems) {
        await FirestoreService.addItemToList(localList.id, item);
      }

      // Sync deleted items to Firebase
      final deletedItems =
          localList.items.where((item) => item.deletedAt != null).toList();
      final successfullyDeletedItemIds = <String>[];

      for (final deletedItem in deletedItems) {
        debugPrint(
          '🗑️ Syncing deletion of item ${deletedItem.id} to Firebase',
        );
        final deleteSuccess = await FirestoreService.deleteItemFromList(
          localList.id,
          deletedItem.id,
        );
        if (deleteSuccess) {
          successfullyDeletedItemIds.add(deletedItem.id);
        }
      }

      // Permanently remove successfully deleted items from local storage
      if (successfullyDeletedItemIds.isNotEmpty) {
        debugPrint(
          '✅ Synced ${successfullyDeletedItemIds.length} item deletions to Firebase',
        );
        await _permanentlyRemoveDeletedItems(
          localList,
          successfullyDeletedItemIds,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to sync items for list ${localList.id}: $e');
      rethrow;
    }
  }

  /// Permanently remove successfully deleted items from local storage
  Future<void> _permanentlyRemoveDeletedItems(
    ShoppingList localList,
    List<String> itemIds,
  ) async {
    try {
      debugPrint(
        '🧹 Permanently removing ${itemIds.length} deleted items from local storage',
      );

      // Remove the successfully deleted items
      final updatedItems =
          localList.items.where((item) => !itemIds.contains(item.id)).toList();

      // Update the list in local storage
      final updatedList = localList.copyWith(items: updatedItems);
      await _localRepo.upsertList(updatedList);

      debugPrint(
        '✅ Permanently removed ${itemIds.length} items from local storage',
      );
    } catch (e) {
      debugPrint('❌ Failed to permanently remove deleted items: $e');
      // Don't rethrow - this is cleanup, sync should still succeed
    }
  }

  // ==========================================
  // STATE MANAGEMENT
  // ==========================================

  /// Current sync state as ValueNotifier for reactive UI updates
  ValueNotifier<SyncState> get syncStateNotifier => _syncStateNotifier;

  /// Current sync state value
  SyncState get syncState => _syncStateNotifier.value;

  /// Last error message if sync state is error
  String? get lastErrorMessage => _lastErrorMessage;

  /// Update sync state and notify listeners
  void _updateSyncState(SyncState newState, [String? errorMessage]) {
    _syncStateNotifier.value = newState;
    _lastErrorMessage = errorMessage;
    debugPrint('🔄 Sync state changed to: $newState');
    if (errorMessage != null) {
      debugPrint('❌ Sync error: $errorMessage');
    }
  }

  // ==========================================
  // APP LIFECYCLE MANAGEMENT
  // ==========================================

  /// Handle app lifecycle state changes for background/foreground sync
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _wasAppPaused = true;
        debugPrint('📱 App went to background');
        break;

      case AppLifecycleState.resumed:
        if (_wasAppPaused) {
          debugPrint('📱 App resumed from background - triggering sync...');
          _wasAppPaused = false;
          _triggerResumeSync();
        }
        break;

      case AppLifecycleState.inactive:
        // App is transitioning between states, no action needed
        break;
    }
  }

  /// Trigger sync when app resumes from background
  /// Only syncs if user is authenticated and sufficient time has passed
  Future<void> _triggerResumeSync() async {
    try {
      if (FirebaseAuthService.currentUser == null ||
          FirebaseAuthService.isAnonymous) {
        debugPrint('🔄 Skipping resume sync - user not authenticated');
        return;
      }

      // If sync is already running, don't start another one
      if (_syncStateNotifier.value == SyncState.syncing) {
        debugPrint('🔄 Sync already in progress - skipping resume sync');
        return;
      }

      debugPrint('🔄 Starting resume sync...');
      await startSync();
    } catch (e) {
      debugPrint('❌ Resume sync failed: $e');
      _updateSyncState(SyncState.error, 'Resume sync failed: $e');
    }
  }

  // ==========================================
  // CORE SYNC LOGIC
  // ==========================================

  /// Determines what sync action to take based on local and remote timestamps
  /// and deletion status
  SyncAction determineSyncAction({
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
    required DateTime? localDeletedAt,
    required DateTime? remoteDeletedAt,
  }) {
    // If both are deleted, no action needed
    if (localDeletedAt != null && remoteDeletedAt != null) {
      return SyncAction.noAction;
    }

    // If only local is deleted, propagate deletion to remote
    if (localDeletedAt != null && remoteDeletedAt == null) {
      return SyncAction.useLocal;
    }

    // If only remote is deleted, propagate deletion to local
    if (localDeletedAt == null && remoteDeletedAt != null) {
      return SyncAction.useRemote;
    }

    // Both are active - compare timestamps
    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      return SyncAction.noAction;
    }

    if (localUpdatedAt == null) {
      return SyncAction.useRemote;
    }

    if (remoteUpdatedAt == null) {
      return SyncAction.useLocal;
    }

    // Both have timestamps - compare them
    final timeDifference = localUpdatedAt.difference(remoteUpdatedAt);
    const toleranceMs = 1000; // 1 second tolerance for timestamp precision

    if (timeDifference.abs().inMilliseconds <= toleranceMs) {
      // Timestamps are very close - no action needed
      return SyncAction.noAction;
    }

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return SyncAction.useLocal;
    } else {
      return SyncAction.useRemote;
    }
  }

  /// Merges two shopping lists using granular merge strategy
  /// List properties use timestamp comparison, items are merged individually
  ShoppingList mergeLists({
    required ShoppingList localList,
    required ShoppingList remoteList,
  }) {
    // Determine which list properties to use based on updatedAt
    final useLocalProperties = localList.updatedAt.isAfter(
      remoteList.updatedAt,
    );

    // Use the newer list properties
    final baseList = useLocalProperties ? localList : remoteList;

    // Merge items using granular strategy
    final mergedItems = _mergeItems(
      localItems: localList.items,
      remoteItems: remoteList.items,
    );

    // Create merged list with newer properties and merged items
    return baseList.copyWith(
      items: mergedItems,
      // Always use the latest updatedAt from either list
      updatedAt:
          localList.updatedAt.isAfter(remoteList.updatedAt)
              ? localList.updatedAt
              : remoteList.updatedAt,
    );
  }

  /// Merges two item lists using item-level timestamp comparison
  List<ShoppingItem> _mergeItems({
    required List<ShoppingItem> localItems,
    required List<ShoppingItem> remoteItems,
  }) {
    final Map<String, ShoppingItem> mergedItemsMap = {};

    // Add all local items first
    for (final item in localItems) {
      if (item.deletedAt == null) {
        mergedItemsMap[item.id] = item;
      }
    }

    // Process remote items
    for (final remoteItem in remoteItems) {
      final localItem = mergedItemsMap[remoteItem.id];

      // If item doesn't exist locally, add it (unless deleted)
      if (localItem == null) {
        if (remoteItem.deletedAt == null) {
          mergedItemsMap[remoteItem.id] = remoteItem;
        }
        continue;
      }

      // Both items exist - determine which to keep
      final syncAction = determineSyncAction(
        localUpdatedAt:
            localItem.createdAt, // Items use createdAt for versioning
        remoteUpdatedAt: remoteItem.createdAt,
        localDeletedAt: localItem.deletedAt,
        remoteDeletedAt: remoteItem.deletedAt,
      );

      switch (syncAction) {
        case SyncAction.useRemote:
          if (remoteItem.deletedAt == null) {
            mergedItemsMap[remoteItem.id] = remoteItem;
          } else {
            mergedItemsMap.remove(remoteItem.id);
          }
          break;
        case SyncAction.useLocal:
          // Local is already in the map, no change needed
          break;
        case SyncAction.noAction:
        case SyncAction.mergeRequired:
          // Keep local version for simplicity in this implementation
          break;
      }
    }

    return mergedItemsMap.values.toList();
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Reset sync service to initial state (useful for testing)
  @visibleForTesting
  void reset() {
    _updateSyncState(SyncState.idle);
    _lastErrorMessage = null;
  }

  // ==========================================
  // TEST HELPER METHODS
  // ==========================================

  /// Test helper to expose _shouldUpdateLocal for unit testing
  @visibleForTesting
  bool testShouldUpdateLocal(ShoppingList localList, ShoppingList mergedList) {
    return _shouldUpdateLocal(localList, mergedList);
  }

  /// Test helper to expose _areItemsEqual for unit testing
  @visibleForTesting
  bool testAreItemsEqual(ShoppingItem item1, ShoppingItem item2) {
    return _areItemsEqual(item1, item2);
  }

  /// Test helper to expose _areItemListsEqual for unit testing
  @visibleForTesting
  bool testAreItemListsEqual(
    List<ShoppingItem> list1,
    List<ShoppingItem> list2,
  ) {
    return _areItemListsEqual(list1, list2);
  }
}
