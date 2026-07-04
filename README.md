<div align="center">
  <img src="assets/icon.png" alt="Baskit App Icon" width="120" height="120">
  
  # Baskit 🛒
  
  A collaborative real-time shopping list app that allows users to create, share, and manage shopping lists together.
  
  <img src="assets/feature.jpeg" alt="Baskit App Features" width="600">
</div>

## 🚀 Quick Start

### Prerequisites
- Flutter SDK `3.41.6` (aligned with CI)
- Firebase project (for backend services)
- Android Studio / Xcode for mobile development

### Toolchain Version
- CI is pinned to Flutter `3.41.6` (`.github/workflows/build-apk.yml`)
- Local development should use Flutter `3.41.6` to avoid analyzer/test drift
- Repo pin file: `.tool-versions` (`flutter 3.41.6`) for `asdf`/`mise` users
- Verify your active SDK: `flutter --version`

### Installation
```bash
# Clone and setup
git clone <repository-url>
cd baskit/app
flutter pub get

# Configure Firebase (see setup guide)
# Add google-services.json (Android)
# Add GoogleService-Info.plist (iOS)

# Run the app
flutter run
```

## 📱 Features

### Guest-First Experience
- **Zero Sign-Up Friction**: Start using the app immediately, no account required
- **Full Offline Functionality**: All features available without internet
- **Local-First for Guests**: Lightning-fast Hive storage on your device
- **Privacy by Default**: Guest data stays on your device

### Collaboration & Sync
- **Optional Cloud Upgrade**: Sign in with Google when you need sync or sharing
- **Automatic Data Migration**: Seamless transition from guest to authenticated user
- **Real-time Collaboration**: Share lists and see updates instantly
- **Cross-Device Sync**: Access your lists from anywhere (authenticated users)
- **Member Management**: Owners can remove members, and non-owner members can leave shared lists

### Technical
- **Cross-platform**: iOS, Android, Web, and Desktop
- **Modern UI**: Material Design 3 with dark/light themes
- **Smart Storage**: Hive for guests, Firebase for authenticated users
- **Granular Permissions**: Fine-grained control over list sharing

## 🏗️ Guest-First Architecture

### Core Design Principles

**Zero-Friction Onboarding**: Users can start using the app immediately without creating an account. This "guest-first" approach removes all barriers to entry while providing a seamless upgrade path when users need cloud features.

**Progressive Enhancement**: 
1. **Guest Mode (Default)**: No authentication required, all data stored locally in Hive
2. **Sign In When Needed**: Users authenticate with Google when they want sharing or sync
3. **Automatic Migration**: Local data seamlessly transfers to Firebase on sign-in
4. **No Data Loss**: Complete preservation of all lists and items during upgrade

**Smart Storage Routing**:
- **Guest Mode → Hive**: No authentication, fast local binary storage, instant operations, complete offline support
- **Authenticated Mode → Firebase**: Google OAuth, real-time sync, cross-device access, collaboration features
- **Transparent Switching**: `StorageService` automatically routes based on authentication state

### Tech Stack
- **Frontend**: Flutter 3.41.6 (Dart 3.11.4)
- **State Management**: Riverpod 3.x with modern Notifier API
- **Local Storage**: Hive 2.x for binary storage with type adapters
- **Backend**: Firebase (Auth, Firestore)
- **Authentication**: None for guests, Google Sign-In when needed
- **Navigation**: GoRouter 16.x

### Storage Architecture
- **Guest Mode**: All data stored locally in Hive (fast, offline-first, no authentication)
- **Authenticated Mode**: Data stored in Firestore with offline persistence (Google Sign-In required)
- **Account Conversion**: Automatic migration from local to cloud on sign-in
- **Sharing**: Real-time collaborative lists via Firestore (authenticated users only)

## 📚 PRDs

### Product Requirements
- **[00 PRD Index](prds/00-index.md)** - Required reading order
- **[01 Overview](prds/01-overview.md)** - Product scope and core flows
- **[02 Authentication](prds/02-authentication.md)** - Auth modes and requirements
- **[03 Storage & Sync](prds/03-storage-and-sync.md)** - Local/Cloud routing and migration
- **[04 Firestore Data Model](prds/04-firestore-data-model.md)** - Schema and indexes
- **[05 State Management](prds/05-state-management.md)** - Riverpod requirements
- **[06 UI & Assets](prds/06-ui-and-assets.md)** - UI expectations and assets
- **[07 Development & Ops](prds/07-development.md)** - Build, test, and setup needs
- **[Play Release Automation](docs/play-release-automation.md)** - Signed Play build, archive, and upload workflow with a manual production rollout gate

## 🚀 Current Status

### ✅ Completed
- Complete Flutter app with Firebase backend
- Local-only fallback when Firebase is unavailable, with anonymous auth + optional Google sign-in when enabled
- Real-time collaborative shopping lists with member management
- Dual-layer storage (Hive for local, Firestore for cloud)
- Automatic data migration on account conversion
- Contact suggestions for easy list sharing
- Granular permissions system (read, write, delete, share)
- Material Design 3 UI with dark/light themes
- Riverpod 3.x state management with centralized auth
- Cross-platform support (iOS, Android, Web, Desktop)

### 🔄 Future Enhancements
- Push notifications for real-time collaboration updates
- Advanced list templates and categories
- Shopping history and analytics
- Barcode scanning for quick item addition
- Recipe integration and meal planning
- Offline-first optimizations with smarter caching

## 🛠️ Development

### Quick Commands
```bash
# Development
flutter run
flutter test
flutter analyze

# Build
flutter build apk --release      # Android
flutter build ios --release      # iOS  
flutter build web --release      # Web
```

### Project Structure
```
app/
├── lib/
│   ├── models/                # Data models with Hive type adapters
│   │   ├── shopping_list_model.dart
│   │   ├── shopping_item_model.dart
│   │   ├── list_member_model.dart
│   │   └── *.g.dart           # Generated Hive adapters
│   ├── services/              # Core services
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── firestore_layer.dart
│   │   ├── local_storage_service.dart
│   │   ├── storage_service.dart
│   │   └── contact_suggestions_service.dart
│   ├── repositories/          # Repository pattern for data access
│   │   ├── shopping_repository.dart
│   │   └── storage_shopping_repository.dart
│   ├── providers/             # Riverpod provider definitions
│   ├── view_models/           # Riverpod ViewModels (Notifier classes)
│   ├── screens/               # UI screens with feature-specific ViewModels
│   │   ├── lists/
│   │   ├── list_detail/
│   │   └── profile/
│   ├── widgets/               # Reusable UI components
│   └── utils/                 # Routing and utilities
├── test/                      # Unit, widget, and integration tests
└── integration_test/          # End-to-end tests
```

## 🔐 Security & Privacy

- **Firebase Security Rules**: Server-side data access control
- **Anonymous Privacy**: No personal data collection for guest users
- **Secure Authentication**: Google OAuth and Firebase Auth
- **Data Isolation**: Users can only access their own data and shared lists

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for better shopping experiences**

> 📖 **Need help?** Check the [prds/](prds/) folder for product requirements.
