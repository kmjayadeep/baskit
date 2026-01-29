# Firestore Data Model

## Overview
Firestore stores user profiles and shared lists for authenticated users. Guests stay local until they upgrade, but anonymous Firebase users still get a `/users/{uid}` profile document when Firebase is configured.

## Collection Structure
```
/users/{userId}                User profiles
/lists/{listId}                Global lists collection
  └── /items/{itemId}           Shopping items subcollection
```

## Users Collection
**Path:** `/users/{userId}`

```json
{
  "profile": {
    "email": "john@example.com",
    "displayName": "John Doe",
    "photoURL": "https://...",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "isAnonymous": true
  },
  "listIds": ["list_id_1"],
  "sharedIds": ["shared_list_id_1"]
}
```

Notes:
- `listIds` and `sharedIds` are deprecated but retained for migration.
- Anonymous users have `isAnonymous: true` and `email` may be null.

## Lists Collection
**Path:** `/lists/{listId}`

```json
{
  "id": "abc123",
  "name": "Weekly Groceries",
  "description": "Items for this week",
  "color": "#FF5722",
  "ownerId": "user_firebase_uid",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-16T14:20:00.000Z",
  "memberIds": ["user_firebase_uid"],
  "members": {
    "user_firebase_uid": {
      "userId": "user_firebase_uid",
      "displayName": "John Doe",
      "email": "john@example.com",
      "role": "owner",
      "joinedAt": "2024-01-15T10:30:00.000Z",
      "permissions": {
        "read": true,
        "write": true,
        "delete": true,
        "share": true
      }
    }
  }
}
```

Member fields:
- `avatarUrl` and `isActive` are optional and may be absent today
- `permissions` map drives server-side access control

## Items Subcollection
**Path:** `/lists/{listId}/items/{itemId}`

```json
{
  "id": "item_123",
  "name": "Milk",
  "quantity": "2 gallons",
  "completed": false,
  "createdAt": "2024-01-16T10:00:00.000Z",
  "updatedAt": "2024-01-16T10:00:00.000Z",
  "completedAt": null,
  "createdBy": "user_firebase_uid"
}
```

Notes:
- `completedAt` is only set when an item is completed
- `updatedAt` updates on writes

## Query Patterns
```javascript
// User lists (owned + shared)
db.collection('lists')
  .where('memberIds', 'array-contains', userId)
  .orderBy('updatedAt', 'desc')
  .limit(100)

// Items for a list
db.collection('lists').doc(listId)
  .collection('items')
  .orderBy('createdAt', 'desc')
```

## Recommended Indexes
```
Collection: lists
Fields:
  - memberIds (Ascending)
  - updatedAt (Descending)

Collection: users
Fields:
  - profile.email (Ascending)
```
