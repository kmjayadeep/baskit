# Database Architecture & Security

## Overview
Baskit uses a dual-layer storage architecture:
- **Local Storage (Hive)** for guest usage and local-only mode
- **Cloud Storage (Firestore)** for authenticated users

Firebase is optional. If Firebase is not configured, the app runs entirely in local mode. If Firebase is configured, the app signs in anonymously on launch but still keeps list data local until the user upgrades with Google Sign-In.

## Storage Routing
`StorageService` routes operations based on auth state:
```dart
// True for anonymous Firebase users or when Firebase is unavailable
bool get _useLocal => FirebaseAuthService.isAnonymous;
```

### Guest Modes
1. **Local-only (no Firebase config)**
   - No Firebase connection
   - All list data in Hive

2. **Firebase-enabled guest (anonymous auth)**
   - Firebase anonymous auth on launch
   - User profile created in Firestore
   - List data remains local in Hive

### Authenticated Mode
- Google Sign-In links the anonymous account
- Local data migrates to Firestore
- All list operations route to Firestore with offline persistence

## Guest-First User Journey
```
1) App launch
   - Firebase init (if configured)
   - Anonymous sign-in
   - Lists stay in Hive

2) User upgrades to Google
   - Anonymous account linked
   - Local lists migrate to Firestore
   - Local Hive data cleared

3) Authenticated usage
   - Firestore is the source of truth
   - Offline persistence enabled
```

## Local Storage Architecture
Hive stores lists in a single box:
```
shopping_lists (Box<ShoppingList>)
└── {listId}: ShoppingList
    └── items: List<ShoppingItem>
```

`LocalStorageService` provides:
- `watchLists()` and `watchList(id)` streams
- CRUD operations for lists and items
- Sorting of completed vs active items

## Cloud Storage Architecture
Firestore uses a global lists collection for sharing:
```
/users/{userId}
/lists/{listId}
  └── /items/{itemId}
```

Key points:
- List membership is stored in `memberIds` and `members` map
- Permission checks are enforced via Firestore security rules
- Firestore offline persistence is enabled on startup

## Migration Strategy
Migration runs on first authenticated use:
1. `StorageService` checks `migration_complete_<uid>` in `SharedPreferences`
2. Local lists are copied to Firestore
3. Migration flag is set
4. Hive data is cleared

## Data Flow Patterns
### Guest or Local-only
```
UI → StorageService → LocalStorageService → Hive
```

### Authenticated
```
UI → StorageService → FirestoreLayer → Firestore
```

## Security Rules Summary
Firestore rules enforce:
- Only list members can read lists/items
- Only owners can delete lists
- Permission-based writes for members
- Validation on list/item fields

## Best Practices
- Keep list data local until account upgrade
- Use `StorageService` rather than talking to Firestore directly
- Test migration and sign-out flows with real devices
