import 'package:baskit/services/firestore_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreErrors', () {
    group('UserNotFoundException', () {
      test('stores email', () {
        final exception = UserNotFoundException('test@example.com');
        expect(exception.email, 'test@example.com');
      });

      test('toString includes email', () {
        final exception = UserNotFoundException('user@email.com');
        expect(
          exception.toString(),
          'UserNotFoundException: user@email.com',
        );
      });
    });

    group('UserAlreadyMemberException', () {
      test('stores userName', () {
        final exception = UserAlreadyMemberException('John Doe');
        expect(exception.userName, 'John Doe');
      });

      test('toString includes userName', () {
        final exception = UserAlreadyMemberException('Jane Smith');
        expect(
          exception.toString(),
          'UserAlreadyMemberException: Jane Smith',
        );
      });
    });
  });
}
