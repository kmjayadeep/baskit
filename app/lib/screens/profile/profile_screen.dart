import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/google_sign_in_widget.dart';
import '../../widgets/auth/auth_wrapper.dart';
import '../../view_models/auth_view_model.dart';
import 'widgets/profile_avatar_widget.dart';
import 'widgets/sign_in_prompt_widget.dart';
import 'widgets/account_benefits_widget.dart';
import 'widgets/about_section_widget.dart';
import 'view_models/profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state from centralized AuthViewModel
    final authState = ref.watch(authViewModelProvider);
    // Read UI ViewModel for methods (state is watched via ref.listen)
    final viewModel = ref.read(profileViewModelProvider.notifier);

    // Handle success/error messages
    ref.listen(profileViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        viewModel.clearSuccessMessage();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        viewModel.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always go to home screen (lists)
            context.go('/lists');
          },
        ),
      ),
      body: AuthWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile Picture and Info
              ProfileAvatarWidget(
                isGoogleUser: authState.isGoogleUser,
                isAnonymous: authState.isAnonymous,
                displayName: authState.displayName,
                email: authState.email,
                photoURL: authState.photoURL,
              ),
              const SizedBox(height: 32),

              // Google Sign-In Widget
              GoogleSignInWidget(
                isGoogleUser: authState.isGoogleUser,
                isAnonymous: authState.isAnonymous,
                isFirebaseAvailable: authState.isFirebaseAvailable,
                displayName: authState.displayName,
                email: authState.email,
                accountStatus:
                    authState.isGoogleUser
                        ? 'Google Account'
                        : authState.isAnonymous
                        ? 'Anonymous User'
                        : 'Signed In',
                upgradePrompt:
                    authState.isAnonymous
                        ? 'Sign in with Google to sync your lists across devices and access them anywhere.'
                        : 'Your data is synced across all your devices.',
                showAccountInfo: false,
                onSignInSuccess: viewModel.onSignInSuccess,
                onSignOut: viewModel.onSignOut,
              ),
              const SizedBox(height: 24),

              // Account Benefits
              if (authState.isAnonymous) const SignInPromptWidget(),
              if (!authState.isAnonymous) const AccountBenefitsWidget(),

              const SizedBox(height: 32),

              // About Section
              const AboutSectionWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
