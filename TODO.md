# TODO

## 📈 **Overall Progress: Phase 1 - Member Management & Permissions**

### **✅ COMPLETED PHASES:**
- **Phase 1.1**: Show Full Member List ✅
- **Phase 1.2**: Fix Firestore-Model Data Mapping ✅  
- **Phase 1.3**: Implement Permission System ✅

### **🔄 CURRENT PHASE:**
- **Phase 1.4**: Enhanced Member Management UI (Ready to implement)

### **⏳ UPCOMING:**
- **Phase 1.5**: Recent Contacts & Share UX  
- **Phase 1.6**: Integration & Testing

---

## Phase 1: Member Management & Permissions System

**Issues to Address**:
- Data loss: Firestore rich member data (roles, permissions, joinedAt) → Model simple strings
- Missing: Role-based permissions in UI
- Missing: Recent contacts for easier sharing

### **Phase 1.1: Show Full Member List** ✅
- ✅ Create `MemberListDialog` with member avatars and "Invite More" button
- ✅ Make sharing status in `ListHeaderWidget` clickable
- ✅ Add `ownerId` field to `ShoppingList` model and fix ownership detection

### **Phase 1.2: Fix Firestore-Model Data Mapping** ✅
**Goal**: ~~Stop losing rich member data from Firestore and properly map to enhanced model~~

~~**Priority**: **CRITICAL** - This is blocking all advanced member features!~~

~~**🚨 Critical Issue**: Firestore stores rich member data but we're only keeping display names!~~

**✅ RESOLVED**: Rich member data is now properly preserved and mapped!

**Completed Steps**:
1. ✅ **Enhanced Member Model** - Created comprehensive `ListMember` model with roles and permissions
2. ✅ **Updated ShoppingList Model** - Added `memberDetails` field for rich data + backward compatibility
3. ✅ **Fixed Firestore Service Mapping** - Now preserves ALL member data (roles, permissions, joinedAt)
4. ✅ **Regenerated Hive Adapters** - Updated for new model structure
5. ✅ **Updated Member List Dialog** - Now displays rich role information with emojis

**Firestore Structure:**
```firestore
members: {
  "user_id_123": {
    userId: "user_id_123",
    role: "owner",           // ← LOST in current mapping
    displayName: "John Doe",
    email: "john@example.com",
    joinedAt: Timestamp,     // ← LOST in current mapping
    permissions: {           // ← LOST in current mapping
      read: true, write: true, delete: true, share: true
    }
  }
}
```

**Steps**:
1. **Create Enhanced Member Model**
   ```dart
   // lib/models/list_member_model.dart
   class ListMember {
     final String userId;       // Firebase UID (primary key)
     final String displayName;  // Name to show in UI
     final String? email;       // Email address
     final String? avatarUrl;   // Profile picture URL
     final MemberRole role;     // owner, editor, viewer
     final DateTime joinedAt;   // When they joined the list
     final bool isActive;       // Still has access
     final Map<String, bool> permissions; // Granular permissions
   }
   
   enum MemberRole { owner, editor, viewer }
   ```

2. **Update ShoppingList Model**
   - Keep `List<String> members` for backward compatibility (local-only mode)
   - Add `List<ListMember>? memberDetails` for rich Firestore data
   - Update Hive type adapters

3. **Fix Firestore Service Mapping**
   - Update `getUserLists()` and `getListById()` to properly map rich member data
   - Create `ListMember` objects from Firestore `members` map
   - Populate both `members` (simple) and `memberDetails` (rich) fields

4. **Update Member List Dialog**
   - Use `memberDetails` when available (Firestore)
   - Fallback to `members` for local-only mode
   - Show roles, join dates, permissions in UI

### **Phase 1.3: Implement Permission System** ✅
**Goal**: ~~Use the rich permission data from Firestore to control UI and operations~~

**✅ COMPLETED**: Comprehensive permission system implemented and tested!

**Completed Steps**:
1. ✅ **Permission Service** - Created robust permission checking with owner/member logic
2. ✅ **Updated ViewModels** - All operations now validate permissions before execution
3. ✅ **Permission-Based UI** - Buttons show/hide based on user permissions
4. ✅ **Comprehensive Tests** - 38 tests covering all permission scenarios
5. ✅ **Simplified Role System** - Owner = full access, Member = permission-based access

**Key Features**:
- **Owner Role**: Full admin access regardless of individual permissions
- **Member Role**: Access based on granular permission settings (read/write/delete/share)
- **Local-Only Mode**: Full access for single-user lists
- **UI Integration**: Share, edit, delete buttons only appear when user has permissions
- **Item-Level Permissions**: Edit/delete actions disabled for unauthorized users

**Steps**:
1. **Permission Service**
   ```dart
   // lib/services/permission_service.dart
   class PermissionService {
     // Check specific permissions from Firestore data
     static bool hasPermission(ListMember member, String permission) =>
       member.permissions[permission] == true;
     
     // Role-based convenience methods
     static bool canEditItems(ListMember member) => 
       hasPermission(member, 'write');
     
     static bool canDeleteList(ListMember member) => 
       member.role == MemberRole.owner; // Only owners can delete lists
     
     static bool canManageMembers(ListMember member) => 
       hasPermission(member, 'share') && member.role == MemberRole.owner;
   }
   ```

2. **Update ViewModels with Permission Checks**
   - Add `getCurrentUserMember()` method to get current user's member data
   - Add permission validation to all operations (add/edit/delete items, share, etc.)
   - Return meaningful error messages for unauthorized actions
   - Use Firestore's `hasListPermission()` method for server-side validation

3. **Update UI Based on Permissions**
   - Show/hide buttons based on user permissions
   - Disable actions for unauthorized users
   - Add visual indicators for permission levels
   - Update member list to show roles and permissions

### **Phase 1.4: Enhanced Member Management UI** ⏳
**Goal**: Rich member management interface using the recovered Firestore data

**Current Status**: Ready to implement - rich member data and permissions system complete!

**Steps**:
1. **Enhanced Member List Dialog** 
   - ✅ Show member roles with icons (👑 owner, 👤 member)
   - 🔄 Add role change functionality (owner only)
   - 🔄 Add remove member functionality (owner only)
   - 🔄 Show permission indicators (read/write/delete/share)

2. **Member Management Actions**
   - 🔄 Add "Change Role" dropdown for owners
   - 🔄 Add "Remove Member" action with confirmation
   - 🔄 Add "Transfer Ownership" functionality
   - 🔄 Show member activity indicators

3. **Permission-Aware UI**
   - 🔄 Hide management actions for non-owners
   - 🔄 Show permission tooltips
   - 🔄 Different UI for different permission levels

### **Phase 1.5: Recent Contacts & Share UX** ⏳
**Goal**: Add "Recent Contacts" feature to improve sharing experience

**User Problem**: "I have to type the same email addresses over and over when sharing lists"

**Solution**: Track sharing history and provide quick selection from recent contacts

**Steps**:
1. **Create Recent Contacts Data Model**
   ```dart
   // lib/models/recent_contact_model.dart
   class RecentContact {
     final String email;
     final String displayName;
     final String? avatarUrl;
     final DateTime lastSharedAt;
     final int shareCount;        // How many times shared with this person
     final List<String> sharedListIds; // Which lists were shared
   }
   ```

2. **Track Sharing History**
   - Update `shareListWithUser()` to record sharing activity
   - Store recent contacts in user profile document
   - Limit to last 20-50 contacts to avoid bloat
   - Update contact data when sharing (frequency, last shared date)

3. **Enhanced Share Dialog UI**
   ```dart
   ShareListDialog:
   ┌─────────────────────────────┐
   │ Share "Grocery List"        │
   │                             │
   │ 📧 Recent Contacts          │
   │ ┌─────────────────────────┐ │
   │ │ [👤] John Doe           │ │ <- Tap to select
   │ │      john@example.com   │ │
   │ │ [👤] Jane Smith         │ │ 
   │ │      jane@company.com   │ │
   │ └─────────────────────────┘ │
   │                             │
   │ ✉️ Or enter new email:      │
   │ [_________________] [Send]   │
   │                             │
   │ 🎯 Role: [Editor ▼]         │
   └─────────────────────────────┘
   ```

4. **Smart Contact Suggestions**
   - Sort by frequency and recency
   - Show contact avatars if available
   - Indicate how many lists already shared with each contact
   - Filter out users already in current list

5. **Storage Strategy**
   - **Firestore**: Store in user profile (`users/{userId}/recentContacts`)
   - **Local**: Store in Hive for offline access
   - **Sync**: Merge local and remote contact history

### **Phase 1.6: Integration & Testing** ⏳
**Goal**: Ensure all components work with the enhanced member and recent contacts system

**Steps**:
1. **Update Extension Methods**
   - Update `sharingText` to use rich member data when available
   - Add role-aware descriptions ("Shared with 2 editors, 1 viewer")
   - Handle fallback to simple strings for local-only mode

2. **Integration Testing**
   - Test recent contacts tracking and retrieval
   - Test contact selection from recent contacts list
   - Test contact frequency and recency sorting
   - Verify contacts sync between local and Firestore

3. **Comprehensive Testing**
   - Test permission enforcement in all operations
   - Test member role display accuracy
   - Test ownership detection with real Firestore data
   - Test fallback to simple mode for local-only lists
   - Verify no data loss during Firestore sync
   - Test recent contacts persistence and sync

### **Technical Considerations**

**Data Mapping (Priority 1)**:
- **FIX ASAP**: Firestore → Model mapping is losing 80% of member data
- Create proper `ListMember` model to capture rich Firestore data
- Dual-mode support: Rich data (Firestore) + Simple strings (local-only)
- Update Hive type adapters for new models

**Backward Compatibility**:
- Keep `List<String> members` for existing local lists
- Add `List<ListMember>? memberDetails` for Firestore lists
- Graceful fallback when rich data unavailable
- Migration strategy for existing users

**Performance**:
- Firestore already provides efficient member queries via `memberIds`
- Client-side permission checks using cached member data
- Avoid repeated permission lookups
- Consider member data caching strategy

**Security & Permissions**:
- Firestore already has granular permissions system implemented
- Use existing `hasListPermission()` for server-side validation
- Client-side permission checks for UI optimization
- Prevent permission escalation attacks

**UX/UI**:
- Progressive enhancement: Show simple data first, enrich when available
- Clear role indicators (👑 owner, ✏️ editor, 👁️ viewer)
- Permission tooltips and explanations
- Graceful error handling for permission denials

**Recent Contacts System**:
- Store contact history in user profile for cross-device sync
- Limit contact history to prevent database bloat (50 max contacts)
- Smart sorting: Combine frequency + recency for best suggestions
- Offline support: Cache recent contacts locally for airplane mode
- Privacy: Only store contacts that user has actively shared with

### **Future Enhancements** 🔮
- **Member Activity Log**: Track member actions
- **Invitation Links**: Share lists via links with predefined roles
- **Bulk Member Management**: CSV import, role templates
- **Advanced Permissions**: Item-level permissions, time-based access
- **Member Notifications**: Notify on role changes, removals

**Recent Contacts Enhancements**:
- **Contact Groups**: Organize frequent contacts (Family, Work, Friends)
- **Contact Search**: Search through contact history by name/email
- **Contact Profiles**: Show sharing history per contact ("Shared 5 lists with John")
- **Smart Suggestions**: "You often share grocery lists with Jane"
- **Contact Import**: Import from phone contacts or Google Contacts
- **Favorite Contacts**: Pin most-used contacts to the top

---
*Note: This plan builds incrementally, allowing review at each phase while maintaining backward compatibility and preparing for advanced permission features.*
