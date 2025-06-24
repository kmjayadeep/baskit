# Firebase Architecture & Security Rules Documentation

## 📋 Current Firebase Data Model

### Collection Structure

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

## 🏗️ Architecture Design Decisions

### 1. **Global Lists Collection**
- **Why**: Enables true list sharing across users
- **Benefit**: Single source of truth for shared lists
- **Implementation**: Lists are stored in `/lists/{listId}` instead of `/users/{userId}/lists/{listId}`

### 2. **Dual Membership Tracking**
```javascript
{
  "memberIds": ["uid1", "uid2", "uid3"],  // For efficient array-contains queries
  "members": {                           // For detailed member information
    "uid1": { role: "owner", permissions: {...} },
    "uid2": { role: "member", permissions: {...} }
  }
}
```

### 3. **Granular Permissions System**
Each member has specific permissions:
- **read**: Can view list and items
- **write**: Can add/edit items and list metadata
- **delete**: Can remove items
- **share**: Can invite new members

### 4. **Anonymous User Support**
- Anonymous users get full functionality
- Seamless upgrade to authenticated accounts
- Data migration handled during account linking

## 🔐 Security Rules Implementation

### Key Security Features

#### 1. **Authentication Requirements**
```javascript
function isAuthenticated() {
  return request.auth != null;  // Supports both anonymous and signed-in users
}
```

#### 2. **Membership Validation**
```javascript
function isListMember(listData) {
  return isAuthenticated() && 
         listData.memberIds is list &&
         request.auth.uid in listData.memberIds;
}
```

#### 3. **Permission-Based Access Control**
```javascript
function hasListPermission(listData, permission) {
  return isAuthenticated() &&
         listData.members is map &&
         request.auth.uid in listData.members &&
         listData.members[request.auth.uid].permissions[permission] == true;
}
```

#### 4. **Data Validation**
- List names: 1-100 characters
- Descriptions: max 500 characters
- Colors: must be valid hex format (#RRGGBB)
- Item names: 1-200 characters
- Quantity: optional string field

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

## 🛡️ Security Protections

### 1. **Ownership Protection**
- Only list owners can delete lists
- Owners cannot be removed from memberIds
- Owner role cannot be transferred via security rules

### 2. **Data Integrity**
- Required fields validation
- Field type validation
- String length limits
- Format validation (hex colors)

### 3. **Query Security**
- Users can only query lists they're members of
- Query result limits (max 100 lists, 10 users)
- Restricted field access in queries

### 4. **Membership Security**
- Users can only be added by members with 'share' permission
- Member data structure validation
- Automatic permission inheritance

## 🔄 Local-First Architecture Integration

### Offline-First Design
The security rules are designed to work seamlessly with the local-first architecture:

1. **Cached Permissions**: Local app caches permission checks
2. **Conflict Resolution**: Server-side validation ensures data integrity
3. **Sync Safety**: Rules prevent unauthorized modifications during sync
4. **Anonymous Support**: Full functionality for offline anonymous users

### Real-time Collaboration
- **Live Updates**: Real-time listeners work within security boundaries
- **Permission Changes**: Immediate effect on user capabilities
- **Member Management**: Real-time member addition/removal

## 🚀 Deployment Instructions

### 1. Deploy Security Rules
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project (if not done)
firebase init firestore

# Deploy the rules
firebase deploy --only firestore:rules
```

### 2. Test Security Rules
```bash
# Run local Firebase emulator for testing
firebase emulators:start --only firestore

# Run security rules unit tests (if created)
npm test -- --testNamePattern="security rules"
```

### 3. Monitor Security
- Enable Firestore audit logs
- Set up alerts for unusual access patterns
- Monitor rule evaluation metrics

## ⚡ Performance Considerations

### Optimized Queries
1. **Member Queries**: Use `memberIds` array for efficient `array-contains` queries
2. **Compound Indexes**: Required for complex queries with multiple filters
3. **Pagination**: Implement pagination for large lists

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

## 🔍 Monitoring & Analytics

### Key Metrics to Track
1. **Security Rule Evaluations**: Monitor rule complexity and performance
2. **Access Patterns**: Track read/write operations by user type
3. **Sharing Activity**: Monitor list sharing frequency and patterns
4. **Data Growth**: Track storage usage and query costs

### Recommended Alerts
- Unusual query patterns
- High rule evaluation costs
- Failed authentication attempts
- Excessive data reads/writes

## 🛠️ Maintenance & Updates

### Regular Security Reviews
1. **Quarterly**: Review and update security rules
2. **Monthly**: Analyze access patterns and rule performance
3. **Weekly**: Monitor security alerts and logs

### Rule Testing Strategy
1. **Unit Tests**: Test individual rule functions
2. **Integration Tests**: Test complete user workflows
3. **Load Tests**: Verify performance under scale
4. **Security Tests**: Attempt unauthorized access patterns

---

This architecture provides a robust, secure, and scalable foundation for the Baskit collaborative shopping list app while maintaining the local-first approach that ensures great user experience both online and offline. 