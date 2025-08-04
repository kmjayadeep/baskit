import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

/// Sync state enumeration for tracking synchronization status
enum SyncState { idle, syncing, synced, error }

/// Action to take during synchronization based on timestamp comparison
enum SyncAction { noAction, useLocal, useRemote, mergeRequired }

/// Core synchronization service implementing local-first architecture
/// Manages bidirectional sync between local Hive storage and Firebase
class SyncService {
  static SyncService? _instance;

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

  /// Dispose resources and stop sync operations
  void dispose() {
    _syncStateNotifier.dispose();
  }

  /// Reset sync service to initial state (useful for testing)
  @visibleForTesting
  void reset() {
    _updateSyncState(SyncState.idle);
    _lastErrorMessage = null;
  }
}
