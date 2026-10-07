# Baskit PRD - Storage & Sync

## Storage Layers
- **Local layer (Hive)**: primary storage for guests and local-only mode
- **Cloud layer (Firestore)**: primary storage for authenticated users

## Routing Rules
- Storage routing is based on auth state
- Anonymous users (or Firebase unavailable) use local storage
- Authenticated users use Firestore with offline persistence

## Migration Requirements
- Migration runs once per authenticated user
- Migration copies all local lists/items to Firestore
- Migration sets a persistent completion flag per user
- Local data is cleared only after every local list has been migrated successfully and the per-user migration flag is set
- Per-list migration failures keep the migration pending: local data is retained and the next authenticated access retries the copy

## Sync Requirements
- Firestore reads/writes use offline persistence
- Lists should update in real time for all members
- Local streams must emit updates immediately on local writes

## Share Requirements
- Sharing is only available for authenticated users
- Share by email; validate that target user exists
- Prevent duplicate member entries
- Members get default permissions (read/write/delete/share)

## Error Handling
- Most storage calls return boolean success/failure
- Sharing returns `ShareResult` with user-facing error messages
- Current implementation returns a generic share failure for most backend errors because Firebase share-layer exceptions are converted to `false` before reaching `StorageService`
- UI surfaces failures via SnackBar or dialog
