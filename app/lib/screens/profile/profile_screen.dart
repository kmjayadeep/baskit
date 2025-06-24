import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/auth/google_sign_in_widget.dart';
import '../../widgets/auth/auth_wrapper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/lists');
            }
          },
        ),
      ),
      body: AuthWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile Picture and Info
              StreamBuilder(
                stream: FirebaseAuthService.authStateChanges,
                builder: (context, snapshot) {
                  final isGoogleUser = FirebaseAuthService.isGoogleUser;
                  final isAnonymous = FirebaseAuthService.isAnonymous;
                  final displayName = FirebaseAuthService.userDisplayName;
                  final email = FirebaseAuthService.userEmail;
                  final photoURL = FirebaseAuthService.userPhotoURL;

                  return Center(
                    child: Column(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              isGoogleUser
                                  ? Colors.green.shade100
                                  : Colors.blue.shade100,
                          backgroundImage:
                              photoURL != null ? NetworkImage(photoURL) : null,
                          child:
                              photoURL == null
                                  ? Icon(
                                    isGoogleUser
                                        ? Icons.account_circle
                                        : Icons.person,
                                    size: 60,
                                    color:
                                        isGoogleUser
                                            ? Colors.green
                                            : Colors.blue,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Name and Status
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ??
                              (isAnonymous
                                  ? 'Sign in to sync your lists'
                                  : 'Signed in user'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),

                        // Account Status Chip
                        Chip(
                          avatar: Icon(
                            isGoogleUser
                                ? Icons.verified_user
                                : isAnonymous
                                ? Icons.person_outline
                                : Icons.account_circle,
                            size: 18,
                            color: isGoogleUser ? Colors.green : Colors.orange,
                          ),
                          label: Text(
                            isGoogleUser ? 'Signed In' : 'Guest User',
                            style: TextStyle(
                              color:
                                  isGoogleUser
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor:
                              isGoogleUser
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Google Sign-In Widget
              GoogleSignInWidget(
                showAccountInfo: false,
                onSignInSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully signed in with Google! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onSignOut: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out successfully'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Account Benefits
              if (FirebaseAuthService.isAnonymous) _buildSignInPrompt(context),
              if (!FirebaseAuthService.isAnonymous)
                _buildAccountBenefits(context),

              const SizedBox(height: 32),

              // About Section
              _buildAboutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_queue, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Sign In to Unlock Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google to sync your lists across devices and collaborate with others.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBenefits(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Account Active',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your lists are synced across devices and backed up to the cloud.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('About Baskit'),
        subtitle: const Text('A collaborative shopping list app'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showAboutDialog(context);
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.shopping_basket, color: Colors.blue),
                const SizedBox(width: 8),
                Text('About Baskit'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A collaborative shopping list app that makes shopping with friends and family easy.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Guest-first experience'),
                Text('• Real-time collaboration'),
                Text('• Cross-device sync'),
                Text('• Offline support'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
