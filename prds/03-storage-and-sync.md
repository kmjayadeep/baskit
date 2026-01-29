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
- Local data is cleared after successful migration
- If migration fails, local data remains and retry is possible

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
- All storage calls return success/failure and user-friendly error strings
- UI surfaces failures via SnackBar or dialog
