import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/auth/google_sign_in_widget.dart';
import '../../widgets/auth/auth_wrapper.dart';
import 'widgets/profile_avatar_widget.dart';
import 'widgets/sign_in_prompt_widget.dart';
import 'widgets/account_benefits_widget.dart';
import 'widgets/about_section_widget.dart';

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
                  return ProfileAvatarWidget(
                    isGoogleUser: FirebaseAuthService.isGoogleUser,
                    isAnonymous: FirebaseAuthService.isAnonymous,
                    displayName: FirebaseAuthService.userDisplayName,
                    email: FirebaseAuthService.userEmail,
                    photoURL: FirebaseAuthService.userPhotoURL,
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
              if (FirebaseAuthService.isAnonymous) const SignInPromptWidget(),
              if (!FirebaseAuthService.isAnonymous)
                const AccountBenefitsWidget(),

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
