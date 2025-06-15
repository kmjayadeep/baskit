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
- **UI/UX**: Modern Material Design 3 with light/dark theme support
- **Navigation**: Proper back navigation and routing between screens
- **Profile Management**: Guest mode with optional sign-in

### 🔄 In Progress
- **List Detail View**: Currently shows mock data, needs integration with local storage
- **Item Management**: Add, edit, delete items within lists
- **Real-time Sync**: Background synchronization with backend (planned)

### 📋 Planned Features
- **Backend Integration**: Cloudflare Workers + PostgreSQL + KV storage
- **Enhanced Authentication**: Full user management and profile features
- **Real-time Collaboration**: WebSocket connections for live updates
- **Sharing**: Share lists via links or email invitations
- **Account Sync**: Sync local lists to account when user signs up

## 🏗️ Architecture

### User Experience Flow
1. **Guest Mode (Default)**: Users land directly on the lists page
2. **Local Storage**: All lists saved locally, works completely offline
3. **Optional Sign-In**: Users can sign in from profile screen to sync data
4. **Account Creation**: Quick registration with option to continue as guest

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
│   │   ├── storage_service.dart ✅
│   │   ├── api_service.dart
│   │   ├── realtime_service.dart
│   │   └── auth_service.dart
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

### Backend Architecture (Planned)
- **Cloudflare Workers**: Serverless API endpoints
- **PostgreSQL**: Persistent data storage
- **Cloudflare KV**: Real-time state management
- **Durable Objects**: Real-time coordination
- **WebSockets**: Live collaboration features

## 🛠️ Local Storage & Guest Mode

The app prioritizes local-first functionality:

- **Guest Mode**: Full functionality without registration
- **SharedPreferences**: Stores shopping lists as JSON locally
- **UUID**: Generates unique IDs for lists
- **Offline First**: App works completely offline
- **Optional Sync**: Planned background sync when user signs in

### Data Structure
```dart
ShoppingList {
  String id;           // UUID
  String name;         // List name
  String description;  // Optional description
  String color;        // Hex color code
  DateTime createdAt;  // Creation timestamp
  DateTime updatedAt;  // Last update timestamp
  List<String> items;  // Item names (simplified for now)
}
```

## 🚀 Getting Started

1. **Install Dependencies**
   ```bash
   cd app
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Start Using Immediately**
   - App opens directly to your lists
   - Tap "+" to create your first list
   - No registration required!
   - Optional: Tap profile icon to sign in for sync features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for better shopping experiences
