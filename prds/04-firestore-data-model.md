# Baskit PRD - Firestore Data Model

## Collections
- `/users/{userId}`: user profiles
- `/lists/{listId}`: global lists collection
- `/lists/{listId}/items/{itemId}`: list items

## User Profile Requirements
- `profile.email`: string or null
- `profile.displayName`: string or null
- `profile.photoURL`: string or null
- `profile.createdAt`: timestamp
- `profile.isAnonymous`: boolean
- `listIds` and `sharedIds` arrays are retained for migration compatibility

## List Requirements
Required fields:
- `name` (1-100 chars)
- `description` (0-500 chars)
- `color` (hex string)
- `ownerId` (Firebase UID)
- `createdAt`, `updatedAt` timestamps
- `memberIds` array (must include owner)
- `members` map keyed by userId

Member object fields:
- `userId`
- `displayName`
- `email` (nullable)
- `avatarUrl` (nullable)
- `role` (owner | member)
- `joinedAt`
- `isActive` (default true)
- `permissions` map (read/write/delete/share booleans)

## Item Requirements
- `name` (1-200 chars)
- `quantity` (nullable string)
- `completed` (boolean)
- `createdAt`, `updatedAt` timestamps
- `completedAt` (nullable timestamp)
- `createdBy` (Firebase UID)

## Query Requirements
- Lists query: memberIds array-contains current user, ordered by updatedAt desc
- Items query: order by createdAt asc
- User lookup: profile.email equals input

## Index Requirements
- `lists`: memberIds ASC + updatedAt DESC
- `users`: profile.email ASC
