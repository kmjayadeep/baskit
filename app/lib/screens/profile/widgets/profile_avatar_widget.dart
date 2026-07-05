import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Widget that displays user profile avatar, name, email, and status
class ProfileAvatarWidget extends StatelessWidget {
  final bool isGoogleUser;
  final bool isAnonymous;
  final String displayName;
  final String? email;
  final String? photoURL;

  const ProfileAvatarWidget({
    super.key,
    required this.isGoogleUser,
    required this.isAnonymous,
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor:
                  isGoogleUser
                      ? AppColors.primaryGreen.withValues(alpha: 0.12)
                      : AppColors.basketOrange.withValues(alpha: 0.12),
              backgroundImage:
                  photoURL != null ? NetworkImage(photoURL!) : null,
              child:
                  photoURL == null
                      ? Icon(
                        isGoogleUser
                            ? Icons.account_circle
                            : Icons.person_outline,
                        size: 58,
                        color:
                            isGoogleUser
                                ? AppColors.primaryGreen
                                : AppColors.basketOrange,
                      )
                      : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email ??
                  (isAnonymous
                      ? 'Your lists are stored on this device'
                      : 'Signed in user'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                isGoogleUser
                    ? Icons.verified_user_outlined
                    : isAnonymous
                    ? Icons.person_outline
                    : Icons.account_circle,
                size: 18,
                color:
                    isGoogleUser
                        ? AppColors.primaryGreen
                        : AppColors.basketOrange,
              ),
              label: Text(
                isGoogleUser
                    ? 'Signed In'
                    : isAnonymous
                    ? 'Local-only'
                    : 'Guest User',
                style: TextStyle(
                  color:
                      isGoogleUser
                          ? AppColors.primaryGreen
                          : AppColors.basketOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor:
                  isGoogleUser
                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                      : AppColors.basketOrange.withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
