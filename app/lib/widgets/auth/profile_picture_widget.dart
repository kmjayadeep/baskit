import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';

class ProfilePictureWidget extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ProfilePictureWidget({
    super.key,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final photoURL = FirebaseAuthService.userPhotoURL;
        
        if (photoURL != null && photoURL.isNotEmpty) {
          // Show user's profile picture
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  photoURL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return _buildDefaultIcon(context);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          // Show default person icon
          return _buildDefaultIcon(context);
        }
      },
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
} 