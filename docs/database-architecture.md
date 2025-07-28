# Database Architecture & Security

## Overview
Baskit uses Firestore as its real-time database with a carefully designed data model that supports both individual use and collaborative sharing while maintaining security and performance.

## Data Model Design

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

### Security
- Always validate data on server-side (security rules)
- Use compound indexes for efficient queries
- Implement proper permission inheritance
- Monitor and log security events

### Performance
- Use `memberIds` array for efficient membership queries
- Implement pagination for large result sets
- Cache permissions locally when possible
- Optimize query patterns for Firestore pricing

### Maintenance
- Regular security rule testing
- Performance monitoring and optimization
- Index management and cleanup
- Cost monitoring and optimization

This architecture provides a robust, secure, and scalable foundation for collaborative real-time shopping lists while maintaining excellent performance and user experience. 