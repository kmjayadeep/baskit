# Baskit Development Guide

## Quick Start

```bash
# Load development environment
source ~/projects/baskit/setup-env.sh

# Navigate to app directory
cd ~/projects/baskit/app

# Run the app on Linux desktop (primary dev target)
flutter run -d linux

# Or build Android APK
flutter build apk

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Environment Setup

All required tools are installed at:
- **Flutter**: `/home/hermes/flutter`
- **JDK 21**: `/home/hermes/dev/jdk`
- **Android SDK**: `/home/hermes/dev/android-sdk`
- **Clang++**: `/home/hermes/dev/clang/bin`
- **CMake**: `/home/hermes/dev/cmake/bin`
- **Ninja**: `/home/hermes/dev/bin`

## Current Status

| Component | Status | Notes |
|---|---|---|
| Flutter 3.41.6 | ✅ | Installed and working |
| Java 21 (Temurin) | ✅ | Required for Android builds |
| Android SDK 36 | ✅ | All licenses accepted |
| Linux Desktop Toolchain | ✅ | clang++, cmake, ninja |
| Code Analysis | ✅ | No issues found |
| Tests | ✅ | 249 tests passing |
| Dependencies | ✅ | All resolved |
| pkg-config | ⚠️ | Stub provided (works for dev) |
| Chrome/Web | ❌ | Missing system libraries (libnspr4, libnss3, libatk) |

## What Works

- ✅ `flutter analyze` - Static analysis passes
- ✅ `flutter test` - All 249 tests pass
- ✅ `flutter run -d linux` - Linux desktop app runs
- ✅ `flutter build apk` - Android APK builds
- ✅ `flutter pub get` - Dependencies resolve

## What Needs System Access (sudo required)

1. **Chrome for web development**: Missing libraries (libnspr4, libnss3, libatk-1.0, libcups, libxcb, libxkbcommon, etc.)
   ```bash
   # Install on Debian/Ubuntu:
   sudo apt install libnspr4 libnss3 libatk1.0-0 libcups2 libx11-xcb1 libxkbcommon0 libasound2 libgbm1
   ```

2. **pkg-config (real version)**: Currently using stub. Real version needed for some Flutter plugins.
   ```bash
   sudo apt install pkg-config
   ```

3. **Android Emulator**: To run app on Android emulator
   ```bash
   # After loading environment:
   flutter emulator --create
   flutter emulator --start
   ```

## Development Workflow

```bash
# 1. Setup environment
source ~/projects/baskit/setup-env.sh

# 2. Navigate to app
cd ~/projects/baskit/app

# 3. Run checks before committing
flutter analyze
flutter test

# 4. Run on Linux desktop
flutter run -d linux

# 5. Build Android APK
flutter build apk --release

# 6. Build for release (requires keystore)
# flutter build appbundle --release --dart-define=FLAVOR=production
```

## Autonomous Agent

The project includes an autonomous development agent:

```bash
cd ~/projects/baskit/automation/autonomous-agent
npm ci
npm run check
npm run build
```

## Troubleshooting

- **pkg-config errors**: The stub at `/home/hermes/dev/bin/pkg-config` should work for most cases
- **Android build fails**: Ensure ANDROID_HOME and JAVA_HOME are set correctly
- **Linux desktop build fails**: Ensure clang++, cmake, and ninja are in PATH
- **Tests fail**: Run `flutter pub get` first
