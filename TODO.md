# TODO

## Phase 1: Member Management & Permissions System

### **Overview**
Implement a comprehensive member management system that shows full member lists and supports future permission controls for shared shopping lists.

### **Current State Analysis**
- ✅ `ShoppingList` model has `List<String> members` (names/emails)
- ✅ `ListHeaderWidget` shows sharing status ("Shared with John" or "Shared with 3 people")
- ✅ `sharingText` extension shows condensed member info
- ✅ Share functionality exists in `ListDetailScreen._showShareDialog()`

### **Phase 1.1: Show Full Member List** ⏳
**Goal**: Allow users to view complete member list with proper UI

**Steps**:
1. **Create Member List Dialog Widget**
   - `lib/screens/list_detail/widgets/dialogs/member_list_dialog.dart`
   - Display all members in a scrollable list
   - Show member avatars (initials or icons)
   - Include current user in the display
   - Add "Invite More" button

2. **Make Sharing Status Clickable**
   - Update `ListHeaderWidget` to make sharing status tappable
   - Add `onTap` callback to show member list dialog
   - Visual indication (underline/color) that it's clickable

3. **Update Extension Methods**
   - Add `String get sharingSubtitle` for secondary info
   - Keep existing `sharingText` for backward compatibility

### **Phase 1.2: Enhanced Member Data Model** ⏳
**Goal**: Prepare data structures for future permissions

**Steps**:
1. **Create Member Model**
   ```dart
   // lib/models/list_member_model.dart
   class ListMember {
     final String id;           // User ID or email
     final String displayName;  // Name to show
     final String? email;       // Email if available
     final String? avatarUrl;   // Profile picture URL
     final MemberRole role;     // Owner, Editor, Viewer
     final DateTime joinedAt;   // When they joined
     final bool isActive;       // Still has access
   }
   
   enum MemberRole {
     owner,    // Full control (delete list, manage members)
     editor,   // Can add/edit/delete items
     viewer,   // Can only view items
   }
   ```

2. **Migration Strategy**
   - Keep `List<String> members` for backward compatibility
   - Add `List<ListMember> memberDetails` field
   - Create migration logic in `StorageService`
   - Update sharing functionality to use new model

3. **Update Repository Pattern**
   - Add member management methods to `ShoppingRepository`
   - `Future<void> updateMemberRole(String listId, String memberId, MemberRole role)`
   - `Future<void> removeMember(String listId, String memberId)`
   - `Future<List<ListMember>> getListMembers(String listId)`

### **Phase 1.3: Permission System** ⏳
**Goal**: Implement role-based permissions for list operations

**Steps**:
1. **Permission Checker Service**
   ```dart
   // lib/services/permission_service.dart
   class PermissionService {
     static bool canEditItems(ListMember member) => 
       member.role == MemberRole.owner || member.role == MemberRole.editor;
     
     static bool canDeleteList(ListMember member) => 
       member.role == MemberRole.owner;
     
     static bool canManageMembers(ListMember member) => 
       member.role == MemberRole.owner;
   }
   ```

2. **Update UI Based on Permissions**
   - Disable add/edit/delete buttons based on user role
   - Show permission indicators in member list
   - Update `ListDetailScreen` AppBar actions
   - Update `ItemCardWidget` edit/delete visibility

3. **Update ViewModels**
   - Add permission checks in `ListDetailViewModel`
   - Return permission errors for unauthorized actions
   - Update `ListFormViewModel` for edit restrictions

### **Phase 1.4: Member Management UI** ⏳
**Goal**: Full member management interface

**Steps**:
1. **Enhanced Member List Dialog**
   - Show member roles with icons
   - Add role change dropdown (if user has permission)
   - Add remove member functionality
   - Show pending invitations

2. **Member Management Screen** (Future)
   - Dedicated screen for complex member management
   - Batch operations (promote multiple members)
   - Member invitation history
   - Access from list settings

### **Phase 1.5: Integration & Testing** ⏳
**Goal**: Ensure all components work together seamlessly

**Steps**:
1. **Update Extension Methods**
   - Update `sharingText` to use `ListMember` model
   - Add role-aware text descriptions
   - Handle mixed permission scenarios

2. **Update Share Functionality**
   - Assign default role when sharing
   - Show role selection in share dialog
   - Handle duplicate invitation attempts

3. **Testing & Validation**
   - Test permission enforcement
   - Test member list display
   - Test role changes and removals
   - Test backward compatibility

### **Technical Considerations**

**Data Storage**:
- Use Hive type adapters for new models
- Maintain backward compatibility during migration
- Consider Firebase sync implications

**Performance**:
- Cache member details to avoid repeated lookups
- Efficient member role checking
- Paginate member lists for large groups

**Security**:
- Validate permissions on both client and server
- Prevent privilege escalation
- Handle offline permission checks

**UX/UI**:
- Clear visual indicators for roles
- Intuitive permission management
- Graceful handling of permission errors

### **Future Enhancements** 🔮
- **Member Activity Log**: Track member actions
- **Invitation Links**: Share lists via links with predefined roles
- **Bulk Member Management**: CSV import, role templates
- **Advanced Permissions**: Item-level permissions, time-based access
- **Member Notifications**: Notify on role changes, removals

---

*Note: This plan builds incrementally, allowing review at each phase while maintaining backward compatibility and preparing for advanced permission features.*