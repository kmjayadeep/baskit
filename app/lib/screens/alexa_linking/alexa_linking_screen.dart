import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../services/alexa_account_linking.dart';
import '../../services/alexa_link_service.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/auth/google_sign_in_widget.dart';

class AlexaLinkingScreen extends ConsumerStatefulWidget {
  final AlexaLinkParams? params;

  const AlexaLinkingScreen({super.key, required this.params});

  @override
  ConsumerState<AlexaLinkingScreen> createState() => _AlexaLinkingScreenState();
}

class _AlexaLinkingScreenState extends ConsumerState<AlexaLinkingScreen> {
  bool _isCompleting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final params = widget.params;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: const Text('Link Alexa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(error: _error),
              const SizedBox(height: 20),
              if (params == null || !params.isValid)
                const _TerminalMessageCard(
                  icon: Icons.link_off,
                  title: 'Alexa request incomplete',
                  message:
                      'We could not start Alexa linking because the request was incomplete. Please try again from the Alexa app.',
                )
              else if (!authState.isFirebaseAvailable)
                const _TerminalMessageCard(
                  icon: Icons.cloud_off,
                  title: 'Cloud sign-in unavailable',
                  message:
                      'Alexa linking requires Firebase cloud sign-in. This build is running without Firebase.',
                )
              else if (authState.isAnonymous)
                _SignInRequiredCard(authState: authState)
              else
                _ConfirmLinkCard(
                  authState: authState,
                  isCompleting: _isCompleting,
                  onLink: () => _completeLinking(params),
                  onCancel: () => _cancelLinking(params),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeLinking(AlexaLinkParams params) async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
      _error = null;
    });

    try {
      final user = ref.read(authUserProvider);
      if (user == null || user.isAnonymous) {
        setState(() => _error = 'Please sign in with a cloud account first.');
        return;
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        setState(() => _error = 'Your sign-in expired. Please sign in again.');
        return;
      }
      if (!params.isValid) {
        setState(
          () =>
              _error =
                  'Alexa did not send a complete linking request. Please restart linking from the Alexa app.',
        );
        return;
      }

      final result = await AlexaLinkService.completeAuthorization(
        params: params,
        idToken: idToken,
      );
      final redirect = buildAlexaSuccessRedirect(params, result);
      final opened = await AlexaLinkService.openAlexaRedirect(redirect);

      if (!mounted) return;
      if (!opened) {
        setState(() {
          _error =
              'Baskit linked your account, but could not return to Alexa automatically.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            error is AlexaLinkException
                ? error.message
                : 'Could not link Alexa right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _cancelLinking(AlexaLinkParams params) async {
    final redirect = buildAlexaErrorRedirect(params, 'access_denied');
    final opened = await AlexaLinkService.openAlexaRedirect(redirect);
    if (!mounted) return;
    if (!opened) {
      context.go('/profile');
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String? error;

  const _HeaderCard({this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.record_voice_over, color: AppColors.primaryGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Link Alexa to Baskit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Alexa will be able to add items to your cloud-synced Baskit lists using your voice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignInRequiredCard extends StatelessWidget {
  final AuthState authState;

  const _SignInRequiredCard({required this.authState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud account required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Local guest lists live only on this device. Sign in so Alexa can securely add items through Baskit cloud sync.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GoogleSignInWidget(
          isGoogleUser: authState.isGoogleUser,
          isAnonymous: authState.isAnonymous,
          isFirebaseAvailable: authState.isFirebaseAvailable,
          displayName: authState.displayName,
          email: authState.email,
          accountStatus: 'Guest mode',
          upgradePrompt:
              'Sign in with Google, then confirm linking Alexa to this Baskit account.',
        ),
      ],
    );
  }
}

class _ConfirmLinkCard extends StatelessWidget {
  final AuthState authState;
  final bool isCompleting;
  final VoidCallback onLink;
  final VoidCallback onCancel;

  const _ConfirmLinkCard({
    required this.authState,
    required this.isCompleting,
    required this.onLink,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                child: const Icon(Icons.person, color: AppColors.primaryGreen),
              ),
              title: Text(authState.displayName),
              subtitle: Text(authState.email ?? 'Signed-in Baskit account'),
            ),
            const SizedBox(height: 12),
            Text(
              'Only link Alexa if this is the Baskit account you want to use for voice commands.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleting ? null : onLink,
                icon:
                    isCompleting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.link),
                label: Text(isCompleting ? 'Linking...' : 'Link Alexa'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isCompleting ? null : onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TerminalMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: AppColors.basketOrange),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
