# TODO

## 📈 **Overall Progress: Phase 1 - Member Management & Permissions**

### **✅ COMPLETED PHASES:**
- **Phase 1.1**: Show Full Member List ✅
- **Phase 1.2**: Fix Firestore-Model Data Mapping ✅  
- **Phase 1.3**: Implement Permission System ✅

### **🔄 CURRENT PHASE:**
- **Phase 1.4**: Enhanced Member Management UI (Ready to implement)

### **⏳ UPCOMING:**
- **Phase 1.5**: Smart Contact Suggestions & Enhanced Share UX  
- **Phase 1.6**: Integration & Testing

### **✅ COMPLETED:**
- **Phase 2**: What's New Feature ✅

---

## Phase 1: Member Management & Permissions System

**Completed Issues**:
- ✅ Fixed: Firestore rich member data now properly mapped to models
- ✅ Added: Role-based permissions in UI with granular control
- ✅ Added: Smart contact suggestions for easier sharing


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

### **Phase 1.5: Smart Contact Suggestions & Enhanced Share UX** ⏳
**Goal**: Add intelligent contact suggestions with autocomplete for seamless sharing

**User Problem**: "I have to type the same email addresses over and over when sharing lists"

**Solution**: Firebase-powered contact suggestions with real-time autocomplete from existing shared lists

**Key Benefits**:
- ✅ Real-time contact data from Firestore (always current)
- ✅ Familiar autocomplete UX (like Gmail/Slack)
- ✅ No complex local storage or tracking needed
- ✅ Leverages existing rich member data from Phase 1.2
- ✅ Efficient single Firebase query

**Steps**:
1. **Create Contact Suggestions Service** 🔄
   ```dart
   // lib/services/contact_suggestions_service.dart
   class ContactSuggestionsService {
     // Query all lists user has access to
     static Stream<List<ContactSuggestion>> getUserContacts(String currentUserId);
     
     // Extract unique contacts from memberDetails across all lists
     static Future<List<ContactSuggestion>> _extractContactsFromLists(List<ShoppingList> lists);
     
     // Cache contacts for quick autocomplete
     static Future<void> refreshContactCache(String currentUserId);
   }
   ```

2. **Contact Suggestion Model** 🔄
   ```dart
   // lib/models/contact_suggestion_model.dart
   class ContactSuggestion {
     final String userId;
     final String email;
     final String displayName;
     final String? avatarUrl;
     final int sharedListsCount; // How many lists they share with current user
     
     // Autocomplete matching logic
     bool matches(String query) => displayName.contains(query) || email.contains(query);
   }
   ```

3. **Enhanced Share Dialog with Autocomplete** 🔄
   ```dart
   ShareListDialog with Autocomplete:
   ┌─────────────────────────────────┐
   │ Share "Grocery List"            │
   │                                 │
   │ 👤 Share with:                  │
   │ ┌─────────────────────────────┐ │
   │ │ [Search contacts...      ▼] │ │ <- Autocomplete field
   │ └─────────────────────────────┘ │
   │                                 │
   │ 📋 Suggestions (as you type):   │ <- Dropdown appears
   │ ┌─────────────────────────────┐ │
   │ │ [👤] John Doe               │ │ <- Click to select
   │ │      john@example.com       │ │
   │ │      Shared 3 lists         │ │
   │ │ [👤] Jane Smith             │ │
   │ │      jane@company.com       │ │
   │ │      Shared 1 list          │ │
   │ └─────────────────────────────┘ │
   │                                 │
   │ [Cancel]              [Share]   │
   └─────────────────────────────────┘
   ```

4. **Firebase Query Strategy** 🔄
   ```dart
   // Single efficient query to get all user's accessible lists
   final listsQuery = FirebaseFirestore.instance
       .collection('lists')
       .where('memberIds', arrayContains: currentUserId);
   
   // Extract contacts from memberDetails of each list
   // Deduplicate by userId/email
   // Sort alphabetically for consistent UX
   ```

5. **Autocomplete Implementation** 🔄
   - Use Flutter's `Autocomplete<ContactSuggestion>` widget
   - Real-time filtering as user types
   - Custom dropdown with avatars and contact info
   - Handle loading states and empty results
   - Fallback to manual email entry for new contacts

### **Phase 1.6: Integration & Testing** ⏳
**Goal**: Ensure all components work seamlessly with enhanced member management and smart contact suggestions

**Steps**:
1. **Contact Suggestions Integration Testing** 🔄
   - Test contact extraction from multiple shared lists
   - Verify deduplication of contacts across lists
   - Test autocomplete performance with many contacts
   - Verify contact data accuracy (names, emails, avatars)
   - Test filtering and search functionality

2. **Share Dialog UX Testing** 🔄
   - Test autocomplete behavior with various input patterns
   - Verify dropdown appearance and selection
   - Test fallback to manual email entry for new contacts
   - Test loading states and error handling
   - Verify contact avatars display correctly

3. **Comprehensive System Testing** 🔄
   - Test permission enforcement in all operations
   - Test member role display accuracy
   - Test ownership detection with real Firestore data
   - Test fallback to simple mode for local-only lists
   - Verify no data loss during Firestore sync
   - Test contact suggestions with various list configurations

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

**Smart Contact Suggestions System**:
- Real-time contact data from existing Firestore member data
- Efficient single query to get all user's accessible lists
- Automatic deduplication and sorting of contacts
- No additional storage needed - leverages existing rich member data
- Offline support through existing list caching mechanisms

### **Future Enhancements** 🔮
- **Member Activity Log**: Track member actions
- **Invitation Links**: Share lists via links with predefined roles
- **Bulk Member Management**: CSV import, role templates
- **Advanced Permissions**: Item-level permissions, time-based access
- **Member Notifications**: Notify on role changes, removals

**Smart Contact Suggestions Enhancements**:
- **Contact Groups**: Organize contacts by frequency/relationship (Family, Work, Friends)
- **Advanced Search**: Search through contact history with fuzzy matching
- **Contact Insights**: Show sharing patterns ("You often share grocery lists with Jane")
- **Contact Import**: Import from phone contacts or Google Contacts API
- **Favorite Contacts**: Pin most-used contacts to the top of suggestions
- **Smart Defaults**: Pre-select likely contacts based on list type/context

---

## Phase 2: What's New Feature

**Goal**: Show users new features and improvements when they update the app

**User Problem**: "I don't know what changed in the new version" / "I miss new features"

**Solution**: Modal dialog showing version highlights on first launch after update

**Steps**:
1. **Version Detection Service** 🔄
   ```dart
   // lib/services/version_service.dart
   class VersionService {
     // Check if this is a new version for the user
     static Future<bool> shouldShowWhatsNew() async;
     
     // Mark current version as seen
     static Future<void> markVersionAsSeen() async;
     
     // Get current app version using package_info_plus
     static Future<String> getCurrentVersion() async;
     
     // Compare versions using pub_semver
     static bool _isNewerVersion(String current, String lastSeen);
   }
   ```

2. **What's New Content Model** 🔄
   ```dart
   // lib/models/whats_new_model.dart
   class WhatsNewContent {
     final String version;
     final String title;
     final List<WhatsNewItem> items;
     
     // Load from local JSON assets
     static WhatsNewContent? loadForVersion(String version);
   }
   
   class WhatsNewItem {
     final String title;
     final String description;
     final IconData icon;
     final WhatsNewItemType type; // feature, improvement, bugfix
   }
   ```

3. **What's New Dialog UI** 🔄
   ```dart
   WhatsNewDialog (Modal):
   ┌─────────────────────────────────┐
   │ 🎉 What's New in Baskit v2.1    │
   │                                 │
   │ ✨ Enhanced Member Management   │
   │    See member roles and         │
   │    permissions clearly          │
   │                                 │
   │ 🔍 Smart Contact Suggestions   │
   │    Autocomplete when sharing    │
   │    lists with others           │
   │                                 │
   │ 🛡️ Improved Permissions        │
   │    Better control over list     │
   │    access and editing          │
   │                                 │
   │ [Skip]              [Got it!]   │
   └─────────────────────────────────┘
   ```

4. **Content Management** 🔄
   - Store content in `assets/whats_new/{version}.json` files
   - Load content based on current app version
   - Graceful fallback if no content exists for version

5. **App Integration** 🔄
   - Check for new version on app startup
   - Show dialog after main UI loads (non-blocking)
   - Track seen versions in SharedPreferences
   - Only show for version updates (not first install)

**Dependencies Needed**:
```yaml
dependencies:
  package_info_plus: ^4.2.0  # Get app version
  pub_semver: ^2.1.4         # Version comparison
```

**✅ COMPLETED IMPLEMENTATION**:
1. ✅ **VersionService** - Version detection, tracking, and comparison logic
2. ✅ **WhatsNewContent Models** - JSON-based content structure with rich item types
3. ✅ **WhatsNewDialog UI** - Beautiful modal dialog with icons, colors, and animations
4. ✅ **Content Management** - Local JSON assets with template for future versions
5. ✅ **App Integration** - Non-blocking startup check with proper timing
6. ✅ **Dependencies Added** - package_info_plus and pub_semver for version handling
7. ✅ **Comprehensive Tests** - Unit tests for version service and content models

**Benefits**:
- ✅ Increase feature discovery and adoption
- ✅ Keep users informed about improvements  
- ✅ Non-intrusive modal dialog approach
- ✅ Simple local JSON content management
- ✅ Version tracking with SharedPreferences
- ✅ Robust error handling and fallback mechanisms

---
*Note: This plan builds incrementally, allowing review at each phase while maintaining backward compatibility and preparing for advanced permission features.*
