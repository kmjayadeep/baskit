# Baskit 🛒

A collaborative real-time shopping list app that allows users to create, share, and manage shopping lists together.

## 📱 Features

- **Guest-First Experience**: Start using the app immediately without registration
- **Create Multiple Lists**: Users can create and manage multiple shopping lists
- **Optional Authentication**: Sign in to sync lists across devices and collaborate
- **Real-time Collaboration**: Share lists with other users and collaborate in real-time (when signed in)
- **Live Updates**: Mark items as done and see changes instantly across all devices
- **Cross-platform**: Available on iOS, Android, Web, and Desktop (Flutter)
- **Offline Support**: Continue adding items even when offline, sync when back online
- **User Management**: Invite users via email or sharing links (when signed in)
- **List Categories**: Organize lists by categories (groceries, household, etc.)

## 🚀 Current Implementation Status

### ✅ Completed Features
- **Flutter App Structure**: Complete navigation system with go_router
- **Guest Experience**: App starts directly on lists page, no login required
- **Optional Authentication**: Login/register available but not mandatory
- **Local Storage**: Lists are saved locally using SharedPreferences
- **Create Lists**: Full form validation, color selection, and preview
- **List Management**: View all created lists with real-time updates
- **List Detail View**: Full integration with local storage, real-time item management
- **Item Management**: Add, edit, delete items within lists with quantity support
- **UI/UX**: Modern Material Design 3 with light/dark theme support
- **Navigation**: Proper back navigation and routing between screens
- **Profile Management**: Guest mode with optional sign-in

### 🔄 In Progress
- **Firebase Backend Integration**: Migrating to Firebase for comprehensive backend solution

### 📋 Planned Features
- **Firebase Authentication**: Google, Email, and Anonymous auth with seamless guest conversion
- **Firebase Firestore**: Real-time database with offline support and automatic sync
- **Real-time Collaboration**: Live updates across devices using Firestore real-time listeners
- **Firebase Security Rules**: Secure data access and sharing permissions
- **Cloud Functions**: Server-side logic for invitations and notifications
- **Firebase Hosting**: Web app deployment with CDN
- **Account Sync**: Automatic sync when converting from guest to authenticated user

## 🏗️ Architecture

### User Experience Flow
1. **Anonymous Auth (Default)**: Users automatically get Firebase anonymous auth
2. **Local + Cloud Storage**: Lists saved locally and synced to Firestore in real-time
3. **Seamless Offline**: Firestore provides automatic offline persistence
4. **Optional Account Creation**: Convert anonymous user to full account with Google/Email
5. **Real-time Collaboration**: Share lists and see live updates across devices

### Frontend (Flutter App)
```
app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── shopping_list.dart ✅
│   │   ├── user.dart
│   │   ├── shopping_item.dart
│   │   └── list_member.dart
│   ├── services/
│   │   ├── firebase_auth_service.dart 🔄
│   │   ├── firestore_service.dart 🔄
│   │   ├── realtime_service.dart 🔄
│   │   └── storage_service.dart ✅ (local cache)
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── lists_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── auth/ ✅ (optional)
│   │   ├── lists/ ✅ (default landing)
│   │   ├── list_detail/ ✅ (UI only)
│   │   └── profile/ ✅ (guest/user modes)
│   ├── widgets/
│   │   ├── common/
│   │   ├── list_widgets/
│   │   └── item_widgets/
│   └── utils/
│       ├── app_router.dart ✅
│       ├── constants.dart
│       ├── validators.dart
│       └── helpers.dart
```

### Backend Architecture 🔄 **REDESIGNED FOR FIREBASE**

#### Firebase Services
- **Firebase Authentication**: Anonymous, Google, and Email authentication
- **Firestore Database**: Real-time NoSQL database with offline support
- **Cloud Functions**: Server-side logic for complex operations
- **Firebase Storage**: File uploads and media storage
- **Firebase Hosting**: Static web app hosting with CDN
- **Firebase Security Rules**: Database and storage access control

#### Database Structure (Firestore)
```
users/{userId}
├── profile: { email, displayName, photoURL, createdAt, isAnonymous }
├── lists/{listId}
│   ├── metadata: { name, description, color, createdAt, updatedAt, ownerId }
│   ├── members: { [userId]: { role, joinedAt, permissions } }
│   └── items/{itemId}: { name, quantity, completed, createdAt, updatedAt, createdBy }
└── invitations/{invitationId}: { listId, email, role, status, createdAt, expiresAt }

shared_lists/{listId}
├── metadata: { name, description, color, createdAt, updatedAt, ownerId }
├── members: { [userId]: { role, joinedAt, permissions } }
└── activity: { [activityId]: { type, userId, timestamp, data } }
```

#### Cloud Functions (TypeScript)
- **onUserCreate**: Initialize user profile and migrate anonymous data
- **onListCreate**: Set up list permissions and sharing
- **onListShare**: Send invitation emails and manage permissions
- **sendInvitation**: Email invitations with secure links
- **processInvitation**: Handle invitation acceptance/rejection
- **cleanupExpiredInvitations**: Background cleanup of expired invitations

#### Security Rules Features
- **User-based Access**: Users can only access their own data
- **List Sharing**: Shared lists accessible to invited members only
- **Role-based Permissions**: Owner, Editor, Viewer roles with different capabilities
- **Anonymous Support**: Anonymous users get full functionality
- **Real-time Validation**: Server-side validation for all operations

## 🛠️ Firebase Integration & Offline Support

The app uses Firebase's built-in offline capabilities:

- **Anonymous Authentication**: Users start with Firebase anonymous auth automatically
- **Firestore Offline**: Built-in offline persistence with automatic sync
- **Real-time Listeners**: Live updates across devices when online
- **Seamless Conversion**: Convert anonymous users to full accounts
- **Local Cache**: Firestore handles local caching automatically

### Enhanced Data Models
```dart
// User model with Firebase integration
class AppUser {
  String uid;              // Firebase UID
  String? email;           // Email (null for anonymous)
  String? displayName;     // Display name
  String? photoURL;        // Profile photo
  bool isAnonymous;        // Anonymous vs authenticated
  DateTime createdAt;      // Account creation
  List<String> listIds;    // Owned lists
  List<String> sharedIds;  // Shared lists
}

// Enhanced shopping list model
class ShoppingList {
  String id;                        // Firestore document ID
  String name;                      // List name
  String? description;              // Optional description
  String color;                     // Hex color code
  String ownerId;                   // Owner's Firebase UID
  DateTime createdAt;               // Creation timestamp
  DateTime updatedAt;               // Last update timestamp
  Map<String, ListMember> members;  // List members with roles
  List<ShoppingItem> items;         // Shopping items
  bool isShared;                    // Sharing status
}

// Shopping item with collaboration features
class ShoppingItem {
  String id;              // Firestore document ID
  String name;            // Item name
  int quantity;           // Quantity needed
  bool completed;         // Completion status
  String createdBy;       // Creator's UID
  DateTime createdAt;     // Creation timestamp
  DateTime? completedAt;  // Completion timestamp
  String? completedBy;    // Who completed it
}

// List member with permissions
class ListMember {
  String userId;          // Member's Firebase UID
  String role;            // owner, editor, viewer
  DateTime joinedAt;      // When they joined
  Map<String, bool> permissions; // Granular permissions
}
```

## 🚀 Getting Started

### Frontend (Flutter App)

1. **Install Dependencies**
   ```bash
   cd app
   flutter pub get
   ```

2. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Anonymous, Google, Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective platform directories

3. **Run the App**
   ```bash
   flutter run
   ```

4. **Start Using Immediately**
   - App automatically signs in anonymously
   - All data syncs to Firestore in real-time
   - Works offline with automatic sync when online
   - Optional: Convert to full account for cross-device sync

### Backend (Firebase Services)

1. **Firestore Setup**
   - Database rules configured for user-based access
   - Collections automatically created on first use
   - Offline persistence enabled by default

2. **Cloud Functions (Optional)**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

3. **Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only storage:rules
   ```

4. **Web Hosting**
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

## 📚 Documentation

- **Firebase Setup**: Complete guide for setting up Firebase project and services
- **Security Rules**: Firestore and Storage security rules for data protection
- **Cloud Functions**: Server-side logic examples and deployment guide
- **Flutter Integration**: Examples for integrating with Firebase services

## 🔐 Authentication & Data Flow

1. **Anonymous Start**: Users automatically get Firebase anonymous authentication
2. **Real-time Sync**: All data immediately syncs to Firestore with offline support
3. **Account Conversion**: Seamlessly link anonymous account to Google/Email
4. **Cross-device Sync**: Data automatically syncs across all user devices
5. **Collaboration**: Share lists with real-time updates for all members
6. **Security**: Firestore security rules ensure users only access their own data

### Benefits of Firebase Approach

- **Real-time Database**: Firestore provides instant updates across devices
- **Offline First**: Built-in offline persistence with automatic sync
- **Scalability**: Firebase handles scaling automatically
- **Security**: Built-in authentication and security rules
- **Simplicity**: No custom backend code needed for basic operations
- **Cost Effective**: Pay-as-you-go pricing model
- **Analytics**: Built-in usage analytics and crash reporting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for better shopping experiences
