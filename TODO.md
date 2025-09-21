# TODO: Refactor Lists Screen & Architecture Compliance

## Overview
Refactor `app/lib/screens/lists/lists_screen.dart` (351 lines) to follow Flutter's recommended MVVM architecture pattern, extract widgets into subfolder structure, and ensure naming convention compliance. This will improve code maintainability, reusability, and testability.

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
- **ViewModels**: PascalCase with `_view_model.dart` suffix
- **Repositories**: PascalCase with `_repository.dart` suffix

## 🏗️ MVVM Architecture Compliance
Following [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/guide):

### Current Architecture Issues ❌

#### **1. Views contain Business Logic** 
- **Problem**: StatefulWidgets (`ListsScreen`, `ListDetailScreen`) contain:
  - Data fetching (`StorageService.instance.watchLists()`)
  - State management (`_isRefreshing`, `_isLoading`, `_isAddingItem`)
  - Business operations (`_addItem`, `_refreshLists`, `_createList`)
  - Error handling and snackbar logic
- **Should be**: Views only render UI, no business logic

#### **2. Missing ViewModel Layer**
- **Problem**: No ViewModel classes exist
- **Should be**: ViewModels handle:
  - Data retrieval/transformation from repositories  
  - State management for views
  - Commands (callbacks) for view actions
  - Most business logic

#### **3. Models contain UI Logic** ❌
- **Problem**: `ShoppingList` model has UI helpers (`displayColor`, `sharingText`, `sharingIcon`)
- **Should be**: Domain models only contain data, UI logic in ViewModels

#### **4. Service/Repository Confusion** ❌  
- **Problem**: `StorageService` acts like Repository (business logic, caching, error handling) but named as Service
- **Should be**: 
  - Services: Wrap API endpoints, no state, async responses
  - Repositories: Business logic, caching, error handling, domain models

#### **5. Direct Service Usage in Views** ❌
- **Problem**: Views directly call `StorageService.instance`
- **Should be**: Views → ViewModels → Repositories → Services

### Target MVVM Architecture ✅

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Views     │───▶│ ViewModels   │───▶│Repositories │
│ (Widgets)   │    │ (Business    │    │ (Data       │
│ UI Logic    │    │  Logic)      │    │  Sources)   │  
│ Only        │    │              │    │             │
└─────────────┘    └──────────────┘    └─────────────┘
                            │                    │
                            ▼                    ▼
                   ┌──────────────┐    ┌─────────────┐
                   │ Domain       │    │  Services   │
                   │ Models       │    │ (API calls) │
                   │ (Data only)  │    │  No State   │
                   └──────────────┘    └─────────────┘
```

## Current Issues
- **MVVM Violations**: Views contain business logic, missing ViewModel layer
- **Large file**: 351 lines mixing UI, state management, and widget building
- **Architecture confusion**: Service/Repository responsibilities mixed
- **Mixed responsibilities**: Screens handle both business logic and UI
- **Hard to maintain**: Large methods make changes risky
- **Poor testability**: Business logic coupled to UI widgets
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

#### 4.2 New Import Structure (MVVM Compliant)
```dart
// ViewModels (business logic)
import 'view_models/lists_view_model.dart';       // ListsViewModel

// Widgets (following _widget.dart convention)  
import 'widgets/welcome_banner_widget.dart';      // WelcomeBannerWidget
import 'widgets/list_card_widget.dart';           // ListCardWidget
import 'widgets/empty_state_widget.dart';         // EmptyStateWidget
import 'widgets/lists_header_widget.dart';        // ListsHeaderWidget

// Models (clean domain models, no UI logic)
import '../../models/shopping_list_model.dart';   // ShoppingList (data only)
```

#### 4.3 MVVM Compliant Build Method
```dart
// Before: ~150 lines of mixed UI + business logic  
// After: ~50 lines of pure UI widget composition
Widget build(BuildContext context) {
  return Consumer<ListsViewModel>(  // Using Provider/Riverpod
    builder: (context, viewModel, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          actions: [AuthStatusIndicator(), ProfilePictureWidget()],
        ),
        body: RefreshIndicator(
          onRefresh: viewModel.refreshLists,  // ViewModel command
          child: Column(
            children: [
              const WelcomeBannerWidget(),
              const SizedBox(height: 24),
              // Lists content uses ViewModel state
              viewModel.isLoading 
                ? const CircularProgressIndicator()
                : viewModel.lists.isEmpty
                  ? EmptyStateWidget(onCreateList: viewModel.navigateToCreateList)
                  : ListView.builder(
                      itemCount: viewModel.lists.length,
                      itemBuilder: (context, index) => ListCardWidget(
                        list: viewModel.lists[index],
                        onTap: () => viewModel.navigateToList(viewModel.lists[index].id),
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: viewModel.navigateToCreateList,  // ViewModel command
          child: const Icon(Icons.add),
        ),
      );
    },
  );
}
```

## Implementation Steps

### Phase 0: Architecture & Naming Compliance ⚠️

#### MVVM Architecture Implementation
- [ ] Create ViewModel classes for each screen:
  - [ ] `lists_view_model.dart` → `ListsViewModel` class
  - [ ] `list_detail_view_model.dart` → `ListDetailViewModel` class  
  - [ ] `create_list_view_model.dart` → `CreateListViewModel` class
- [ ] Move UI helpers from models to ViewModels:
  - [ ] Move `displayColor`, `sharingText`, `sharingIcon` from `ShoppingList` to ViewModels
  - [ ] Clean up domain models to contain only data
- [ ] Restructure Service/Repository layer:
  - [ ] Rename `StorageService` → `ShoppingRepository` (it's acting as repository)
  - [ ] Keep actual services as services (`FirestoreService`, `LocalStorageService`)
- [ ] Refactor Views to use ViewModels:
  - [ ] Remove business logic from StatefulWidgets
  - [ ] Views only handle UI rendering and call ViewModel commands
  - [ ] Use proper state management (Provider/Riverpod/Bloc) instead of StatefulWidget

#### Naming Conventions Compliance  
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

## 📁 Files to be Created (MVVM + Naming Conventions)

### ViewModels (NEW - Core Architecture)
1. `app/lib/screens/lists/view_models/lists_view_model.dart` → `ListsViewModel`
2. `app/lib/screens/list_detail/view_models/list_detail_view_model.dart` → `ListDetailViewModel`  
3. `app/lib/screens/lists/view_models/create_list_view_model.dart` → `CreateListViewModel`

### Repositories (Restructured)
4. `app/lib/repositories/shopping_repository.dart` → `ShoppingRepository` (rename from StorageService)

### Widgets (Following Conventions)
5. `app/lib/screens/lists/widgets/welcome_banner_widget.dart` → `WelcomeBannerWidget`
6. `app/lib/screens/lists/widgets/list_card_widget.dart` → `ListCardWidget`
7. `app/lib/screens/lists/widgets/empty_state_widget.dart` → `EmptyStateWidget`  
8. `app/lib/screens/lists/widgets/lists_header_widget.dart` → `ListsHeaderWidget`

## 📝 Files to be Renamed (Naming Conventions)
1. `app/lib/models/shopping_list.dart` → `shopping_list_model.dart`
2. `app/lib/models/shopping_item.dart` → `shopping_item_model.dart`
3. `app/lib/models/shopping_list.g.dart` → `shopping_list_model.g.dart` (auto-generated)
4. `app/lib/models/shopping_item.g.dart` → `shopping_item_model.g.dart` (auto-generated)

## 🔧 Files to be Modified (MVVM Architecture)

### Major Refactoring (Remove Business Logic from Views)
1. `app/lib/screens/lists/lists_screen.dart` → Convert to pure View, use ListsViewModel
2. `app/lib/screens/list_detail/list_detail_screen.dart` → Convert to pure View, use ListDetailViewModel  
3. `app/lib/screens/lists/create_list_screen.dart` → Convert to pure View, use CreateListViewModel

### Service Layer Restructuring
4. `app/lib/services/storage_service.dart` → Rename to `shopping_repository.dart`, move to repositories/
5. All files using `StorageService.instance` → Update to use `ShoppingRepository`

### Model Cleanup (Remove UI Logic)
6. `app/lib/models/shopping_list.dart` → Remove `displayColor`, `sharingText`, `sharingIcon` (move to ViewModels)
7. All files importing models → Update import paths after renaming

### State Management Integration
8. Add state management provider (Provider/Riverpod/Bloc) configuration
9. Update main.dart to configure ViewModels and dependency injection

---

## 📋 Current Progress Status
- ✅ **Model Enhancement**: Added `displayColor`, `sharingText`, `sharingIcon` getters (⚠️ NEEDS REFACTORING: Move to ViewModels)
- ✅ **Utility Consolidation**: Eliminated duplicate color parsing logic
- ✅ **Code Reduction**: Reduced main screen from 397 → 351 lines  
- ❌ **MVVM Architecture**: Major violations - Views contain business logic, missing ViewModels
- ⚠️ **Naming Conventions**: Need to rename model files and add ViewModels
- 🔄 **Widget Extraction**: Ready to proceed (but should be done after MVVM refactor)

## 🎯 Recommended Implementation Order

### Phase 0A: MVVM Architecture (CRITICAL - Do First) 🚨
**Why first**: Widget extraction will be cleaner after proper architecture
1. Create ViewModel classes with proper state management  
2. Move business logic from Views to ViewModels
3. Move UI helpers from Models to ViewModels
4. Restructure Service → Repository layer
5. Convert Views to pure UI widgets

### Phase 0B: Naming Conventions  
6. Rename model files and update imports
7. Apply consistent naming across codebase

### Phase 1-5: Widget Extraction & Testing
8. Extract widgets (now much simpler with clean ViewModels)
9. Testing and cleanup

**Priority**: CRITICAL - Architecture violations must be fixed before feature development
**Estimated effort**: 6-8 hours (MVVM refactor is significant but essential)
**Risk level**: High - Major architectural changes, but necessary for maintainability

**Reference**: [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide)
