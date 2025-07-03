import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  final Widget Function(
    BuildContext context,
    bool isAuthenticated,
    bool isFirebaseAvailable,
  )?
  builder;
  final VoidCallback? onAuthStateChanged;

  const AuthWrapper({
    super.key,
    required this.child,
    this.builder,
    this.onAuthStateChanged,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _previousIsAuthenticated;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isFirebaseAvailable = FirebaseAuthService.isFirebaseAvailable;
        final isAuthenticated =
            !FirebaseAuthService.isAnonymous && snapshot.hasData;

        // Only call callback if authentication state changed
        if (_previousIsAuthenticated != null && 
            _previousIsAuthenticated != isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAuthStateChanged?.call();
          });
        }
        _previousIsAuthenticated = isAuthenticated;

        if (widget.builder != null) {
          return widget.builder!(context, isAuthenticated, isFirebaseAvailable);
        }

        return widget.child;
      },
    );
  }
}

// Helper widget for conditional content based on auth state
class AuthConditional extends StatelessWidget {
  final Widget authenticated;
  final Widget anonymous;
  final Widget? firebaseDisabled;

  const AuthConditional({
    super.key,
    required this.authenticated,
    required this.anonymous,
    this.firebaseDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isFirebaseAvailable = FirebaseAuthService.isFirebaseAvailable;
        final isAuthenticated =
            !FirebaseAuthService.isAnonymous && snapshot.hasData;

        if (!isFirebaseAvailable && firebaseDisabled != null) {
          return firebaseDisabled!;
        }

        return isAuthenticated ? authenticated : anonymous;
      },
    );
  }
}

// Status indicator widget
class AuthStatusIndicator extends StatelessWidget {
  final bool showText;

  const AuthStatusIndicator({super.key, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isFirebaseAvailable = FirebaseAuthService.isFirebaseAvailable;
        final isGoogleUser = FirebaseAuthService.isGoogleUser;
        final isAnonymous = FirebaseAuthService.isAnonymous;

        Color indicatorColor;
        IconData icon;
        String statusText;

        if (!isFirebaseAvailable) {
          indicatorColor = Colors.grey;
          icon = Icons.cloud_off;
          statusText = 'Offline';
        } else if (isGoogleUser) {
          indicatorColor = Colors.green;
          icon = Icons.cloud_done;
          statusText = 'Synced';
        } else if (isAnonymous) {
          indicatorColor = Colors.orange;
          icon = Icons.cloud_queue;
          statusText = 'Guest';
        } else {
          indicatorColor = Colors.blue;
          icon = Icons.cloud;
          statusText = 'Connected';
        }

        if (!showText) {
          return Icon(icon, color: indicatorColor, size: 16);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: indicatorColor, size: 16),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: indicatorColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
