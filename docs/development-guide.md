# Development Guide

## Overview
This guide covers local setup, code generation, testing, and build workflows for the Baskit Flutter app. Run all Flutter commands from `app/` unless stated otherwise.

## Prerequisites
### Required Tools
- **Flutter SDK**: Latest stable (3.16+)
- **Dart SDK**: 3.7.2+ (bundled with Flutter)
- **Android Studio** or **Xcode** for mobile builds
- **VS Code** (recommended)
- **Firebase CLI** (optional, for rules/hosting)
- **Node.js** (for Firebase CLI)

### Verify Flutter
```bash
flutter doctor
```

## Project Setup
```bash
git clone <repository-url>
cd baskit/app
flutter pub get
```

### Firebase Configuration
Firebase is optional. If you want cloud features, follow `docs/firebase-setup.md` to configure:
- `app/lib/firebase_options.dart`
- Platform config files (Android/iOS/web)

## Code Generation
Hive adapters and other generated files are produced via build_runner:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

## Testing
### Test Layout
```
test/
├── integration/
│   ├── contact_suggestions_integration_test.dart
│   └── local_first_flow_test.dart
├── models/
├── screens/
│   └── profile/
│       └── view_models/
├── services/
├── widgets/
└── widget_test.dart
```

### Run Tests
```bash
flutter test
flutter test test/services/storage_service_test.dart
flutter test test/widgets/enhanced_share_list_dialog_test.dart
```

### Integration Tests
```bash
flutter test test/integration/
flutter test test/integration/ -d <device-id>
```

## Linting and Formatting
```bash
flutter analyze
dart format .
```

## Build Commands
### Android
```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
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

## Debugging
```bash
flutter run --debug
flutter run --profile
flutter logs
```

### Flutter DevTools
```bash
dart pub global activate devtools
dart pub global run devtools
```

## Troubleshooting
```bash
flutter clean
flutter pub get
```

## Code Review Checklist
- Tests pass
- `flutter analyze` clean
- No unintended UI regressions
- Docs updated for user-facing changes
