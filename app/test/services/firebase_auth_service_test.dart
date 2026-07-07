import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/firebase_auth_service.dart';

void main() {
  group('GoogleSignInFailure', () {
    test('returns user-facing message from toString', () {
      const failure = GoogleSignInFailure('Google sign-in failed.');

      expect(failure.message, 'Google sign-in failed.');
      expect(failure.toString(), 'Google sign-in failed.');
    });
  });

  group('sign-in cancellation mapping', () {
    test('treats Firebase popup cancellation codes as cancellation', () {
      for (final code in const [
        'canceled',
        'cancelled',
        'popup-closed-by-user',
        'web-context-cancelled',
      ]) {
        expect(
          FirebaseAuthService.isGoogleSignInCancellation(
            FirebaseAuthException(code: code),
          ),
          isTrue,
          reason: code,
        );
      }
    });

    test('does not treat non-cancellation auth errors as cancellation', () {
      expect(
        FirebaseAuthService.isGoogleSignInCancellation(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        isFalse,
      );
    });
  });

  group('AccountDeletionResult', () {
    test('represents successful deletion', () {
      const result = AccountDeletionResult.success();

      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(result.message, isNull);
      expect(result.requiresReauthentication, isFalse);
    });

    test('surfaces reauthentication failures with a user-facing message', () {
      final result = AccountDeletionResult.failure(
        AccountDeletionFailure.requiresRecentLogin,
      );

      expect(result.success, isFalse);
      expect(result.failure, AccountDeletionFailure.requiresRecentLogin);
      expect(result.requiresReauthentication, isTrue);
      expect(
        result.message,
        'Please sign in again before deleting your account.',
      );
    });
  });
}
