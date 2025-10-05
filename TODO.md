# TODO

## Release Readiness Priorities

### 1. Contact Suggestions (Priority 1) 🔄

**Goal**: Add intelligent contact suggestions with autocomplete for seamless sharing.

**Implementation Tasks**:

1. **Create Contact Suggestions Service**
   ```dart
   // lib/services/contact_suggestions_service.dart
   class ContactSuggestionsService {
     static Stream<List<ContactSuggestion>> getUserContacts(String currentUserId);
     static Future<List<ContactSuggestion>> _extractContactsFromLists(List<ShoppingList> lists);
     static Future<void> refreshContactCache(String currentUserId);
   }
   ```

2. **Contact Suggestion Model**
   ```dart
   // lib/models/contact_suggestion_model.dart
   class ContactSuggestion {
     final String userId;
     final String email;
     final String displayName;
     final String? avatarUrl;
     final int sharedListsCount;
     bool matches(String query) => displayName.contains(query) || email.contains(query);
   }
   ```

3. **Enhanced Share Dialog with Autocomplete**
   - Use Flutter's `Autocomplete<ContactSuggestion>` widget
   - Real-time filtering as user types
   - Custom dropdown with avatars and contact info
   - Handle loading states and empty results
   - Fallback to manual email entry for new contacts

4. **Firebase Query Strategy**
   ```dart
   final listsQuery = FirebaseFirestore.instance
       .collection('lists')
       .where('memberIds', arrayContains: currentUserId);
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