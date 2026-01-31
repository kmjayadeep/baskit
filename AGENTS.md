# Baskit App Agent Guide

This file describes how to build, lint, test, and contribute to the Baskit app.
It is intended for agentic coding tools working in this repository.

## Scope

- App source lives in `app/` (Flutter/Dart).
- Docs and architectural context live in `README.md` and `prds/`.
- Generated artifacts live in `app/lib/**.g.dart` (do not edit manually).

## Linting and Formatting

```bash
flutter analyze
```

## Testing

### Run All Tests

```bash
flutter test
```

Run this before committing changes. Proactively suggest adding new tests or updating existing ones when necessary.

### Run a Single Test File

```bash
flutter test test/services/storage_service_test.dart
flutter test test/widgets/enhanced_share_list_dialog_test.dart
flutter test test/widgets/leave_list_dialog_test.dart
```

## Project Layout (app/)

- `lib/models/` data models and Hive adapters.
- `lib/services/` storage, Firebase, and platform services.
- `lib/repositories/` data access abstraction.
- `lib/providers/` provider definitions.
- `lib/view_models/` global view models (Notifier-based).
- `lib/screens/` feature screens and view models.
- `lib/widgets/` reusable UI components.
- `lib/utils/` routing and helpers.
- `test/` unit/widget tests.
- `integration_test/` end-to-end tests.

## Code Style Guidelines

### Dart/Flutter Defaults

- Follow `flutter_lints` (see `app/analysis_options.yaml`).
- Prefer `const` constructors and `const` widgets where possible.
- Favor immutable state objects with `copyWith` methods.
- Keep widgets small and composable; extract sub-widgets for readability.
- Use Material 3 patterns (see existing screens/widgets).

### Naming Conventions

- Files: `snake_case.dart`.
- Types/classes/enums: `PascalCase`.
- Variables/functions: `camelCase`.
- Private members: `_leadingUnderscore`.
- Providers: `somethingProvider` or `somethingViewModelProvider`.
- Use descriptive names; avoid one-letter variables.

### Imports

Order imports in this sequence:
1. `dart:`
2. `package:`
3. Relative imports (`../` or `./`)

Prefer relative imports within `app/lib/` to keep paths consistent.
Keep import lists clean; remove unused imports.

### State Management (Riverpod 3.x)

- Use `Notifier` and `NotifierProvider` (not `StateNotifier`).
- Keep side effects in ViewModels or services.
- Use `ref.listen` for cross-provider reactions (auth changes, etc.).
- Avoid storing `BuildContext` in providers.

### Error Handling

- Use `try/catch` around Firebase/storage calls.
- Return typed results or `bool` + error strings rather than throwing into UI.
- Surface user-friendly errors in ViewModels and screens.
- Use `debugPrint` for non-fatal diagnostics.

### Logging

- Prefer `debugPrint` for quick diagnostics.
- For structured logging, use `dart:developer` when needed.
- Avoid noisy logs in hot paths.

### Data Models

- Keep models immutable with required fields.
- Use explicit `toJson`/`fromJson` for Firestore/Hive data.
- Do not hand-edit `.g.dart` files.

### UI Patterns

- Use `ConsumerWidget`/`ConsumerStatefulWidget` to read providers.
- Keep business logic in ViewModels, not widgets.
- Use `SnackBar` helpers for consistent feedback.
- Handle loading/empty/error states explicitly.

### Firebase/Storage

- Respect the guest-first routing (local Hive vs Firestore).
- Use `StorageService`/repositories instead of direct Firestore calls in UI.
- Ensure migration and sync flows remain intact.

## Documentation Expectations

- Update `README.md` for high-level changes.
- Update relevant files in `prds/` for architecture or API changes.
- Keep docs aligned with code per Cursor rule.

## Useful References

- `README.md` for overview and quick commands.
- `prds/07-development.md` for environment setup and workflows.
- `prds/05-state-management.md` for provider relationships.
