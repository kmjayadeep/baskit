## Bug Fixes

### 1. MigrationService duplicate prevention
**Problem:** During migration, if some lists succeed and others fail, retrying would call `createList()` for already-migrated lists, creating duplicates in Firestore.

**Fix:** Before creating, check if the list already exists in the cloud using `watchList(list.id).first`. If it exists, use `updateList()` instead.

### 2. LocalStorageService resource leak
**Problem:** `dispose()` closed stream controllers but never closed the Hive box, causing file handle leaks that accumulate over time.

**Fix:** Changed `dispose()` to async and added `await _listsBox.close()` when the box is open.

### 3. Safe JSON parsing for Hive models
**Problem:** `ShoppingList.fromJson()`, `ShoppingItem.fromJson()`, and `ListMember.fromJson()` would throw on corrupted/incomplete Hive data — missing required fields, unparseable dates, or null values — crashing the app on startup.

**Fix:**
- Added null-safe defaults for all fields (`id=''`, `name=''`, etc.)
- Replaced `DateTime.parse()` with `DateTime.tryParse()` with `DateTime.now()` fallback
- Added `fromJsonSafe()` constructors for resilient Hive deserialization
- `ShoppingList.fromJson()` now uses `fromJsonSafe()` for nested items and members

### 4. Updated dispose() interface
All `ShoppingRepository` implementations updated to `Future<void> dispose()` to support async Hive box closing.

## Changed Files
- `app/lib/models/list_member_model.dart` — safe JSON parsing + fromJsonSafe
- `app/lib/models/shopping_item_model.dart` — safe JSON parsing + fromJsonSafe
- `app/lib/models/shopping_list_model.dart` — safe JSON parsing + uses fromJsonSafe
- `app/lib/repositories/firestore_shopping_repository.dart` — async dispose
- `app/lib/repositories/local_shopping_repository.dart` — async dispose
- `app/lib/repositories/shopping_repository.dart` — interface: async dispose
- `app/lib/repositories/storage_shopping_repository.dart` — async dispose
- `app/lib/services/local_storage_service.dart` — async dispose + close Hive box
- `app/lib/services/migration_service.dart` — upsert instead of always create
- `app/lib/services/storage_service.dart` — async dispose
- `app/test/integration/leave_list_flow_test.dart` — await dispose
- `app/test/integration/local_first_flow_test.dart` — await dispose
- `app/test/integration/remove_member_flow_test.dart` — await dispose
- `app/test/repositories/storage_shopping_repository_test.dart` — await dispose
- `app/test/widget_test.dart` — await dispose