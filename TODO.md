# TODO: Complete MVVM Architecture Implementation

## ✅ Completed Work
- ✅ **Widget Extraction**: Clean component library with 4 reusable widgets
- ✅ **Naming Conventions**: All files follow `*_model.dart` pattern  
- ✅ **Code Quality**: 45% complexity reduction (397→194 lines), all tests passing

## 🚧 MVVM Architecture: Complete Application Refactor

### 🎯 **Scope**: All Screens + Repository Pattern
**Goal**: Implement consistent MVVM architecture across the entire application

### Phase 1: Foundation Setup ✅
**Goal**: Add state management infrastructure

- [x] Add `flutter_riverpod` to `pubspec.yaml`
- [x] Wrap `MaterialApp` with `ProviderScope` in `main.dart`  
- [x] Create `lib/view_models/` directory
- **Test**: App loads, all 46 tests pass ✅

### Phase 2: Create ListsViewModel ✅
**Goal**: Extract business logic from ListsScreen

- [x] Create `lists_view_model.dart` with state (`lists`, `isLoading`, `error`)
- [x] Move stream subscription logic to ViewModel
- [x] Add business logic methods (`refreshLists()`, `initializeListsStream()`)
- **Test**: ViewModel compiles, existing screen unchanged ✅

### Phase 3: Integrate ViewModel ✅
**Goal**: Connect ViewModel to UI

- [x] Add ViewModel provider to `lists_screen.dart`
- [x] Replace `StreamBuilder` with `Consumer<ListsViewModel>`
- [x] Convert `StatefulWidget` to `StatelessWidget`
- **Test**: Identical UI behavior, cleaner code ✅

### Phase 4: Repository Pattern (Global)
**Goal**: Implement repository pattern for all data operations

- [ ] Create `lib/repositories/shopping_repository.dart` interface
- [ ] Create `lib/repositories/storage_shopping_repository.dart` implementation  
- [ ] Update ListsViewModel to use Repository instead of StorageService
- [ ] Create repository provider in Riverpod
- **Test**: Same functionality, better architecture

### Phase 5: List Detail Screen MVVM
**Goal**: Implement MVVM for list detail screen

- [ ] Create `lib/screens/list_detail/view_models/list_detail_view_model.dart`
- [ ] Extract business logic (item operations, real-time updates)
- [ ] Create `ListDetailState` class (list, items, isLoading, error)
- [ ] Convert ListDetailScreen to ConsumerWidget
- [ ] Replace direct service calls with ViewModel
- **Test**: Individual list management works identically

### Phase 6: Create List Screen MVVM  
**Goal**: Implement MVVM for list creation

- [ ] Create `lib/screens/lists/view_models/create_list_view_model.dart`
- [ ] Extract form state management and validation logic
- [ ] Create `CreateListState` class (formData, isValid, isSubmitting, error)
- [ ] Convert CreateListScreen to ConsumerWidget
- [ ] Add form validation and submission methods
- **Test**: List creation flow works identically

### Phase 7: Profile Screen MVVM
**Goal**: Implement MVVM for user profile

- [ ] Create `lib/screens/profile/view_models/profile_view_model.dart`  
- [ ] Extract user authentication and profile logic
- [ ] Create `ProfileState` class (user, authStatus, isLoading, error)
- [ ] Convert ProfileScreen to ConsumerWidget
- [ ] Move auth operations to ViewModel
- **Test**: Profile management works identically

### Phase 8: Model Cleanup (Final)  
**Goal**: Pure domain models across all screens

- [ ] Move UI helpers from ShoppingList model to ViewModels
- [ ] Move form helpers from models to ViewModels  
- [ ] Update all widgets to use ViewModel helpers instead of model methods
- [ ] Ensure models only contain business data (no UI logic)
- **Test**: Clean separation of concerns, identical functionality

## 🎯 Validation
After each phase:
- `flutter test` (all 46 tests pass)
- `flutter analyze` (zero errors)
- Manual testing (app works identically)

## 📊 Current Status
```
✅ Phase 1: Foundation Setup (Complete)
✅ Phase 2: Create ListsViewModel (Complete)  
✅ Phase 3: Integrate ViewModel (Complete)
🚧 Phase 4: Repository Pattern (Pending)
🚧 Phase 5: List Detail Screen MVVM (Pending)  
🚧 Phase 6: Create List Screen MVVM (Pending)
🚧 Phase 7: Profile Screen MVVM (Pending)
🚧 Phase 8: Model Cleanup (Pending)
```

**Estimated time**: 2-3 hours total, 30-45 minutes per phase
**Risk**: Low (incremental, non-breaking changes)