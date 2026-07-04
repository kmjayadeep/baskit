import 'package:firebase_auth/firebase_auth.dart';

/// Typed result for account deletion attempts.
///
/// This keeps Firebase-specific errors out of the UI while still letting the UI
/// decide whether to prompt re-authentication, show a manual request path, or
/// report a generic failure.
enum AccountDeletionStatus {
  success,
  firebaseUnavailable,
  noSignedInUser,
  anonymousUser,
  requiresRecentLogin,
  reauthenticationCancelled,
  reauthenticationFailed,
  failed,
}

class AccountDeletionResult {
  final AccountDeletionStatus status;
  final String message;

  const AccountDeletionResult({required this.status, required this.message});

  bool get isSuccess => status == AccountDeletionStatus.success;

  bool get requiresReauthentication =>
      status == AccountDeletionStatus.requiresRecentLogin;

  static const success = AccountDeletionResult(
    status: AccountDeletionStatus.success,
    message: 'Account deleted. You are now in guest mode.',
  );

  static const firebaseUnavailable = AccountDeletionResult(
    status: AccountDeletionStatus.firebaseUnavailable,
    message:
        'Account deletion is unavailable while cloud services are not configured.',
  );

  static const noSignedInUser = AccountDeletionResult(
    status: AccountDeletionStatus.noSignedInUser,
    message: 'No signed-in account is available to delete.',
  );

  static const anonymousUser = AccountDeletionResult(
    status: AccountDeletionStatus.anonymousUser,
    message:
        'Guest mode does not have a cloud account to delete. Your lists stay on this device unless you sign in.',
  );

  static const requiresRecentLogin = AccountDeletionResult(
    status: AccountDeletionStatus.requiresRecentLogin,
    message: 'Please sign in again before deleting your account.',
  );

  static const reauthenticationCancelled = AccountDeletionResult(
    status: AccountDeletionStatus.reauthenticationCancelled,
    message: 'Re-authentication was cancelled. Your account was not deleted.',
  );

  static const reauthenticationFailed = AccountDeletionResult(
    status: AccountDeletionStatus.reauthenticationFailed,
    message:
        'Could not confirm your identity. Your account was not deleted. Please try again or use the account deletion request page.',
  );

  static const failed = AccountDeletionResult(
    status: AccountDeletionStatus.failed,
    message:
        'Could not delete your account. Your account was not deleted. Please try again or use the account deletion request page.',
  );

  factory AccountDeletionResult.fromAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return requiresRecentLogin;
      case 'web-context-cancelled':
      case 'popup-closed-by-user':
      case 'canceled':
      case 'cancelled-popup-request':
        return reauthenticationCancelled;
      default:
        return failed;
    }
  }
}
