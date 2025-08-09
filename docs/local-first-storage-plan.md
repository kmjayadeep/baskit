# Local-First Storage Architecture Implementation Plan (v2)

## Overview

Convert Baskit from a dual-layer architecture to a true local-first model with robust background synchronization. This plan addresses critical requirements such as conflict resolution, deletion propagation, and seamless data merging on authentication.

### Current Issues
- `StorageService` switches between local and Firebase based on auth state.
- UI operations can be blocked by network calls.
- Complex and brittle routing logic in the `StorageService` facade.

### Target Architecture
- All UI operations interact *only* with the local Hive database for immediate feedback.
- A dedicated `SyncService` handles all network operations asynchronously in the background.
- A single, unified data flow for all application states.

---

## Core Concepts

### Data Models
To support robust synchronization, the data models must be updated:
- **`ShoppingList`**: Add `deletedAt: DateTime?`.
- **`ShoppingItem`**: Add `deletedAt: DateTime?`.

### Service Responsibilities

#### StorageService
- **Remains the single entry point for all UI-initiated data operations.**
- Simplifies to *only* communicate with `LocalStorageService`. No more auth-based logic.

#### LocalStorageService
- Manages the local Hive database, including all CRUD operations and reactive streams.
- Implements soft deletes by marking records with `deletedAt`.

#### SyncService (New & Expanded)
- **Stateful Service**: Manages and exposes the current sync status (e.g., `idle`, `syncing`, `synced`, `error`) to the UI.
- **Bidirectional Sync**: Watches local data for changes to upload and listens to Firebase for changes to download.
- **Conflict Resolution**: Implements a granular, item-level merge strategy to prevent data loss.
- **Deletion Propagation**: Handles syncing soft deletes to Firestore and cleaning up local tombstoned records.
- **Initial Sync**: Manages the critical data merge process when a user first logs in.

#### FirestoreService
- Becomes a pure data layer for Firebase, containing no business logic. Handles direct Firebase CRUD and stream setup.

---

## Detailed Sync Logic

### 1. Conflict Resolution: Granular Merge Strategy
A simple "last write wins" on an entire list is insufficient. The `SyncService` will use a more granular approach:
- **List Properties (name, color, etc.):** The version with the more recent `updatedAt` timestamp wins.
- **Item List:** The service will merge the local and remote item lists:
    - For each item, compare the `updatedAt` timestamp. The newest version of the item is kept.
    - If an item exists on one side but not the other (and is not a tombstone), it is added.
    - This prevents a minor item edit from overwriting a list name change, and vice-versa.

### 2. Deletion Propagation: Tombstoning
To sync deletions, a soft-delete mechanism is required:
1.  **Local Deletion**: When a user deletes a list or item, the record in Hive is not removed. Instead, its `deletedAt` field is set to the current timestamp.
2.  **Sync to Cloud**: The `SyncService` detects the `deletedAt` timestamp and sends a delete command to Firestore for that record.
3.  **Cloud Deletion**: The record is permanently deleted from Firestore.
4.  **Local Cleanup**: After confirming the cloud deletion, the `SyncService` permanently removes the tombstoned record from the local Hive database.

### 3. Initial Sync on Login
To prevent data loss when a user with cloud data logs in on a new device (or after an anonymous session), the `SyncService` will:
1.  **Halt local sync.**
2.  **Fetch all lists** from Firestore.
3.  **Fetch all lists** from the local Hive database (from the anonymous session).
4.  **Merge the two datasets**:
    - For each list, apply the **Granular Merge Strategy** described above.
    - This intelligently combines anonymous and cloud data.
5.  **Save the merged dataset** as the new authoritative state in the local Hive database.
6.  **Resume bidirectional sync.**

---

## Implementation Plan

### Phase 1: Data Model and StorageService Cleanup ✅
- **Tasks**:
    - ✅ Add `deletedAt: DateTime?` to `ShoppingList` and `ShoppingItem` Hive models. Run build runner.
    - ✅ Refactor `StorageService` to remove all auth-based routing and Firebase logic. All methods now call `LocalStorageService`.  
    - ✅ Refactor `LocalStorageService` to implement soft deletes for lists and items (using `deletedAt`) instead of hard deletes.
    - ✅ Clean up unused migration code and resolve all analyzer warnings.

### Phase 2: Create FirestoreLayer Abstraction ✅
- **Tasks**:
    - ✅ Create a `FirestoreLayer` class that abstracts all direct Firebase operations.
    - ✅ This layer should handle `DocumentSnapshot` conversion and basic error handling.

### Phase 3: SyncService Foundation ✅
- **Tasks**:
    - ✅ Create the `SyncService` singleton.
    - ✅ Implement sync state management: `enum SyncState { idle, syncing, synced, error }` and expose it as a `ValueNotifier` or `Stream`.
    - ✅ Implement the core `determineSyncAction` logic based on timestamps and the `deletedAt` field.
    - ✅ Implement the granular `mergeLists` function for conflict resolution.

### Phase 4: Implement Bidirectional Sync
- **Tasks**:
    - **Local-to-Firebase**: Subscribe to local streams. When a change is detected, push it to `FirestoreLayer`. Handle `deletedAt` timestamps by calling the appropriate delete method.
    - **Firebase-to-Local**: Subscribe to Firebase streams (when authenticated). When a change is detected, merge it with local data using the `mergeLists` function.
    - **Sharing Feedback Loop**: Ensure that when a list is shared, the new member's `SyncService` automatically downloads and saves it to their local Hive.

### Phase 5: Authentication Event Integration
- **Tasks**:
    - Listen to `FirebaseAuthService.authStateChanges`.
    - **On Sign-In**: Trigger the **Initial Sync on Login** process described above.
    - **On Sign-Out**: Stop all sync operations and clear all local data to ensure privacy and a clean state for the next user.

### Phase 6: UI and Edge Cases
- **Tasks**:
    - **UI Feedback**: Create a widget (e.g., `SyncStatusIndicator`) that listens to the `SyncService.syncState` stream and displays the current status (e.g., "Synced", "Syncing...", "Offline").
    - **App Resume**: Implement logic to trigger a full sync when the app resumes after a long offline period.
    - **Error Handling**: Add comprehensive error handling and retry logic (e.g., exponential backoff) to the `SyncService`.

### Phase 7: Testing and Validation
- **Tasks**:
    - Write unit tests for the `mergeLists` and `determineSyncAction` logic.
    - Write integration tests for the full sync cycle: local change -> cloud -> other device.
    - Test all authentication scenarios: anonymous to signed-in, fresh install login, sign-out, etc.
    - Test collaboration scenarios with multiple users modifying the same list.
    - Test offline scenarios extensively.

---

## Implementation Timeline (Revised)

### Week 1: Foundations
- [x] Phase 1: Update data models and clean up `StorageService` & `LocalStorageService`.
- [x] Phase 2: Create `FirestoreLayer` abstraction.

**Progress**: Phase 1, 2 & 3 complete. StorageService is purely local-first with soft deletes. FirestoreLayer abstraction handles all DocumentSnapshot conversion and Firebase query operations. SyncService foundation with state management and core sync logic implemented with comprehensive tests. Ready for Phase 4.

### Week 2-3: Sync Logic
- [x] Phase 3: Build `SyncService` foundation with state management and merge/conflict logic.
- [x] Write unit tests for the core sync logic.

### Week 4-5: Full Sync Implementation
- [x] Phase 4a: Implement local-to-firebase sync with authentication integration ✅
- [ ] Phase 4b: Implement firebase-to-local sync (pending)
- [x] Test basic sync functionality ✅

### Week 6: Auth and UI Integration
- [x] Phase 5: Implement the authentication event handling (initial sync, sign-out) ✅
- [ ] Phase 6: Create the `SyncStatusIndicator` UI widget and app resume logic.

### Week 7: Testing and Polish
- [ ] Phase 7: Conduct thorough integration testing for all user flows, collaboration, and offline scenarios.
- [ ] Performance testing with large datasets.

---

## Current Status & Technical Debt

### ✅ **Completed (Phase 4a & 5)**
- **Local-to-Firebase sync**: Functional with authentication integration
- **Authentication event handling**: Auto-start/stop sync on sign-in/sign-out  
- **SyncService initialization**: Properly integrated in main.dart
- **Error handling**: Graceful continuation when individual lists fail to sync
- **Unit tests**: All 27 sync service tests passing

### ⚠️ **Technical Debt & Known Issues**

#### 1. ~~**ID Mismatch Problem**~~ ✅ **FIXED**
- **Issue**: Local lists use UUID v4, Firebase generates auto-IDs
- **Solution**: Modified `FirestoreService.createList()` to use predetermined IDs from local lists
- **Implementation**: Changed from `_listsCollection.add({...})` to `_listsCollection.doc(list.id).set({...})`
- **Result**: Local and Firebase lists now maintain consistent UUIDs
- **Status**: ✅ **RESOLVED** - Both list and item IDs are now consistent across local and Firebase storage

#### 2. **One-Way Sync Only** (High Priority)  
- **Issue**: Only local-to-Firebase sync implemented
- **Missing**: Firebase-to-local sync for collaborative features
- **Impact**: Changes made by other users or on other devices won't appear locally
- **TODO**: Implement Phase 4b - Firebase-to-local sync

#### 3. ~~**Deletion Sync Issue**~~ ✅ **FIXED**
- **Issue**: Deleted lists were not being synced to Firebase due to stream filtering
- **Root Cause**: `watchLists()` filtered out soft-deleted lists, so SyncService never saw them
- **Solution**: Added `watchAllListsIncludingDeleted()` method for sync service
- **Implementation**: SyncService now uses separate stream that includes deleted lists
- **Status**: ✅ **RESOLVED** - Deletions now properly sync from local to Firebase

#### 4. **Duplicate Creation Risk** (Medium Priority)
- **Issue**: No duplicate detection when sync runs multiple times
- **Impact**: May create multiple copies of same list in Firebase
- **Workaround**: `createList()` fails gracefully if list exists, but doesn't handle updates
- **TODO**: Add existence checking and update logic

#### 5. **No Initial Sync on Login** (Medium Priority)
- **Issue**: When user signs in, no merge of existing Firebase data with local anonymous data
- **Impact**: User may lose data or see incomplete state after authentication
- **TODO**: Implement initial sync merge strategy from plan

#### 6. **Missing UI Feedback** (Low Priority)
- **Issue**: No user-visible sync status indicators
- **Impact**: Users don't know if sync is working or failed
- **TODO**: Implement `SyncStatusIndicator` widget (Phase 6)

### 📋 **Next Priority Actions**

1. ~~**Fix ID Mismatch**~~ ✅ **COMPLETED** 
2. **Add Firebase-to-Local Sync** - Complete bidirectional sync  
3. **Add Initial Sync on Login** - Merge anonymous + authenticated data
4. **Add Duplicate Prevention** - Check existence before creating (partially addressed with create/update fallback)
5. **Add UI Sync Indicators** - Show sync status to users

### 🏗️ **Architecture Notes**

The current implementation successfully establishes the **local-first foundation** with basic sync capability. The technical debt is manageable and doesn't break the core local-first principle - all UI operations remain instant and local. The debt primarily affects **collaboration and multi-device scenarios**.