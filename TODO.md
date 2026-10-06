# TODO

> Last audited against `main`: 2026-10-06. Every ✅ below was verified in source, not just this file.

## Tech debts

1. ~~Rename `memberDetails` to `members` in list model to align with firestore data~~ ✅ DONE
2. ~~Remove ListMember.fromLegacyString, Listmember.displayString~~ ✅ DONE
3. ~~listmodel.sharedMembers should check ownerId instead of role, also remove legacy part~~ ✅ DONE
4. ~~listmodel.sharedMemberDisplayNames should use sharedMembers method internally~~ ✅ DONE
5. ~~listmodel.hasRichMemberData should be removed~~ ✅ DONE
6. ~~allmembers should be fixed to not use legacy logic~~ ✅ DONE
7. ~~allMemberDisplayNames. Do we need all of these methods? Can we simplify?~~ ✅ DONE

## Active Priorities

### 1. Have at Home Feature (Priority 1) 🆕

**Plan**: `plans/001-have-at-home-page.md`

- ~~Phase 1 — Data model: `ItemType` enum, `ShoppingItem.listItemType`, Firestore mappers, Hive adapter~~ ✅ DONE
- Phase 2 — ViewModel: `addItemToHaveAtHome`, `finishHaveAtHomeItem`, `markBackToHaveAtHome` + guards on `toggleItemCompletion` / `clearCompletedItems` + tests
- Phase 3 — UI: TabBar on `ListDetailScreen`, `HaveAtHomeItemCard` with "Finished" button, collapsible `RunOutSection` with "Move back" / Delete + tests
- Phase 4 — Polish: haptics, snackbar messages, E2E / integration tests, design review

---

### 2. Leave List Feature (Priority 2) ✅ (code complete)

**Goal**: Allow members to leave lists that have been shared with them.

**Status**: Phases 1–4 code-complete and merged (repository, ViewModel, dialog, permission checks, snackbars, unit + widget + integration tests). Only manual testing across scenarios is pending.

---

### 3. Remove Member Feature (Priority 3) ✅ (code complete)

**Goal**: Allow list owners to remove members from their lists.

**Status**: Merged.

- Backend `removeMember(listId, userId)` shared with Leave List ✅
- `RemoveMemberConfirmationDialog` + remove button in `MemberListDialog` (owner-only, hidden on owner's own entry) ✅
- Wired to `ListDetailViewModel.removeMember()`; member list refreshes after removal ✅
- Integration test: `app/test/integration/remove_member_flow_test.dart` (owner removes member; owner cannot remove self) ✅

Remaining: manual testing with multiple members.

---

### 4. Repository/Storage Correctness Follow-ups (From Code Review) ✅ DONE

All six items verified fixed in `main` (2026-10-06):

1. ~~Migration safety in `MigrationService.ensureComplete()`~~ ✅ — returns false on partial failure, keeps local data, does not clear, retries with stable list IDs (tested)
2. ~~False-success in Firestore list update/delete~~ ✅ — `FirestoreShoppingRepository.updateList` / `deleteList` return the actual Firestore results
3. ~~`ListDetailViewModel` stream lifecycle~~ ✅ — subscription stored, cancelled on dispose, `disposeListStream` called, no duplicate listeners
4. ~~`sharedMemberCount` negative clamp~~ ✅ — `count < 0 ? 0 : count`
5. ~~Share error mapping~~ ✅ — `UserNotFoundException` / `UserAlreadyMemberException` + string fallbacks preserved through `FirestoreShoppingRepository._mapShareError`
6. ~~Create-list success snackbar name regression~~ ✅ — list name captured from the controller before navigation in `ListFormScreen`

---

### 5. Documentation Alignment (Priority 4)

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

### 6. Code Cleanup & Testing (Priority 5) ⏳

**High Priority Tasks**:
- Remove unused imports and dead code
- Optimize Firebase queries for better performance
- Standardize error handling patterns across services
- Remove debug prints from production code
- Add missing unit tests for services
- Add integration tests for permission system

---

### 7. UI Polish (Priority 6) ⏳

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
- Return `ActionResult` from async ViewModel methods
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
<summary><strong>Leave List + Remove Member</strong> (Click to expand)</summary>

Full member self-management: members can leave shared lists; owners can remove members. MVVM + Riverpod, shared `removeMember(listId, userId)` repository path through local and cloud repositories, permission-gated UI, confirmation dialogs, snackbars, and integration tests.
</details>

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

*Focus: Have at Home → Documentation → Cleanup & polish → Production release*
