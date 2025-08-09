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
class SyncService {
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

    // Listen to authentication state changes
    _authStateSubscription = FirebaseAuthService.authStateChanges.listen(
      (user) async {
        final isAuthenticated =
            user != null && !FirebaseAuthService.isAnonymous;
        debugPrint('🔄 Auth state changed - isAuthenticated: $isAuthenticated');

        if (isAuthenticated) {
          // User signed in (non-anonymous) - start sync
          await startSync();
        } else {
          // User signed out or is anonymous - stop sync
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
    stopSync();
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _syncStateNotifier.dispose();
    debugPrint('✅ SyncService disposed');
  }

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
      debugPrint('✅ Sync started successfully');
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

    // Subscribe to local lists changes
    _localListsSubscription = _localRepo.watchLists().listen(
      (localLists) async {
        debugPrint(
          '🔄 Local lists changed, syncing ${localLists.length} lists to Firebase',
        );
        await _syncLocalListsToFirebase(localLists, userId);
      },
      onError: (error) {
        debugPrint('❌ Error in local lists stream: $error');
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

      // Remove from local storage using existing deleteList method
      // Note: This will be a hard delete since the list is already soft-deleted
      await _localRepo.deleteList(localList.id);

      debugPrint('✅ Successfully deleted list ${localList.id}');
    } catch (e) {
      debugPrint('❌ Failed to delete list ${localList.id}: $e');
      rethrow;
    }
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
      } else {
        debugPrint(
          '⚠️ Failed to sync list ${localList.id} - Firebase unavailable',
        );
      }
    } catch (e) {
      // If creation fails, the document might already exist - try updating instead
      debugPrint('⚠️ Create failed for ${localList.id}, attempting update: $e');

      try {
        final updateSuccess = await FirestoreService.updateList(
          localList.id,
          name: localList.name,
          description: localList.description,
          color: localList.color,
        );

        if (updateSuccess) {
          debugPrint('✅ Successfully updated list ${localList.id} in Firebase');
        } else {
          debugPrint('❌ Failed to update list ${localList.id} in Firebase');
        }
      } catch (updateError) {
        debugPrint('❌ Failed to sync list ${localList.id}: $updateError');
        // Don't rethrow - we want to continue syncing other lists
      }
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
}
