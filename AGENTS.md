# Baskit App Agent Guide

This file describes how to build, lint, test, and contribute to the Baskit app.
It is intended for agentic coding tools working in this repository.

## Scope

- App source lives in `app/` (Flutter/Dart).
- Docs and architectural context live in `README.md` and `docs/`.
- Generated artifacts live in `app/lib/**.g.dart` (do not edit manually).

## Cursor Rules (Required)

From `.cursor/rules/readme.mdc`:
- Refer to `README.md` for general app information.
- Refer to `docs/` for file structure, design decisions, and APIs.
- Keep those docs up-to-date when changing behavior or architecture.

## Quick Start

```bash
cd app
flutter pub get
flutter run
```

## Build Commands

Run all commands from `app/` unless noted otherwise.

### Android

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

### iOS (macOS only)

```bash
flutter build ios --debug
flutter build ios --release
flutter build ipa --release
```

### Web

```bash
flutter build web --release
flutter build web --base-href /baskit/
```

### Desktop

```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

## Linting and Formatting

```bash
flutter analyze

dart format .
# Check formatting in CI-style mode:
# dart format --set-exit-if-changed .

# Apply simple fixes
# dart fix --apply
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run a Single Test File

```bash
flutter test test/services/storage_service_test.dart
flutter test test/widgets/enhanced_share_list_dialog_test.dart
```

### Run a Single Test by Name

```bash
flutter test test/services/storage_service_test.dart -n "creates list"
```

### Widget Tests

```bash
flutter test test/widget/
```

### Integration Tests

```bash
flutter test integration_test/
flutter test integration_test/ -d <device-id>
```

### Coverage

```bash
flutter test --coverage
# genhtml coverage/lcov.info -o coverage/html
```

## Code Generation

Hive adapters and other generated files are produced via build_runner.

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner watch --delete-conflicting-outputs
flutter packages pub run build_runner clean
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
- Update relevant files in `docs/` for architecture or API changes.
- Keep docs aligned with code per Cursor rule.

## Useful References

- `README.md` for overview and quick commands.
- `docs/development-guide.md` for environment setup and workflows.
- `docs/riverpod-architecture.md` for provider relationships.
