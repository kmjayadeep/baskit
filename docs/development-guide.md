# Development Guide

## Overview
This guide covers local development setup, testing strategies, and deployment processes for the Baskit shopping list app.

## Prerequisites

### Required Tools
- **Flutter SDK**: Latest stable version (3.0+)
- **Dart SDK**: Included with Flutter
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **VS Code**: Recommended editor with Flutter extension
- **Firebase CLI**: For backend services management

### System Requirements
```bash
# Check Flutter installation
flutter doctor

# Expected output should show ✓ for:
# - Flutter SDK
# - Android toolchain
# - Xcode (macOS)
# - VS Code with Flutter extension
```

## Project Setup

### 1. Clone and Install Dependencies
```bash
# Clone the repository
git clone <repository-url>
cd baskit

# Install Flutter dependencies
cd app
flutter pub get

# Add Hive dependencies (if not already added)
flutter pub add hive hive_flutter
flutter pub add --dev hive_generator build_runner

# Run code generation for Hive adapters and models
flutter packages pub run build_runner build
```

### 2. Environment Configuration
Create environment-specific configuration:

```bash
# Copy environment template
cp .env.example .env

# Configure environment variables
# - Firebase configuration
# - API keys
# - Debug settings
```

### 3. Firebase Configuration
Follow the [Firebase Setup Guide](firebase-setup.md) to:
- Create Firebase project
- Add configuration files
- Enable required services
- Deploy security rules

## Local Development

### Development Workflow
```bash
# Start development server
flutter run

# Hot reload during development
# Press 'r' to hot reload
# Press 'R' to hot restart
# Press 'q' to quit

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>        # Run on specific device
```

### Development Tools

#### Flutter Inspector
```bash
# Launch Flutter Inspector
flutter run --dart-define=INSPECTOR=true

# Debug widget tree and performance
# Available in VS Code or Android Studio
```

#### Debugging
```bash
# Debug mode with detailed logging
flutter run --debug

# Profile mode for performance testing
flutter run --profile

# View logs
flutter logs
```

### Code Generation
For models and serialization:
```bash
# Generate code for @JsonSerializable models
flutter packages pub run build_runner build

# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# Clean generated files
flutter packages pub run build_runner clean
```

## Testing Strategy

### Test Structure
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   ├── screens/
│   └── widgets/
├── integration/
│   ├── user_flows/
│   └── api_tests/
└── test_utils/
    ├── mocks/
    └── fixtures/
```

### Running Tests

#### Unit Tests
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/services/storage_service_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### Widget Tests
```bash
# Run widget tests
flutter test test/widget/

# Test specific widget
flutter test test/widget/screens/lists_screen_test.dart
```

#### Integration Tests
```bash
# Run integration tests
flutter test integration_test/

# Run on device
flutter test integration_test/ -d <device-id>
```

### Test Examples

#### Unit Test Example
```dart
// test/services/storage_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;
    
    setUp(() {
      storageService = StorageService();
    });
    
    test('should create shopping list', () async {
      // Arrange
      final list = ShoppingList(name: 'Test List');
      
      // Act
      final result = await storageService.createList(list);
      
      // Assert
      expect(result, isNotNull);
      expect(result.name, equals('Test List'));
    });
  });
}
```

#### Widget Test Example
```dart
// test/widget/screens/lists_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListsScreen displays lists', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp());
    
    // Verify lists screen elements
    expect(find.text('My Lists'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

## Build and Deployment

### Build Configurations

#### Android
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release

# Split per ABI (reduces download size)
flutter build apk --release --split-per-abi
```

#### iOS
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

#### Web
```bash
# Build for web
flutter build web --release

# Build with specific base URL
flutter build web --base-href /baskit/
```

#### Desktop
```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

### Deployment Strategies

#### Firebase Hosting (Web)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Google Play Store (Android)
1. Build app bundle: `flutter build appbundle --release`
2. Sign app bundle with upload key
3. Upload to Google Play Console
4. Complete store listing and testing
5. Submit for review

#### App Store (iOS)
1. Build IPA: `flutter build ipa --release`
2. Upload via Xcode or Application Loader
3. Complete App Store Connect listing
4. Submit for review

### Environment-Specific Builds

#### Development
```bash
flutter run --dart-define=ENV=dev
```

#### Staging
```bash
flutter build apk --dart-define=ENV=staging --release
```

#### Production
```bash
flutter build apk --dart-define=ENV=prod --release
```

## Performance Optimization

### Build Optimization
```bash
# Analyze bundle size
flutter build apk --analyze-size

# Tree shake icons
flutter build apk --tree-shake-icons

# Obfuscate code (release only)
flutter build apk --obfuscate --split-debug-info=debug-info/
```

### Performance Monitoring
```dart
// Add performance monitoring
import 'package:firebase_performance/firebase_performance.dart';

// Track custom traces
final trace = FirebasePerformance.instance.newTrace('list_creation');
await trace.start();
// ... perform operation
await trace.stop();
```

## Debugging and Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build artifacts
flutter clean
flutter pub get

# Clear Dart analysis cache
dart pub cache repair

# Reset iOS build
cd ios && rm -rf Pods Podfile.lock && pod install
```

#### Performance Issues
```bash
# Run in profile mode to identify performance bottlenecks
flutter run --profile

# Use Flutter Inspector to analyze widget rebuilds
# Monitor memory usage and identify leaks
```

#### Firebase Issues
```bash
# Check Firebase configuration
flutter run --debug | grep Firebase

# Verify security rules
firebase firestore:rules get

# Test with Firebase emulator
firebase emulators:start
```

### Debugging Tools

#### Flutter DevTools
```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Or launch from IDE
# VS Code: Ctrl+Shift+P → "Flutter: Open DevTools"
```

#### Logging
```dart
// Add logging throughout the app
import 'dart:developer' as developer;

developer.log('User created list', name: 'app.lists');

// Use different log levels
developer.log('Debug info', level: 800);
developer.log('Warning', level: 900);
developer.log('Error', level: 1000);
```

## Code Quality

### Linting
```bash
# Run Flutter analyze
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Formatting
```bash
# Format all Dart files
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .
```

### Code Review Checklist
- [ ] Tests pass and coverage is adequate
- [ ] Code follows Flutter/Dart style guidelines
- [ ] No analyzer warnings or errors
- [ ] Performance impact considered
- [ ] Accessibility requirements met
- [ ] Error handling implemented
- [ ] Documentation updated

This development guide provides a comprehensive workflow for contributing to and maintaining the Baskit project effectively. 