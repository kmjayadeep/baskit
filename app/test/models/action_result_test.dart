import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/action_result.dart';

void main() {
  group('ActionResult', () {
    test('success creates a successful result', () {
      const result = ActionResult.success();

      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.requiresReauth, isFalse);
    });

    test('failure creates a failed result with message', () {
      const result = ActionResult.failure('Something went wrong');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Something went wrong');
      expect(result.requiresReauth, isFalse);
    });

    test('requiresReauth creates a failure with requiresReauth flag', () {
      const result = ActionResult.requiresReauth(
        'You need to sign in again',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'You need to sign in again');
      expect(result.requiresReauth, isTrue);
    });

    test('success does not have requiresReauth set', () {
      const result = ActionResult.success();

      expect(result.requiresReauth, isFalse);
    });

    test('failure does not have requiresReauth set', () {
      const result = ActionResult.failure('Error');

      expect(result.requiresReauth, isFalse);
    });
  });
}
