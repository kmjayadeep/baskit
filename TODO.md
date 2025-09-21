# TODO: Refactor Lists Screen & Naming Conventions

## Overview
Simplify `app/lib/screens/lists/lists_screen.dart` (351 lines) by extracting widgets and dialogs into a subfolder structure to improve code maintainability, reusability, and testability. Also update existing files to follow Flutter naming conventions.

## 🏗️ Naming Conventions Compliance
Following Flutter/Dart best practices:

### Current Violations & Fixes Needed:
- **Models**: `shopping_list.dart` → `shopping_list_model.dart` ❌
- **Models**: `shopping_item.dart` → `shopping_item_model.dart` ❌
- **Widgets**: Will follow `*_widget.dart` pattern ✅
- **Services**: Already follow correct naming ✅
- **Screens**: Already follow `*_screen.dart` pattern ✅

### Naming Standards:
- **Folders & Files**: lowercase_with_underscores
- **Classes**: PascalCase (e.g., `WelcomeBannerWidget`)
- **Methods & Variables**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Widgets**: PascalCase with `_widget.dart` suffix
- **Models**: PascalCase with `_model.dart` suffix
- **Services**: PascalCase with `_service.dart` suffix

## Current Issues
- **Large file**: 351 lines mixing UI, state management, and widget building
- **Mixed responsibilities**: Main screen handles both business logic and UI components  
- **Hard to maintain**: Large methods make changes risky
- **Poor reusability**: UI components are tightly coupled to the main screen
- **Testing complexity**: Hard to test individual UI components in isolation
- **Naming conventions**: Model files don't follow `*_model.dart` convention

## Refactoring Plan

### 1. Create Widget Subfolder Structure
```
screens/lists/
├── lists_screen.dart (simplified main screen ~200 lines)
└── widgets/
    ├── welcome_banner_widget.dart (WelcomeBannerWidget)
    ├── list_card_widget.dart (ListCardWidget)
    ├── empty_state_widget.dart (EmptyStateWidget)
    └── lists_header_widget.dart (ListsHeaderWidget)
```

### 2. Extract Major Widgets

#### 2.1 ListCardWidget (~95 lines → separate file)
- **Source**: Extract `_buildListCard()` method 
- **Includes**: 
  - Card layout and styling
  - Progress indicator
  - Sharing status display (using `list.sharingText`, `list.sharingIcon`)
  - Navigation on tap
- **Props needed**:
  - `ShoppingList list` (contains all display logic via getters)
  - `VoidCallback onTap`
- **Note**: ✅ Sharing logic already moved to model

#### 2.2 EmptyStateWidget (~37 lines → separate file)
- **Source**: Extract `_buildEmptyState()` method
- **Features**:
  - Empty basket icon
  - Encouraging message
  - Create list button
- **Props needed**:
  - `VoidCallback onCreateList`

#### 2.3 WelcomeBannerWidget (~25 lines → separate file)
- **Source**: Extract welcome container
- **Features**:
  - Welcome message with emoji
  - App description
  - Blue themed styling
- **Props needed**: None (static content)

#### 2.4 ListsHeaderWidget (new extraction)
- **Source**: Extract header section
- **Features**:
  - "Your Lists (count)" title
  - "New List" button
- **Props needed**:
  - `int listsCount`
  - `VoidCallback onCreateList`

### 3. ✅ Utility Functions (COMPLETED)

#### 3.1 Color Utils ✅ 
- **Status**: ✅ **COMPLETED** - Logic moved to `ShoppingList.displayColor` getter
- **Approach**: Inlined color parsing directly in model getter (better encapsulation)
- **Benefits**: No separate utility file needed, model owns its display logic

### 4. Simplified Main Screen Structure

#### 4.1 Reduced Responsibilities
After refactoring, `lists_screen.dart` will focus on:
- Stream management (`_listsStream`, `_initializeListsStream`)
- Authentication state handling (`_onAuthStateChanged`)
- Refresh logic (`_refreshLists`, `_isRefreshing`)
- Widget composition using extracted components
- Navigation setup

#### 4.2 New Import Structure
```dart
// Widgets (following _widget.dart convention)
import 'widgets/welcome_banner_widget.dart';      // WelcomeBannerWidget
import 'widgets/list_card_widget.dart';           // ListCardWidget  
import 'widgets/empty_state_widget.dart';         // EmptyStateWidget
import 'widgets/lists_header_widget.dart';        // ListsHeaderWidget

// Models (already enhanced with UI helpers)
import '../../models/shopping_list.dart';         // ShoppingList with displayColor, sharingText, sharingIcon
```

#### 4.3 Simplified Build Method
```dart
// Before: ~150 lines of mixed UI code
// After: ~50 lines of clean widget composition
Widget build(BuildContext context) {
  return AuthWrapper(
    onAuthStateChanged: _onAuthStateChanged,
    child: Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshLists,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const WelcomeBannerWidget(),
              const SizedBox(height: 24),
              _buildListsContent(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    ),
  );
}
```

## Implementation Steps

### Phase 0: Naming Conventions Compliance ⚠️
- [ ] Rename `shopping_list.dart` → `shopping_list_model.dart`
- [ ] Rename `shopping_item.dart` → `shopping_item_model.dart`  
- [ ] Update all imports across the codebase
- [ ] Update generated files (`shopping_list.g.dart` → `shopping_list_model.g.dart`)
- [ ] Verify no broken imports remain

### Phase 1: Setup and Utilities ✅
- [x] Create `screens/lists/widgets/` directory ✅
- [x] ~~Create `utils/color_utils.dart`~~ → Enhanced model with `displayColor` getter ✅
- [x] Enhanced `ShoppingList` model with UI helpers (`displayColor`, `sharingText`, `sharingIcon`) ✅

### Phase 2: Extract Standalone Widgets  
- [ ] Create `welcome_banner_widget.dart` with `WelcomeBannerWidget` class (no dependencies)
- [ ] Create `empty_state_widget.dart` with `EmptyStateWidget` class (minimal dependencies)
- [ ] Create `lists_header_widget.dart` with `ListsHeaderWidget` class (simple props)

### Phase 3: Extract Complex Widgets
- [ ] Create `list_card_widget.dart` with `ListCardWidget` class
- [ ] ~~Move sharing utility methods~~ → Use model's `sharingText`/`sharingIcon` getters ✅
- [ ] Ensure proper navigation handling

### Phase 4: Refactor Main Screen
- [ ] Update `lists_screen.dart` to use extracted widgets  
- [ ] Remove old widget-building methods (`_buildListCard`, `_buildEmptyState`, etc.)
- [ ] Update imports to use new widget files (following `_widget.dart` convention)
- [ ] Test navigation and functionality

### Phase 5: Testing and Cleanup
- [ ] Test all list operations (create, view, refresh)
- [ ] Test navigation flows
- [ ] Test authentication state changes
- [ ] Test empty states and error handling
- [ ] Verify pull-to-refresh functionality
- [ ] Clean up any unused imports

## Expected Benefits

### Code Quality
- **Reduced complexity**: Main screen drops from ~400 to ~200 lines
- **Single responsibility**: Each widget has one clear purpose
- **Better separation**: UI components separated from business logic

### Maintainability
- **Easier changes**: Modify list card without touching main screen
- **Safer refactoring**: Changes isolated to specific components
- **Clear structure**: Easy to find and modify specific UI elements

### Reusability
- **Portable components**: Widgets can be used in other screens
- **Consistent styling**: Centralized component styling
- **Shared utilities**: Color utils available across the app

### Testing
- **Unit testable**: Each widget can be tested independently
- **Widget testing**: Easier to write specific widget tests
- **Isolated testing**: Changes don't affect unrelated tests

## 📁 Files to be Created (Following Naming Conventions)
1. `app/lib/screens/lists/widgets/welcome_banner_widget.dart` → `WelcomeBannerWidget`
2. `app/lib/screens/lists/widgets/list_card_widget.dart` → `ListCardWidget`
3. `app/lib/screens/lists/widgets/empty_state_widget.dart` → `EmptyStateWidget`  
4. `app/lib/screens/lists/widgets/lists_header_widget.dart` → `ListsHeaderWidget`

## 📝 Files to be Renamed (Naming Conventions)
1. `app/lib/models/shopping_list.dart` → `shopping_list_model.dart`
2. `app/lib/models/shopping_item.dart` → `shopping_item_model.dart`
3. `app/lib/models/shopping_list.g.dart` → `shopping_list_model.g.dart` (auto-generated)
4. `app/lib/models/shopping_item.g.dart` → `shopping_item_model.g.dart` (auto-generated)

## 🔧 Files to be Modified
1. `app/lib/screens/lists/lists_screen.dart` (major refactoring - extract widgets)
2. All files importing models (update import paths after renaming)
3. Generated Hive adapter files (regenerate after model renaming)

---

## 📋 Current Progress Status
- ✅ **Model Enhancement**: Added `displayColor`, `sharingText`, `sharingIcon` getters  
- ✅ **Utility Consolidation**: Eliminated duplicate color parsing logic
- ✅ **Code Reduction**: Reduced main screen from 397 → 351 lines
- ⚠️ **Naming Conventions**: Need to rename model files
- 🔄 **Widget Extraction**: Ready to proceed

**Priority**: High - This refactoring will significantly improve code maintainability
**Estimated effort**: 3-4 hours (including naming convention fixes)
**Risk level**: Medium - Model renaming requires careful import updates
