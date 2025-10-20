# Database Architecture & Security

## Overview
Baskit implements a **dual-layer storage architecture** that combines local-first performance with cloud synchronization:

- **Local Storage (Hive)**: Fast binary storage for anonymous users and local caching
- **Cloud Storage (Firestore)**: Real-time collaborative database for authenticated users

### Current Implementation: Guest-First Architecture

The `StorageService` acts as a smart routing layer that switches between local and cloud storage based on authentication state. This **guest-first** approach allows users to start using the app immediately without any sign-up friction:

- **Anonymous users (Guest Mode)**: All operations route to `LocalStorageService` (Hive) only
  - Instant app usage without authentication
  - Fast local binary storage
  - Full offline functionality
  - No network dependency
  
- **Authenticated users**: All operations route to `FirestoreLayer` (Firebase) with offline persistence
  - Real-time collaboration
  - Cross-device synchronization
  - Cloud backup
  - Sharing capabilities
  
- **Account conversion**: Automatic one-time migration of local data to Firebase when user signs in
  - Seamless upgrade from guest to full account
  - No data loss during conversion
  - Transparent to the user

This architecture provides the best of both worlds: zero-friction onboarding for guests and powerful cloud features for authenticated users.

### Why Guest-First Architecture?

**Design Philosophy:**
1. **Zero Friction Onboarding**: Users can start using the app immediately without creating an account
2. **Privacy by Default**: Anonymous users' data stays local on their device
3. **Progressive Enhancement**: Users unlock cloud features only when they need them (sharing, sync)
4. **No Data Loss**: Seamless transition from guest to authenticated user preserves all data

**Key Benefits:**
- ✅ **Instant Gratification**: No sign-up friction, users can evaluate the app immediately
- ✅ **Performance**: Local operations are instant (no network latency)
- ✅ **Privacy-First**: Guest data never leaves the device
- ✅ **Flexible Upgrade Path**: Users choose when/if to authenticate
- ✅ **Offline-First for Guests**: Full functionality without internet
- ✅ **Cloud-First for Authenticated**: Real-time sync and collaboration

**Technical Advantages:**
- Simple routing logic based on `FirebaseAuthService.isAnonymous`
- Clear separation of concerns (local vs cloud operations)
- Easy to test (local and cloud layers independent)
- Automatic migration handles data transfer transparently
- Firebase offline persistence provides caching for authenticated users

### Guest-First User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. App Launch (Guest Mode)                                     │
├─────────────────────────────────────────────────────────────────┤
│ • Anonymous Firebase auth (automatic)                           │
│ • All data → Hive (local binary storage)                       │
│ • Full app functionality                                        │
│ • No network required                                           │
│ • Instant operations                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User wants to share a list
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Sign In with Google (Optional)                              │
├─────────────────────────────────────────────────────────────────┤
│ • User clicks "Sign in with Google"                            │
│ • Google OAuth flow                                             │
│ • Account linking preserves anonymous data                      │
│ • Automatic migration triggered                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Migration happens transparently
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Automatic Data Migration                                    │
├─────────────────────────────────────────────────────────────────┤
│ • All local lists copied to Firebase                           │
│ • SharedPreferences tracks migration completion                │
│ • Local data cleared after successful migration                │
│ • One-time process per user                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Storage layer switches
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Authenticated Mode                                          │
├─────────────────────────────────────────────────────────────────┤
│ • All data → Firebase (with offline persistence)              │
│ • Real-time collaboration enabled                              │
│ • Cross-device sync active                                     │
│ • Sharing features available                                   │
│ • Offline mode still works (Firebase cache)                   │
└─────────────────────────────────────────────────────────────────┘
```

## Local Storage Architecture

### Hive Database Design
The local storage layer uses **Hive** (binary storage) for optimal performance:

```
📁 Local Hive Database
└── 📦 shopping_lists (Box<ShoppingList>)
    ├── {listId}: ShoppingList
    │   ├── id: string
    │   ├── name: string
    │   ├── description: string
    │   ├── color: string (hex format)
    │   ├── createdAt: DateTime
    │   ├── updatedAt: DateTime
    │   └── items: List<ShoppingItem>
    │       └── ShoppingItem
    │           ├── id: string
    │           ├── name: string
    │           ├── quantity: string?
    │           ├── isCompleted: boolean
    │           ├── createdAt: DateTime
    │           └── completedAt: DateTime?
```

### Local Storage Service Features

#### Singleton Architecture
```dart
class LocalStorageService {
  static LocalStorageService get instance // Singleton pattern
  Future<void> init()                     // Initialize Hive and adapters
  void dispose()                          // Clean up resources
}
```

#### Reactive Streams
- **Lists Stream**: `Stream<List<ShoppingList>> watchLists()`
- **Individual List Stream**: `Stream<ShoppingList?> watchList(String id)`
- **Broadcast Controllers**: Multiple widgets can listen to the same data
- **Auto-refresh**: Streams automatically emit updates on data changes

#### CRUD Operations
```dart
// Lists
Future<bool> upsertList(ShoppingList list)
Future<bool> deleteList(String id)
Future<List<ShoppingList>> getAllLists()
Future<ShoppingList?> getListById(String id)

// Items  
Future<bool> addItem(String listId, ShoppingItem item)
Future<bool> updateItem(String listId, String itemId, {...})
Future<bool> deleteItem(String listId, String itemId)
Future<bool> clearCompleted(String listId)
```

#### Smart Item Sorting
The service automatically sorts items for optimal UX:

1. **Incomplete Items** (top section):
   - Sorted by creation date (newest first)
   - Always visible and easily accessible

2. **Completed Items** (bottom section):
   - Sorted by completion date (most recently completed first)
   - Fallback to creation date if completion date unavailable
   - Visually separated from active items

#### Performance Optimizations
- **Binary Storage**: Hive provides faster read/write compared to JSON
- **Lazy Loading**: Only loads data when accessed
- **Memory Efficient**: Minimal memory footprint
- **Background Operations**: Non-blocking UI operations

### Local Storage Use Cases

#### Anonymous Users
- **Primary Storage**: All data stored locally in Hive
- **Instant Performance**: No network delays
- **Offline-First**: Full functionality without internet
- **No Account Required**: Complete app experience

#### Authenticated Users  
- **Local Cache**: Hive acts as local cache for Firestore data
- **Instant UI**: Read from local cache first
- **Background Sync**: Firestore sync happens in background
- **Conflict Resolution**: Local changes merge with server data

## Cloud Storage Architecture

### Firestore Database Design

### Global Collection Structure
The database uses a **global lists collection** approach that enables true list sharing:

```
📁 Firestore Database
├── 📁 users/{userId}
│   ├── profile: object
│   │   ├── email: string | null
│   │   ├── displayName: string | null
│   │   ├── photoURL: string | null
│   │   ├── createdAt: timestamp
│   │   └── isAnonymous: boolean
│   ├── listIds: array<string> (deprecated - kept for migration)
│   └── sharedIds: array<string> (deprecated - kept for migration)
│
└── 📁 lists/{listId} (GLOBAL COLLECTION - Enables Sharing)
    ├── name: string
    ├── description: string
    ├── color: string (hex format)
    ├── ownerId: string (Firebase UID)
    ├── createdAt: timestamp
    ├── updatedAt: timestamp
    ├── memberIds: array<string> (for efficient querying)
    ├── members: object (detailed member info)
    │   └── {userId}: object
    │       ├── userId: string
    │       ├── role: "owner" | "member"
    │       ├── displayName: string
    │       ├── email: string
    │       ├── joinedAt: timestamp
    │       └── permissions: object
    │           ├── read: boolean
    │           ├── write: boolean
    │           ├── delete: boolean
    │           └── share: boolean
    │
    └── 📁 items/{itemId} (subcollection)
        ├── name: string
        ├── quantity: string | null
        ├── completed: boolean
        ├── createdAt: timestamp
        ├── updatedAt: timestamp
        └── createdBy: string (Firebase UID)
```

## Architecture Design Decisions

### 1. Global Lists Collection
- **Purpose**: Enables true list sharing across users
- **Benefit**: Single source of truth for shared lists
- **Implementation**: Lists stored in `/lists/{listId}` instead of user subcollections

### 2. Dual Membership Tracking
```javascript
{
  "memberIds": ["uid1", "uid2", "uid3"],  // For efficient array-contains queries
  "members": {                           // For detailed member information
    "uid1": { role: "owner", permissions: {...} },
    "uid2": { role: "member", permissions: {...} }
  }
}
```

### 3. Granular Permissions System
Each member has specific permissions:
- **read**: Can view list and items
- **write**: Can add/edit items and list metadata
- **delete**: Can remove items
- **share**: Can invite new members

### 4. Anonymous User Support
- Anonymous users get full functionality
- Seamless upgrade to authenticated accounts
- Data migration handled during account linking

## Security Rules Implementation

### Core Security Functions

#### Authentication Check
```javascript
function isAuthenticated() {
  return request.auth != null;  // Supports both anonymous and signed-in users
}
```

#### Membership Validation
```javascript
function isListMember(listData) {
  return isAuthenticated() && 
         listData.memberIds is list &&
         request.auth.uid in listData.memberIds;
}
```

#### Permission-Based Access
```javascript
function hasListPermission(listData, permission) {
  return isAuthenticated() &&
         listData.members is map &&
         request.auth.uid in listData.members &&
         listData.members[request.auth.uid].permissions[permission] == true;
}
```

### Access Control Matrix

| Operation | Owner | Member (Read) | Member (Write) | Member (Delete) | Member (Share) | Non-Member |
|-----------|-------|---------------|----------------|-----------------|----------------|------------|
| Read List | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Update List Metadata | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Delete List | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Add Members | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Read Items | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Create Items | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Update Items | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Delete Items | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |

## Security Protections

### 1. Ownership Protection
- Only list owners can delete lists
- Owners cannot be removed from memberIds
- Owner role cannot be transferred via security rules

### 2. Data Integrity
- Required fields validation
- Field type validation
- String length limits (names: 1-100 chars, descriptions: max 500 chars)
- Format validation (hex colors: #RRGGBB pattern)

### 3. Query Security
- Users can only query lists they're members of
- Query result limits (max 100 lists, 10 users)
- Restricted field access in queries

### 4. Membership Security
- Users can only be added by members with 'share' permission
- Member data structure validation
- Automatic permission inheritance

## Performance Optimizations

### Recommended Indexes
```javascript
// Compound index for efficient list queries
{
  collection: "lists",
  fields: [
    { fieldPath: "memberIds", order: "ASCENDING" },
    { fieldPath: "updatedAt", order: "DESCENDING" }
  ]
}

// Index for user lookup during sharing
{
  collection: "users",
  fields: [
    { fieldPath: "profile.email", order: "ASCENDING" }
  ]
}
```

### Query Patterns
```dart
// Get user's lists (both owned and shared)
FirebaseFirestore.instance
  .collection('lists')
  .where('memberIds', arrayContains: currentUserId)
  .orderBy('updatedAt', descending: true)
  .limit(100);

// Get specific list with permission check
FirebaseFirestore.instance
  .collection('lists')
  .doc(listId)
  .get()
  .then((doc) => {
    // Security rules automatically validate access
  });
```

## Offline-First Integration

### Offline Capabilities
- **Cached Permissions**: Local app caches permission checks
- **Conflict Resolution**: Server-side validation ensures data integrity
- **Sync Safety**: Rules prevent unauthorized modifications during sync
- **Anonymous Support**: Full functionality for offline anonymous users

### Real-time Collaboration
- **Live Updates**: Real-time listeners work within security boundaries
- **Permission Changes**: Immediate effect on user capabilities
- **Member Management**: Real-time member addition/removal

## Data Validation Rules

### List Validation
```javascript
// List creation/update validation
function isValidListData(data) {
  return data.keys().hasAll(['name', 'description', 'color', 'ownerId']) &&
         data.name is string && data.name.size() >= 1 && data.name.size() <= 100 &&
         data.description is string && data.description.size() <= 500 &&
         data.color is string && data.color.matches('^#[0-9A-Fa-f]{6}$') &&
         data.ownerId is string;
}
```

### Item Validation
```javascript
// Shopping item validation
function isValidItemData(data) {
  return data.keys().hasAll(['name', 'completed', 'createdBy']) &&
         data.name is string && data.name.size() >= 1 && data.name.size() <= 200 &&
         data.completed is bool &&
         data.createdBy is string &&
         (!data.keys().hasAny(['quantity']) || data.quantity is string);
}
```

## Dual-Layer Architecture Integration

### Storage Service Facade
The `StorageService` acts as a smart facade that automatically routes operations based on authentication state:

```dart
class StorageService {
  final LocalStorageService _local = LocalStorageService.instance;
  final FirestoreLayer _firebase = FirestoreLayer.instance;
  
  // Automatic routing based on authentication state
  bool get _useLocal => FirebaseAuthService.isAnonymous;
  
  // Unified API for UI components - routes to appropriate layer
  Future<bool> createList(ShoppingList list) async {
    if (_useLocal) {
      return await _local.upsertList(list);
    } else {
      await _ensureMigrationComplete(); // Migrate local data on first authenticated use
      final success = await _firebase.createList(list);
      if (success) await _updateLastSyncTime();
      return success;
    }
  }
  
  Stream<List<ShoppingList>> watchLists() {
    return _useLocal
      ? _local.watchLists()
      : _getAuthenticatedListsStream(); // Includes migration logic
  }
}
```

**Key Implementation Details:**
- Anonymous users: Direct routing to `LocalStorageService`
- Authenticated users: Routes to `FirestoreLayer` with automatic data migration
- Migration happens transparently on first authenticated operation
- Local data is cleared after successful migration to Firebase

### Data Flow Patterns

#### Anonymous User Flow
```
UI → StorageService → LocalStorageService → Hive
                 ↓
            Reactive Streams → UI Updates
```

#### Authenticated User Flow
```
UI → StorageService → FirestoreLayer → Firestore
                 ↓
            Real-time Listeners → UI Updates
                 ↓
            LocalStorageService → Hive (cache)
```

#### Account Conversion Flow
```
Anonymous Data (Hive) → Account Linking → Firestore Migration
                                      ↓
                            Local Data Cleanup → Firestore Only
```

### Benefits of Dual-Layer Architecture

#### Performance Benefits
- **Zero Loading States**: UI always shows data immediately
- **Instant CRUD**: Local operations complete in <1ms
- **Background Sync**: Network operations don't block UI
- **Optimistic Updates**: Changes appear instantly, sync later

#### User Experience Benefits
- **Offline-First**: Full functionality without internet
- **No Sign-up Friction**: Anonymous users get complete experience
- **Seamless Upgrade**: Account conversion preserves all data
- **Cross-device Sync**: Authenticated users get data everywhere

#### Technical Benefits
- **Simple Migration**: No complex data merging logic
- **Clean Separation**: Local and cloud concerns isolated
- **Error Resilience**: Local operations always succeed
- **Scalable**: Each layer optimized for its use case

### Implementation Strategy

The current implementation handles three user states:

#### Phase 1: Anonymous Users (Local Only)
```dart
// All operations go through LocalStorageService
// StorageService._useLocal returns true for anonymous users
await LocalStorageService.instance.init();
final stream = StorageService.instance.watchLists(); // Routes to _local.watchLists()
```

#### Phase 2: Account Linking (Automatic Migration)
```dart
// When user signs in, StorageService automatically migrates data
// Called internally by StorageService._ensureMigrationComplete()
final localLists = await _local.getAllLists();
for (final list in localLists) {
  await _firebase.createList(list); // Migrate each list to Firebase
}
await _local.clearAllData(); // Clear local data after migration
```

#### Phase 3: Authenticated Users (Cloud Only)
```dart
// All operations route to FirestoreLayer (Firebase with offline persistence)
// StorageService._useLocal returns false for authenticated users
final stream = StorageService.instance.watchLists(); // Routes to _firebase.watchLists()
// Firebase handles offline caching automatically via offline persistence
```

**Migration Tracking**: The app uses `SharedPreferences` to track migration completion per user, preventing repeated migrations.

## Deployment & Maintenance

### Deploy Security Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Test rules with emulator
firebase emulators:start --only firestore
```

### Monitor Security
- Enable Firestore audit logs
- Set up alerts for unusual access patterns
- Monitor rule evaluation metrics
- Track query performance and costs

### Regular Maintenance
- **Quarterly**: Review and update security rules
- **Monthly**: Analyze access patterns and rule performance
- **Weekly**: Monitor security alerts and logs

## Best Practices

### Local Storage (Hive)
- **Initialize Early**: Call `LocalStorageService.instance.init()` in main()
- **Dispose Properly**: Clean up stream controllers to prevent memory leaks
- **Use Reactive Streams**: Leverage `watchLists()` and `watchList()` for real-time UI
- **Batch Operations**: Group multiple updates to reduce stream emissions
- **Handle Errors**: Always wrap Hive operations in try-catch blocks

### Cloud Storage (Firestore) Security
- Always validate data on server-side (security rules)
- Use compound indexes for efficient queries
- Implement proper permission inheritance
- Monitor and log security events

### Dual-Layer Performance
- **Local-First Reads**: Always read from local storage first
- **Background Sync**: Perform cloud operations asynchronously
- **Optimistic Updates**: Update local storage immediately, sync later
- **Conflict Resolution**: Handle sync conflicts gracefully
- **Cache Invalidation**: Keep local cache fresh with cloud data

### Architecture Maintenance
- **Local Storage**: Monitor Hive database size and performance
- **Cloud Storage**: Regular security rule testing and index optimization
- **Integration**: Test data migration and sync scenarios
- **Monitoring**: Track local vs. cloud operation performance
- **Cost Management**: Optimize Firestore query patterns and storage usage

This architecture provides a robust, secure, and scalable foundation for collaborative real-time shopping lists while maintaining excellent performance and user experience. 