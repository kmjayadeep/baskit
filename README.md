<div align="center">
  <img src="assets/icon.png" alt="Baskit App Icon" width="120" height="120">
  
  # Baskit 🛒
  
  A collaborative real-time shopping list app that allows users to create, share, and manage shopping lists together.
  
  <img src="assets/feature.jpeg" alt="Baskit App Features" width="600">
</div>

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Firebase project (for backend services)
- Android Studio / Xcode for mobile development

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

- **Guest-First Experience**: Start using immediately without registration
- **Real-time Collaboration**: Share lists and collaborate instantly
- **Cross-platform**: iOS, Android, Web, and Desktop
- **Offline Support**: Full functionality without internet
- **Firebase Backend**: Real-time sync with secure authentication
- **Modern UI**: Material Design 3 with dark/light themes

## 🏗️ Architecture

### User Experience
1. **Anonymous Authentication**: Automatic Firebase anonymous auth
2. **Local-First Storage**: All data cached locally for instant responses
3. **Real-time Sync**: Background Firebase synchronization
4. **Optional Account**: Convert to Google/Email account for cross-device sync

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Hosting)
- **Storage**: Local cache + Firestore with offline persistence
- **Authentication**: Anonymous, Google, Email/Password

## 📚 Documentation

### Setup Guides
- **[Firebase Setup](docs/firebase-setup.md)** - Complete Firebase configuration
- **[Authentication](docs/authentication.md)** - Google Auth and anonymous login
- **[Development Guide](docs/development-guide.md)** - Local setup and testing

### Architecture
- **[Database Architecture](docs/database-architecture.md)** - Firestore data model and security
- **[UI & Assets](docs/ui-assets.md)** - Branding and asset management

## 🚀 Current Status

### ✅ Completed
- Complete Flutter app with Firebase backend
- Anonymous authentication with optional Google sign-in
- Real-time collaborative shopping lists
- Local-first storage with background sync
- Material Design 3 UI with responsive design
- Cross-platform support (iOS, Android, Web, Desktop)

### 🔄 Next Phase
- Migrate to Hive for enhanced local storage performance
- Advanced sharing with role-based permissions
- Push notifications for collaboration
- Web app deployment with Firebase Hosting

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
│   ├── models/          # Data models (ShoppingList, ShoppingItem)
│   ├── services/        # Firebase, storage, and business logic
│   ├── screens/         # UI screens (lists, profile, auth)
│   ├── widgets/         # Reusable UI components
│   └── utils/           # Routing and utilities
├── test/                # Unit, widget, and integration tests
└── integration_test/    # End-to-end tests
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

> 📖 **Need help?** Check the [docs/](docs/) folder for detailed setup guides and architecture information.
