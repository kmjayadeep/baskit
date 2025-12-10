# Firestore Data Model

## Overview

This document describes the Firestore database schema for Baskit's collaborative shopping list application.

## Collection Structure

```
/users/{userId}                    User profiles
/lists/{listId}                    Global lists collection
    └── /items/{itemId}            Shopping items subcollection
```

---

## Collections

### 1. Users Collection

**Path**: `/users/{userId}`

**Document Structure**:

```json
{
  "profile": {
    "email": "john@example.com",
    "displayName": "John Doe",
    "photoURL": "https://lh3.googleusercontent.com/...",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "isAnonymous": false
  },
  "listIds": ["list_id_1", "list_id_2"],
  "sharedIds": ["shared_list_id_1"]
}
```

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `profile.email` | String | No | User's email address |
| `profile.displayName` | String | No | User's display name |
| `profile.photoURL` | String | No | Profile picture URL |
| `profile.createdAt` | Timestamp | Yes | Account creation timestamp |
| `profile.isAnonymous` | Boolean | Yes | Whether user is anonymous |
| `listIds` | Array\<String\> | No | Lists owned by user (deprecated) |
| `sharedIds` | Array\<String\> | No | Lists shared with user (deprecated) |

**Notes**:
- `listIds` and `sharedIds` are deprecated but kept for migration
- User document is created on first sign-in

---

### 2. Lists Collection

**Path**: `/lists/{listId}`

**Document Structure**:

```json
{
  "id": "abc123",
  "name": "Weekly Groceries",
  "description": "Items for this week's shopping",
  "color": "#FF5722",
  "ownerId": "user_firebase_uid",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-16T14:20:00.000Z",
  "memberIds": [
    "user_firebase_uid",
    "member_uid_1",
    "member_uid_2"
  ],
  "members": {
    "user_firebase_uid": {
      "userId": "user_firebase_uid",
      "displayName": "John Doe",
      "email": "john@example.com",
      "avatarUrl": "https://...",
      "role": "owner",
      "joinedAt": "2024-01-15T10:30:00.000Z",
      "isActive": true,
      "permissions": {
        "read": true,
        "write": true,
        "delete": true,
        "share": true
      }
    },
    "member_uid_1": {
      "userId": "member_uid_1",
      "displayName": "Jane Smith",
      "email": "jane@example.com",
      "avatarUrl": null,
      "role": "member",
      "joinedAt": "2024-01-16T09:15:00.000Z",
      "isActive": true,
      "permissions": {
        "read": true,
        "write": true,
        "delete": true,
        "share": false
      }
    }
  }
}
```

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique list identifier |
| `name` | String | Yes | List name (1-100 characters) |
| `description` | String | Yes | List description (max 500 characters) |
| `color` | String | Yes | Hex color code (#RRGGBB format) |
| `ownerId` | String | Yes | Firebase UID of list owner |
| `createdAt` | Timestamp | Yes | Creation timestamp |
| `updatedAt` | Timestamp | Yes | Last modification timestamp |
| `memberIds` | Array\<String\> | Yes | Array of member UIDs (for queries) |
| `members` | Map\<String, Object\> | Yes | Detailed member information |

**Member Object Structure**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | String | Yes | Firebase UID |
| `displayName` | String | Yes | Display name |
| `email` | String | No | Email address |
| `avatarUrl` | String | No | Profile picture URL |
| `role` | String | Yes | "owner" or "member" |
| `joinedAt` | Timestamp | Yes | When member joined |
| `isActive` | Boolean | Yes | Membership status |
| `permissions.read` | Boolean | Yes | Can view list and items |
| `permissions.write` | Boolean | Yes | Can add/edit items |
| `permissions.delete` | Boolean | Yes | Can delete items |
| `permissions.share` | Boolean | Yes | Can invite members |

**Validation Rules**:
- `name`: 1-100 characters
- `description`: max 500 characters
- `color`: must match `^#[0-9A-Fa-f]{6}$`
- `memberIds` must include `ownerId`
- Owner must exist in `members` map with role "owner"

---

### 3. Items Subcollection

**Path**: `/lists/{listId}/items/{itemId}`

**Document Structure**:

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

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique item identifier |
| `name` | String | Yes | Item name (1-200 characters) |
| `quantity` | String | No | Optional quantity/notes |
| `completed` | Boolean | Yes | Completion status |
| `createdAt` | Timestamp | Yes | Creation timestamp |
| `updatedAt` | Timestamp | Yes | Last modification timestamp |
| `completedAt` | Timestamp | No | When item was completed |
| `createdBy` | String | Yes | Firebase UID of creator |

**Validation Rules**:
- `name`: 1-200 characters
- `completed`: must be boolean
- `createdBy`: must be a valid UID

---

## Query Patterns

### Get User's Lists

```javascript
db.collection('lists')
  .where('memberIds', 'array-contains', userId)
  .orderBy('updatedAt', 'desc')
  .limit(100)
```

### Get List Items

```javascript
db.collection('lists').doc(listId)
  .collection('items')
  .orderBy('createdAt', 'desc')
```

### Find User by Email

```javascript
db.collection('users')
  .where('profile.email', '==', email)
  .limit(1)
```

---

## Indexes

### Required Composite Indexes

**Lists Query Index**:
```
Collection: lists
Fields:
  - memberIds (Ascending)
  - updatedAt (Descending)
```

**User Email Lookup Index**:
```
Collection: users
Fields:
  - profile.email (Ascending)
```

---

## Member Roles & Permissions

### Role Types

| Role | Description |
|------|-------------|
| `owner` | Full admin access (ignores individual permissions) |
| `member` | Access controlled by permissions map |

### Permission Matrix

| Operation | Owner | Member (with permission) |
|-----------|-------|-------------------------|
| Read list | ✅ | ✅ (read: true) |
| Edit list metadata | ✅ | ✅ (write: true) |
| Delete list | ✅ | ❌ |
| Add items | ✅ | ✅ (write: true) |
| Edit items | ✅ | ✅ (write: true) |
| Delete items | ✅ | ✅ (delete: true) |
| Share list | ✅ | ✅ (share: true) |

---

## Data Flow

### Creating a List

1. User creates list document in `/lists/{listId}`
2. Set `ownerId` to creator's UID
3. Add creator to `memberIds` array
4. Add creator to `members` map with role "owner"

### Sharing a List

1. Look up user by email in `/users` collection
2. Add user's UID to list's `memberIds` array
3. Add user to list's `members` map with role "member"
4. Set appropriate permissions in user's member object

### Adding Items

1. Create item document in `/lists/{listId}/items/{itemId}`
2. Set `createdBy` to current user's UID
3. Update parent list's `updatedAt` timestamp

---

## Storage Architecture

### Guest Users (Local Only)
- Data stored in local Hive database
- No Firestore synchronization
- No network required

### Authenticated Users (Cloud Sync)
- All data synced to Firestore
- Items stored in subcollections
- Real-time listeners for collaboration
- Offline persistence enabled

### Account Migration
- Local data migrated to Firestore on first sign-in
- User document created in `/users/{userId}`
- Lists moved to `/lists` collection
- Items moved to subcollections

