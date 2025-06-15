# Baskit 🛒

A collaborative real-time shopping list app that allows users to create, share, and manage shopping lists together.

## 📱 Features

- **Create Multiple Lists**: Users can create and manage multiple shopping lists
- **Real-time Collaboration**: Share lists with other users and collaborate in real-time
- **Live Updates**: Mark items as done and see changes instantly across all devices
- **Cross-platform**: Available on iOS, Android, Web, and Desktop (Flutter)
- **Offline Support**: Continue adding items even when offline, sync when back online
- **User Management**: Invite users via email or sharing links
- **List Categories**: Organize lists by categories (groceries, household, etc.)

## 🚀 Current Implementation Status

### ✅ Completed Features
- **Flutter App Structure**: Complete navigation system with go_router
- **Local Storage**: Lists are saved locally using SharedPreferences
- **Create Lists**: Full form validation, color selection, and preview
- **List Management**: View all created lists with real-time updates
- **UI/UX**: Modern Material Design 3 with light/dark theme support
- **Navigation**: Proper back navigation and routing between screens

### 🔄 In Progress
- **List Detail View**: Currently shows mock data, needs integration with local storage
- **Item Management**: Add, edit, delete items within lists
- **Real-time Sync**: Background synchronization with backend (planned)

### 📋 Planned Features
- **Backend Integration**: Cloudflare Workers + PostgreSQL + KV storage
- **User Authentication**: Login/register functionality
- **Real-time Collaboration**: WebSocket connections for live updates
- **Sharing**: Share lists via links or email invitations

## 🏗️ Architecture

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
│   │   ├── auth/ ✅
│   │   ├── lists/ ✅
│   │   ├── list_detail/ ✅ (UI only)
│   │   └── profile/ ✅ (UI only)
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

## 🛠️ Local Storage

The app currently uses local storage for data persistence:

- **SharedPreferences**: Stores shopping lists as JSON
- **UUID**: Generates unique IDs for lists
- **Automatic Sync**: Planned background sync with backend
- **Offline First**: App works completely offline

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

3. **Create Your First List**
   - Tap the "+" button or "New List"
   - Enter a name and optional description
   - Choose a color
   - Tap "Create List"

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for better shopping experiences
