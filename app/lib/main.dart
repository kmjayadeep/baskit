import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't fail if it's not configured
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');

    // Enable Firestore offline persistence
    await FirestoreService.enableOfflinePersistence();

    // Initialize anonymous authentication
    await FirebaseAuthService.signInAnonymously();

    // Initialize user profile
    await FirestoreService.initializeUserProfile();

    print('✅ Firebase services initialized');
  } catch (e) {
    print('⚠️  Firebase initialization failed: $e');
    print('📱 Running in local-only mode');
  }

  runApp(BaskitApp(firebaseEnabled: firebaseInitialized));
}

class BaskitApp extends StatelessWidget {
  final bool firebaseEnabled;

  const BaskitApp({super.key, this.firebaseEnabled = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Baskit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
