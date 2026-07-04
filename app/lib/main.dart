import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/storage_shopping_repository.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/app_router.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Try to initialize Firebase, but don't fail if it's not configured
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');

    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = (errorDetails) {
      unawaited(
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails),
      );
    };
    // Pass all uncaught async errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      return true;
    };

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

  // Initialize the shopping repository (includes Hive setup)
  try {
    await StorageShoppingRepository.instance().init();
    debugPrint('✅ Shopping repository initialized');
  } catch (e) {
    debugPrint('❌ Shopping repository initialization failed: $e');
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
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
          primary: AppColors.primaryGreen,
          secondary: AppColors.basketOrange,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.warmBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.warmBackground,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
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
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
