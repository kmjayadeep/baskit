# TODO

## Tech debts

1. ~~Rename `memberDetails` to `members` in list model to align with firestore data~~ ✅ DONE
2. ~~Remove ListMember.fromLegacyString, Listmember.displayString~~ ✅ DONE

listmodel
3. ~~listmodel.sharedMembers should check ownerId instead of role, also remove legacy part~~ ✅ DONE
4. ~~listmodel.sharedMemberDisplayNames should use sharedMembers method internally~~ ✅ DONE
5. ~~listmodel.hasRichMemberData should be removed~~ ✅ DONE
6. ~~allmembers should be fixed to not use legacy logic~~ ✅ DONE
7. ~~allMemberDisplayNames. Do we need all of these methods? Can we simplify?~~ ✅ DONE

## Active Priorities

### 1. Leave List Feature (Priority 1) 🆕

**Goal**: Allow members to leave lists that have been shared with them.

**Implementation Plan**:

#### **Phase 1: Backend - Repository & Services**
1. ~~Add `removeMember(listId, userId)` method to ShoppingRepository interface~~ ✅ DONE
2. ~~Implement in StorageShoppingRepository (delegates to FirestoreService and LocalStorageService)~~ ✅ DONE
3. ~~Implement `removeMemberFromList()` in FirestoreService~~ ✅ DONE
   - Use Firestore transaction to filter members array
   - Update security rules: allow member to remove themselves
4. ~~Implement `removeMemberFromList()` in LocalStorageService~~ ✅ DONE
   - Update Hive cache
   - Trigger stream update
5. ~~Add unit tests for repository methods~~ ✅ DONE

#### **Phase 2: ViewModel Integration**
6. ~~Add `removeMember(userId)` method to ListDetailViewModel~~ ✅ DONE
7. ~~Add `leaveList()` convenience method (calls removeMember with current userId)~~ ✅ DONE
8. ~~Handle state updates and error propagation~~ ✅ DONE
9. ~~Add ViewModel unit tests~~ ✅ DONE

#### **Phase 3: UI Implementation**
10. ~~Create `LeaveListConfirmationDialog` widget~~ ✅ DONE
11. ~~Add "Leave List" option to list detail screen app bar menu~~ ✅ DONE
12. ~~Add permission check: only show if user is a member (not owner)~~ ✅ DONE
13. ~~Wire up to ViewModel and handle navigation to lists screen on success~~ ✅ DONE
14. ~~Add success/error snackbar feedback~~ ✅ DONE
15. ~~Add widget tests for leave list dialog and interactions~~ ✅ DONE

#### **Phase 4: Testing & Polish**
16. ~~Add integration tests for complete leave list flow~~ ✅ DONE
17. ~~Test edge cases: leaving while viewing list, network failures~~ ✅ DONE
18. Manual testing across different scenarios (pending)

**Technical Details**:
```dart
// Repository
abstract class ShoppingRepository {
  Future<void> removeMember(String listId, String userId);
}

// ViewModel
class ListDetailViewModel {
  Future<bool> leaveList() async {
    return await removeMember(currentUserId);
  }
  Future<bool> removeMember(String userId) async { /* ... */ }
}

// UI - ListDetailScreen
PopupMenuButton(
  items: [
    if (_isListMember && !_isListOwner)
      PopupMenuItem(child: Text('Leave List'), onTap: _showLeaveDialog)
  ]
)
```

---

### 2. Remove Member Feature (Priority 2) 🆕

**Goal**: Allow list owners to remove members from their lists.

**Implementation Plan**:

#### **Phase 1: Backend** (Shared with Leave List)
1. Use same `removeMember(listId, userId)` method from Leave List feature
2. Update Firestore security rules: allow owner to remove any member
3. Add validation: prevent owner from removing themselves

#### **Phase 2: UI Implementation**
4. Create `RemoveMemberConfirmationDialog` widget with member name display
5. Enhance `MemberListDialog` to show remove button next to each member
6. Add permission checks:
   - Only show remove buttons if current user is owner
   - Hide remove button next to owner's own entry
7. Wire up to ListDetailViewModel's `removeMember()` method
8. Refresh member list after successful removal
9. Add success/error snackbar feedback
10. Add widget tests for remove member flow

#### **Phase 3: Testing & Polish**
11. Add integration tests for remove member flow
12. Test edge cases: removing member viewing the list, network failures
13. Verify removed member loses access immediately
14. Manual testing with multiple members

**Technical Details**:
```dart
// Enhanced MemberListDialog
ListTile(
  title: Text(member.displayName),
  trailing: isOwner && !member.isCurrentUser
    ? IconButton(
        icon: Icon(Icons.person_remove),
        onPressed: () => _showRemoveMemberDialog(member),
      )
    : null,
)

// Usage
void _removeMember(String userId) async {
  final success = await viewModel.removeMember(userId);
  if (success) Navigator.pop(context); // Close dialog and refresh
}
```

---

### 3. Documentation Alignment (Priority 3)

**Goal**: Align PRDs and README with current behavior so they match the app.

**Tasks**:
- Update README with current features
- Update architecture documentation in prds/
- Align PRDs to current implementation
  - Profile status wording (Guest vs local-only)
  - Member list dialog content (roles vs permissions)
  - Storage error semantics (bool vs structured errors)
- Add inline documentation for complex functions
- Clean up comments in code

---

### 4. Code Cleanup & Testing (Priority 4) ⏳

**High Priority Tasks**:
- Remove unused imports and dead code
- Optimize Firebase queries for better performance
- Standardize error handling patterns across services
- Remove debug prints from production code
- Add missing unit tests for services
- Add integration tests for permission system

---

### 5. UI Polish (Priority 5) ⏳

**High Priority Tasks**:
- Improve loading states across the app
- Add better error messages with user-friendly text
- Enhance empty states with helpful illustrations
- Polish animations and transitions
- Optimize for different screen sizes and orientations

---

## Technical Architecture Reference

**Member Management Flow**:
```
User Action → ViewModel → Repository → [FirestoreService + LocalStorageService] → State Update → UI Refresh
```

**Permission Checks**:
- Leave List: `!isOwner` (members only)
- Remove Member: `isOwner && targetUser != currentUser` (owner can remove others, not themselves)

**Firestore Security Rules Required**:
```
// Allow member to remove themselves
allow update: if request.auth.uid in resource.data.members.map(m => m.userId);

// Allow owner to remove any member
allow update: if request.auth.uid == resource.data.ownerId;
```

**State Management**:
- Use ListDetailViewModel for all member operations
- Return bool for success/failure from async methods
- Update local state and trigger re-fetch from repository
- Show snackbars for user feedback

**Testing Strategy**:
- Unit tests: Repository and ViewModel methods with mocks
- Widget tests: Dialogs, buttons, permission-based visibility
- Integration tests: Complete flows with Firestore mocks
- Edge cases: Network errors, permission denied, invalid states

---

## Completed Features ✅

<details>
<summary><strong>Contact Suggestions Feature</strong> (Click to expand)</summary>

**Status**: ✅ Fully implemented, tested, and production-ready

**Achievement Summary**:
- 27+ tests across 3 test files (all passing)
- Full MVVM integration with Riverpod
- Intelligent autocomplete with contact avatars and shared list counts
- Real-time contact suggestions from shared lists
- Proper caching with stream-based updates
- Bug fixes: shared list count accuracy, contact suggestions refresh

**Implementation Details**:
- ContactSuggestion model with matching logic
- ContactSuggestionsService with stream-based caching
- ContactSuggestionsViewModel for state management
- EnhancedShareListDialog with autocomplete UI
- Comprehensive test coverage (unit, widget, integration)

</details>

---

*Focus: Member management features → Testing & polish → Production release*
