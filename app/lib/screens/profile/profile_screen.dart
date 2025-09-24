import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/auth/google_sign_in_widget.dart';
import '../../widgets/auth/auth_wrapper.dart';
import 'widgets/profile_avatar_widget.dart';
import 'widgets/sign_in_prompt_widget.dart';
import 'widgets/account_benefits_widget.dart';
import 'widgets/about_section_widget.dart';
import 'view_models/profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
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
                isGoogleUser: profileState.isGoogleUser,
                isAnonymous: profileState.isAnonymous,
                displayName: profileState.displayName,
                email: profileState.email,
                photoURL: profileState.photoURL,
              ),
              const SizedBox(height: 32),

              // Google Sign-In Widget
              GoogleSignInWidget(
                showAccountInfo: false,
                onSignInSuccess: viewModel.onSignInSuccess,
                onSignOut: viewModel.onSignOut,
              ),
              const SizedBox(height: 24),

              // Account Benefits
              if (profileState.isAnonymous) const SignInPromptWidget(),
              if (!profileState.isAnonymous) const AccountBenefitsWidget(),

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
