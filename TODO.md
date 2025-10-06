# TODO

## Release Readiness Priorities

### 1. Contact Suggestions (Priority 1) 🔄

**Goal**: Add intelligent contact suggestions with autocomplete for seamless sharing.

**Implementation Plan** (Small, testable steps):

#### **Phase 1A: Models & Services Foundation**
1. **Step 1a**: Create ContactSuggestion model with basic fields ✅ *Completed*
2. **Step 1b**: Add unit tests for ContactSuggestion model ✅ *Completed* (6 essential tests)
3. **Step 2a**: Create ContactSuggestionsService class structure ✅ *Completed*
4. **Step 2b**: Add unit tests for service structure ✅ *Completed* (3 tests)
5. **Step 3a**: Implement _extractContactsFromLists method ✅ *Completed*
6. **Step 3b**: Add unit tests for contact extraction ✅ *Completed* (8 tests - all core logic)

#### **Phase 1B: Data Processing & MVVM Integration**
7. **Step 4a**: Add contact deduplication logic ✅ *Completed* (built into extraction)
8. **Step 4b**: Add unit tests for deduplication ✅ *Completed* (covered by extraction tests)
9. **Step 5a**: Implement getUserContacts method to fetch lists and use caching ✅ *Completed*
10. **Step 5b**: Add tests for getUserContacts with caching behavior ✅ *Completed* (covered by simplified tests)
11. **Step 5c**: Create ContactSuggestionsViewModel for proper MVVM integration ✅ *Completed*

#### **Phase 1C: UI Integration**
12. **Step 6a**: Create enhanced ShareListDialog with autocomplete structure
13. **Step 6b**: Add widget tests for enhanced dialog
14. **Step 7a**: Integrate ViewModel with dialog autocomplete
15. **Step 7b**: Add integration tests for suggestions
16. **Step 8a**: Add loading states and error handling
17. **Step 8b**: Add tests for loading/error scenarios

**Current Status**: ✅ **11 out of 17 steps complete** - Service + ViewModel fully integrated!

**Next Priority**: Create enhanced ShareListDialog with autocomplete (Step 6a) using the ViewModel pattern.

**🎯 Key Milestone Achieved**: Proper MVVM integration complete! The service now follows the established architecture patterns:
- ✅ Static service for business logic (ContactSuggestionsService)
- ✅ StateNotifier ViewModel for UI state management (ContactSuggestionsViewModel) 
- ✅ Riverpod providers for dependency injection
- ✅ Automatic auth state integration and cache management
- ✅ Reactive UI updates and proper lifecycle management

**Technical Specifications**:
```dart
// lib/models/contact_suggestion_model.dart
class ContactSuggestion {
  final String userId;
  final String email;
  final String displayName; 
  final String? avatarUrl;
  final int sharedListsCount;
  bool matches(String query) => /* fuzzy matching logic */;
}

// lib/services/contact_suggestions_service.dart  
class ContactSuggestionsService {
  static Stream<List<ContactSuggestion>> getUserContacts(String currentUserId);
  static Future<List<ContactSuggestion>> extractContactsFromLists(List<ShoppingList> lists, String currentUserId);
  static Future<void> refreshContactCache(String currentUserId);
}

// lib/view_models/contact_suggestions_view_model.dart
class ContactSuggestionsState {
  final List<ContactSuggestion> contacts;
  final bool isLoading;
  final String? error;
}

class ContactSuggestionsViewModel extends StateNotifier<ContactSuggestionsState> {
  // MVVM integration with Riverpod providers
}

// Usage in UI:
final contacts = ref.watch(contactSuggestionsProvider);
final isLoading = ref.watch(contactSuggestionsLoadingProvider);
```

### 2. Tests & Code Cleanup ⏳

**Testing Tasks**:
- Add tests for contact suggestions service
- Add tests for enhanced share dialog
- Integration tests for permission system
- Test contact extraction from shared lists
- Test autocomplete performance and accuracy

**Code Cleanup Tasks**:
- Remove unused imports and dead code
- Optimize Firebase queries
- Clean up model constructors and serialization
- Standardize error handling patterns
- Refactor large widget files

### 3. UI Improvements ⏳

**Implementation Tasks**:
- Improve loading states across the app
- Add better error messages with user-friendly text
- Enhance empty states with helpful illustrations
- Improve color scheme consistency
- Polish animations and transitions
- Optimize for different screen sizes

### 4. Documentation & Repo Cleanup ⏳

**Documentation Tasks**:
- Update README with current features and setup
- Update API documentation in docs/
- Clean up comments in code
- Add inline documentation for complex functions
- Update architecture documentation

**Repository Cleanup Tasks**:
- Remove unused assets and files
- Clean up build configurations
- Update dependencies to latest versions
- Organize import statements
- Remove debug prints and console logs

### 5. Enhanced Member Management UI ⏳

**Implementation Tasks**:

1. **Enhanced Member List Dialog**
   - Show member roles with icons (👑 owner, 👤 member)
   - Add role change functionality (owner only)
   - Add remove member functionality (owner only)
   - Show permission indicators (read/write/delete/share)

2. **Member Management Actions**
   - Add "Change Role" dropdown for owners
   - Add "Remove Member" action with confirmation
   - Add "Transfer Ownership" functionality
   - Show member activity indicators

3. **Permission-Aware UI**
   - Hide management actions for non-owners
   - Show permission tooltips
   - Different UI for different permission levels

---

## Technical Implementation Notes

**Contact Suggestions Architecture**:
- Query all lists user has access to
- Extract unique contacts from memberDetails across all lists
- Cache contacts for quick autocomplete
- Deduplicate by userId/email
- Sort alphabetically for consistent UX

**Testing Strategy**:
- Unit tests for all services
- Widget tests for complex dialogs
- Integration tests for Firebase operations
- Performance tests for large contact lists
- Edge case handling tests

**UI Optimization**:
- Progressive enhancement approach
- Graceful error handling
- Responsive design patterns
- Accessibility considerations
- Performance optimizations

---

*Focus: Ship-ready implementation with robust testing and clean codebase.*