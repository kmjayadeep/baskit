import 'package:flutter/material.dart';

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
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 60,
            backgroundColor:
                isGoogleUser ? Colors.green.shade100 : Colors.blue.shade100,
            backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
            child:
                photoURL == null
                    ? Icon(
                      isGoogleUser ? Icons.account_circle : Icons.person,
                      size: 60,
                      color: isGoogleUser ? Colors.green : Colors.blue,
                    )
                    : null,
          ),
          const SizedBox(height: 16),

          // Name and Status
          Text(
            displayName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            email ??
                (isAnonymous ? 'Sign in to sync your lists' : 'Signed in user'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
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
                isGoogleUser ? Colors.green.shade50 : Colors.orange.shade50,
          ),
        ],
      ),
    );
  }
}
