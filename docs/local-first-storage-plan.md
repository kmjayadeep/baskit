# Local-First Storage Architecture Implementation Plan

## Overview

Convert Baskit from dual-layer architecture to local-first storage with background synchronization.

### Current Issues
- StorageService switches between local and Firebase based on auth state
- UI operations sometimes wait for network calls
- Complex routing logic in StorageService facade

### Target Architecture
- All UI operations hit local storage immediately
- Firebase operations happen asynchronously in background
- Single data flow pattern

## Architecture Overview

### New Data Flow

```
UI Components
    ↓ (immediate)
StorageService (local-first)
    ↓ (immediate)
LocalStorageService
    ↓ (immediate)
Hive Database
    ↑ (immediate)
Stream Controllers → UI Updates
    ↓ (background)
SyncService (watches streams)
    ↓ (background)
FirestoreService
    ↓ (background)
Firebase/Firestore
```

### Service Responsibilities

#### StorageService
- Single entry point for all UI operations
- Always writes to local storage first
- Unified API for UI components

#### LocalStorageService
- Manage local Hive database and reactive streams
- Local CRUD operations and stream management

#### SyncService (New)
- Bidirectional sync between local and Firebase
- Watches local streams and syncs changes to Firebase
- Conflict resolution using timestamps

#### FirestoreService
- Pure Firebase operations without local concerns
- Direct Firebase CRUD and real-time listeners

## Implementation Plan

### Phase 1: Clean Up StorageService (Local-First Only)

#### Tasks
- Remove `_useLocal` getter and all auth-based routing logic
- Remove `_ensureMigrationComplete()` and migration code
- Remove SharedPreferences dependencies
- Simplify all methods to always use LocalStorageService
- Keep sharing method as Firebase-only operation

#### Implementation
```dart
class StorageService {
  final LocalStorageService _local = LocalStorageService.instance;
  
  Future<bool> createList(ShoppingList list) async {
    return await _local.upsertList(list);
  }
  
  Future<bool> updateList(ShoppingList list) async {
    return await _local.upsertList(list);
  }
  
  Stream<List<ShoppingList>> watchLists() {
    return _local.watchLists();
  }
  
  // Keep sharing as Firebase operation
  Future<ShareResult> shareList(String listId, String email) async {
    if (!FirebaseAuthService.isAuthenticated) {
      return ShareResult.error('Sign in required for sharing');
    }
    return await FirestoreService.shareListWithUser(listId, email);
  }
}
```

#### Tests
- Test all CRUD operations work with local storage only
- Test streams update correctly
- Test sharing requires authentication
- Integration tests with UI components

### Phase 2: Add FirestoreLayer Abstraction

#### Tasks
- Create `FirestoreLayer` class to abstract Firebase operations
- Move Firebase methods from FirestoreService to FirestoreLayer
- Add proper error handling and offline support
- Add stream management for Firebase data

#### Implementation
```dart
class FirestoreLayer {
  static FirestoreLayer? _instance;
  static FirestoreLayer get instance => _instance ??= FirestoreLayer._();
  
  Future<bool> createList(ShoppingList list) async { /* */ }
  Future<bool> updateList(ShoppingList list) async { /* */ }
  Future<bool> deleteList(String id) async { /* */ }
  Stream<List<ShoppingList>> watchLists() { /* */ }
  Stream<ShoppingList?> watchList(String id) { /* */ }
}
```

#### Tests
- Test Firebase operations work independently
- Test error handling for network failures
- Test stream subscriptions and cleanup
- Mock Firebase for unit tests

### Phase 3: Create SyncService Foundation

#### Tasks
- Create SyncService with singleton pattern
- Add sync state management
- Implement timestamp comparison logic
- Add basic sync loop prevention

#### Implementation
```dart
enum SyncAction { uploadToFirebase, downloadFromFirebase, noAction }

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  
  final LocalStorageService _local = LocalStorageService.instance;
  final FirestoreLayer _firebase = FirestoreLayer.instance;
  final Set<String> _syncingLists = {};
  
  SyncAction determineSyncAction(DateTime local, DateTime firebase) {
    if (local.isAfter(firebase)) return SyncAction.uploadToFirebase;
    if (firebase.isAfter(local)) return SyncAction.downloadFromFirebase;
    return SyncAction.noAction;
  }
}
```

#### Tests
- Test sync action determination logic
- Test sync state management
- Test singleton behavior
- Unit tests for all helper methods

### Phase 4: Implement Local-to-Firebase Sync

#### Tasks
- Subscribe to local storage streams
- Implement upload logic for lists and items
- Add proper error handling and retry logic
- Prevent sync loops

#### Implementation
```dart
void startLocalToFirebaseSync() {
  _localListsSubscription = _local.watchLists().listen((localLists) {
    for (final list in localLists) {
      _syncListToFirebase(list);
    }
  });
}

Future<void> _syncListToFirebase(ShoppingList localList) async {
  if (_syncingLists.contains(localList.id) || !_isAuthenticated) return;
  
  _syncingLists.add(localList.id);
  try {
    // Compare and sync logic
  } finally {
    _syncingLists.remove(localList.id);
  }
}
```

#### Tests
- Test sync triggers on local changes
- Test conflict resolution with timestamps
- Test error handling and retry logic
- Test sync loop prevention

### Phase 5: Implement Firebase-to-Local Sync

#### Tasks
- Subscribe to Firebase streams when authenticated
- Implement download logic for lists and items
- Add proper timestamp-based conflict resolution
- Handle real-time updates from shared lists

#### Implementation
```dart
void startFirebaseToLocalSync() {
  _firebaseListsSubscription = _firebase.watchLists().listen((firebaseLists) {
    for (final list in firebaseLists) {
      _syncListToLocal(list);
    }
  });
}
```

#### Tests
- Test sync triggers on Firebase changes
- Test real-time updates work correctly
- Test conflict resolution prioritizes newer data
- Test shared list updates sync to local

### Phase 6: Authentication Event Integration

#### Tasks
- Listen to auth state changes
- Handle sign-in: start sync, migrate local data
- Handle sign-out: stop sync, clear local data
- Handle account switching

#### Implementation
```dart
void handleAuthStateChange(User? user) {
  if (user == null) {
    _handleSignOut();
  } else {
    _handleSignIn(user);
  }
}
```

#### Tests
- Test auth state change handling
- Test data migration on sign-in
- Test data clearing on sign-out
- Test account switching scenarios

### Phase 7: Edge Cases and Optimization

#### Tasks
- Handle first-time login scenarios
- Handle app resume after long offline period
- Add performance optimizations
- Add comprehensive error handling

#### Implementation
```dart
Future<void> handleAppResume() async {
  if (_isAuthenticated) {
    await _performFullSync();
  }
}
```

#### Tests
- Test first-time login with existing cloud data
- Test app resume triggers full sync
- Test performance with large datasets
- Integration tests for complete user flows

## Implementation Timeline

### Week 1: StorageService Cleanup
- [ ] Phase 1: Remove auth routing, migration code, SharedPreferences
- [ ] Add comprehensive tests for local-first operations
- [ ] Validate UI integration works correctly

### Week 2: Firebase Abstraction  
- [ ] Phase 2: Create FirestoreLayer abstraction
- [ ] Move Firebase methods from FirestoreService
- [ ] Add Firebase operation tests with mocking

### Week 3: Sync Foundation
- [ ] Phase 3: Create SyncService with timestamp logic
- [ ] Implement sync state management and loop prevention
- [ ] Unit tests for sync decision logic

### Week 4: Local-to-Firebase Sync
- [ ] Phase 4: Implement upload sync with stream subscriptions
- [ ] Add conflict resolution and error handling
- [ ] Test sync triggers and performance

### Week 5: Firebase-to-Local Sync
- [ ] Phase 5: Implement download sync and real-time updates
- [ ] Test shared list collaboration scenarios
- [ ] Validate bidirectional sync works correctly

### Week 6: Authentication Integration
- [ ] Phase 6: Auth state change handling
- [ ] Data migration and clearing logic
- [ ] Test sign-in/sign-out/account switching

### Week 7: Edge Cases and Polish
- [ ] Phase 7: First-time login, app resume, optimizations
- [ ] Performance testing with large datasets
- [ ] Integration tests for complete user flows 