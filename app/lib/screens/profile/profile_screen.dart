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
          onPressed: () => context.go('/lists'),
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

              // Features available with Google account
              AuthConditional(
                authenticated: _buildAuthenticatedFeatures(context),
                anonymous: _buildAnonymousPrompt(context),
              ),
              const SizedBox(height: 32),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Lists Created',
                      FirebaseAuthService.isGoogleUser ? '3' : '-',
                      Icons.list_alt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Items Added',
                      FirebaseAuthService.isGoogleUser ? '24' : '-',
                      Icons.add_shopping_cart,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Shared Lists',
                      FirebaseAuthService.isGoogleUser ? '1' : '-',
                      Icons.share,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Completed',
                      FirebaseAuthService.isGoogleUser ? '87%' : '-',
                      Icons.check_circle,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Settings Section
              _buildSettingsSection(context),
              const SizedBox(height: 24),

              // About Section
              _buildAboutSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedFeatures(BuildContext context) {
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
                  'Account Benefits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.sync,
              'Cross-device sync',
              'Access your lists on all devices',
            ),
            _buildBenefitItem(
              Icons.share,
              'List sharing',
              'Collaborate with friends and family',
            ),
            _buildBenefitItem(
              Icons.backup,
              'Cloud backup',
              'Your data is safely backed up',
            ),
            _buildBenefitItem(
              Icons.offline_bolt,
              'Offline support',
              'Works offline, syncs when online',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousPrompt(BuildContext context) {
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
                  'Upgrade Your Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google to unlock premium features:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.sync_disabled,
              'Cross-device sync',
              'Access lists on all your devices',
              isDisabled: true,
            ),
            _buildBenefitItem(
              Icons.share_outlined,
              'List sharing',
              'Collaborate with others',
              isDisabled: true,
            ),
            _buildBenefitItem(
              Icons.backup_outlined,
              'Cloud backup',
              'Never lose your lists',
              isDisabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isDisabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDisabled ? Colors.grey : Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDisabled ? Colors.grey : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled ? Colors.grey : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage your notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notifications settings
              _showComingSoon(context, 'Notifications');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            subtitle: const Text('Manage your privacy settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy settings
              _showComingSoon(context, 'Privacy Settings');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Choose your app theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to theme settings
              _showComingSoon(context, 'Theme Selection');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help
              _showComingSoon(context, 'Help & Support');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Baskit'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            subtitle: const Text('Rate us on the app store'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open app store rating
              _showComingSoon(context, 'App Rating');
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon! 🚀'),
        behavior: SnackBarBehavior.floating,
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
                Text('Version: 1.0.0'),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                Text(
                  'Made with ❤️ for better shopping experiences',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
