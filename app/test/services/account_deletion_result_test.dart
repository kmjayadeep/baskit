import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/account_deletion_result.dart';

void main() {
  group('AccountDeletionResult', () {
    test('maps requires-recent-login to a reauthentication result', () {
      final result = AccountDeletionResult.fromAuthException(
        FirebaseAuthException(code: 'requires-recent-login'),
      );

      expect(result.status, AccountDeletionStatus.requiresRecentLogin);
      expect(result.requiresReauthentication, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('maps user-cancelled reauthentication to cancelled result', () {
      for (final code in [
        'web-context-cancelled',
        'popup-closed-by-user',
        'canceled',
        'cancelled-popup-request',
      ]) {
        final result = AccountDeletionResult.fromAuthException(
          FirebaseAuthException(code: code),
        );

        expect(result.status, AccountDeletionStatus.reauthenticationCancelled);
        expect(result.message, contains('not deleted'));
      }
    });

    test(
      'maps unknown auth failures to generic failure without raw details',
      () {
        final result = AccountDeletionResult.fromAuthException(
          FirebaseAuthException(
            code: 'internal-error',
            message: 'raw provider details should not be shown',
          ),
        );

        expect(result.status, AccountDeletionStatus.failed);
        expect(result.message, isNot(contains('raw provider details')));
      },
    );
  });
}
