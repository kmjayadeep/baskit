import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/repositories/firestore_shopping_repository.dart';
import 'package:baskit/services/firestore_service.dart';

void main() {
  group('FirestoreShoppingRepository share error mapping', () {
    test('maps UserNotFoundException to explicit not-found message', () {
      final message = FirestoreShoppingRepository.mapShareErrorForTest(
        UserNotFoundException('missing@test.com'),
        'missing@test.com',
      );

      expect(message, contains('User with email missing@test.com not found.'));
      expect(
        message,
        contains('Make sure they have signed up for the app first'),
      );
    });

    test(
      'maps UserAlreadyMemberException to explicit already-member message',
      () {
        final message = FirestoreShoppingRepository.mapShareErrorForTest(
          UserAlreadyMemberException('Existing User'),
          'existing@test.com',
        );

        expect(message, equals('This user is already a member of this list.'));
      },
    );

    test('maps unknown errors to generic fallback message', () {
      final message = FirestoreShoppingRepository.mapShareErrorForTest(
        Exception('network timeout'),
        'fallback@test.com',
      );

      expect(message, contains('Unable to share list with fallback@test.com.'));
      expect(message, contains('Please make sure they have the app installed'));
    });
  });
}
