import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'utils/app_router.dart';
import 'widgets/whats_new_dialog.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't fail if it's not configured
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');

    // Enable Firestore offline persistence
    await FirestoreService.enableOfflinePersistence();

    // Initialize anonymous authentication
    await FirebaseAuthService.signInAnonymously();

    // Initialize user profile
    await FirestoreService.initializeUserProfile();

    debugPrint('✅ Firebase services initialized');
  } catch (e) {
    debugPrint('⚠️  Firebase initialization failed: $e');
    debugPrint('📱 Running in local-only mode');
  }

  // Initialize storage service (includes Hive setup)
  try {
    await StorageService.instance.init();
    debugPrint('✅ Storage service initialized');
  } catch (e) {
    debugPrint('❌ Storage service initialization failed: $e');
  }

  runApp(ProviderScope(child: BaskitApp(firebaseEnabled: firebaseInitialized)));
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
        cardTheme: CardThemeData(
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
        cardTheme: CardThemeData(
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
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Get current location first
            final currentLocation =
                AppRouter.router.routeInformationProvider.value.uri.path;

            // If we're at the root route (/lists), exit the app
            if (currentLocation == '/lists') {
              SystemNavigator.pop();
              return;
            }

            // For other routes, try to use the navigation stack first
            final navigator =
                AppRouter.router.routerDelegate.navigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
            } else {
              // If no navigation history, go to home
              AppRouter.router.go('/lists');
            }
          },
          child: WhatsNewWrapper(child: child ?? const SizedBox()),
        );
      },
    );
  }
}

/// Wrapper widget to handle What's New dialog display
class WhatsNewWrapper extends StatefulWidget {
  final Widget child;

  const WhatsNewWrapper({super.key, required this.child});

  @override
  State<WhatsNewWrapper> createState() => _WhatsNewWrapperState();
}

class _WhatsNewWrapperState extends State<WhatsNewWrapper> {
  @override
  void initState() {
    super.initState();
    // Check and show What's New dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWhatsNew();
    });
  }

  Future<void> _checkAndShowWhatsNew() async {
    // Skip in test environment to avoid timer issues
    if (kDebugMode &&
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }

    // Add a small delay to ensure the app is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await WhatsNewService.checkAndShow(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
