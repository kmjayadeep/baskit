import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';

class GoogleSignInWidget extends StatefulWidget {
  final bool showAccountInfo;
  final VoidCallback? onSignInSuccess;
  final VoidCallback? onSignOut;

  const GoogleSignInWidget({
    super.key,
    this.showAccountInfo = true,
    this.onSignInSuccess,
    this.onSignOut,
  });

  @override
  State<GoogleSignInWidget> createState() => _GoogleSignInWidgetState();
}

class _GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (!FirebaseAuthService.isFirebaseAvailable) {
      _showMessage('Firebase not configured. Running in local mode.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await FirebaseAuthService.signInWithGoogle();
      if (result != null) {
        _showMessage('Successfully signed in with Google!');
        widget.onSignInSuccess?.call();
      } else {
        _showMessage('Sign-in was cancelled.');
      }
    } catch (e) {
      _showMessage('Sign-in failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuthService.signOut();
      _showMessage('Signed out successfully');
      widget.onSignOut?.call();
    } catch (e) {
      _showMessage('Sign-out failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final isGoogleUser = FirebaseAuthService.isGoogleUser;
        final isAnonymous = FirebaseAuthService.isAnonymous;
        final accountStatus = FirebaseAuthService.accountStatusText;
        final upgradePrompt = FirebaseAuthService.upgradePrompt;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Account Status
                if (widget.showAccountInfo) ...[
                  Row(
                    children: [
                      Icon(
                        isGoogleUser
                            ? Icons.account_circle
                            : isAnonymous
                            ? Icons.person_outline
                            : Icons.offline_bolt,
                        color:
                            isGoogleUser
                                ? Colors.green
                                : isAnonymous
                                ? Colors.orange
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseAuthService.userDisplayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              accountStatus,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upgradePrompt,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child:
                      _isLoading
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : isGoogleUser
                          ? OutlinedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          )
                          : ElevatedButton.icon(
                            onPressed:
                                FirebaseAuthService.isFirebaseAvailable
                                    ? _handleSignIn
                                    : null,
                            icon: const Icon(Icons.account_circle, size: 18),
                            label: Text(
                              FirebaseAuthService.isFirebaseAvailable
                                  ? 'Sign in with Google'
                                  : 'Firebase not configured',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                ),

                // User Info for Google Users
                if (isGoogleUser && widget.showAccountInfo) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (FirebaseAuthService.userEmail != null)
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            FirebaseAuthService.userEmail!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
