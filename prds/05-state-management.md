# Baskit PRD - State Management

## Framework
- Riverpod 3.x using `Notifier` and `NotifierProvider`
- No `StateNotifier` usage

## Responsibilities
- ViewModels own business logic and state
- Services handle side effects and external I/O
- UI reads providers and renders states (loading/empty/error)

## Required Providers
- `shoppingRepositoryProvider`: injects `StorageShoppingRepository`
- `authViewModelProvider`: source of auth state
- `authUserProvider`, `isAnonymousProvider`, `isAuthenticatedProvider`
- Feature view models: lists, list form, list detail, profile
- Contact suggestions view model with derived providers

## Cross-Provider Behavior
- Contact suggestions must refresh when auth user changes
- ViewModels must not store `BuildContext`

## State Requirements
- States are immutable and use `copyWith`
- Operations return boolean success and optional error messages
