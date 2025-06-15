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

## 🏗️ Architecture

### Frontend (Flutter App)
```
app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── shopping_list.dart
│   │   ├── shopping_item.dart
│   │   └── list_member.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── realtime_service.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── lists_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── lists/
│   │   ├── list_detail/
│   │   └── profile/
│   ├── widgets/
│   │   ├── common/
│   │   ├── list_widgets/
│   │   └── item_widgets/
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       └── helpers.dart
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for better shopping experiences
