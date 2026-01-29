# Riverpod Architecture

## Overview
Baskit uses Riverpod 3.x with `Notifier` and `NotifierProvider`. Business logic lives in view models and services; UI is built with `ConsumerWidget` and `ConsumerStatefulWidget`.

## Core Layers
1. **Services**: Firebase, Hive, and platform integrations
2. **Repositories**: Data access abstraction (`ShoppingRepository`)
3. **View Models**: `Notifier` state and business logic
4. **Screens/Widgets**: UI consuming providers

## Key Providers
### Repository Provider
```dart
final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return StorageShoppingRepository.instance();
});
```

### Auth Providers
```dart
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authViewModelProvider).user;
});

final isAnonymousProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAnonymous;
});
```

### Contact Suggestions Providers
```dart
final contactSuggestionsViewModelProvider =
    NotifierProvider<ContactSuggestionsViewModel, ContactSuggestionsState>(
  ContactSuggestionsViewModel.new,
);

final contactSuggestionsProvider = Provider<List<ContactSuggestion>>((ref) {
  return ref.watch(contactSuggestionsViewModelProvider).contacts;
});
```

## Cross-Provider Patterns
### Auth-Driven Reinitialization
`ContactSuggestionsViewModel` listens for auth changes and clears cache on user switches:
```dart
ref.listen<String?>(authUserProvider.select((user) => user?.uid), (
  previous,
  next,
) {
  if (previous != next) {
    ContactSuggestionsService.clearCache();
    initializeContactsStream();
  }
});
```

## Feature View Models
Each feature has its own view model, e.g.:
- `ListsViewModel`
- `ListFormViewModel`
- `ListDetailViewModel`
- `ProfileViewModel`

They all depend on `shoppingRepositoryProvider` and `authUserProvider` where needed.

## UI Integration
### Stateless UI
```dart
class ListsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsState = ref.watch(listsViewModelProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);
    // ...
  }
}
```

### Stateful UI
```dart
class EnhancedShareListDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<EnhancedShareListDialog> createState() => _State();
}
```

## Design Notes
- Prefer immutable state objects with `copyWith`
- Use `ref.listen` for cross-view-model reactions
- Keep widget trees thin; move logic into view models
