import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/firestore_service.dart';

void main() {
  group('FirestoreService Tests', () {
    group('Delegation to FirestoreLayer', () {
      test(
        'getUserLists should return empty stream when Firebase unavailable',
        () async {
          // Act
          final stream = FirestoreService.getUserLists();
          final result = await stream.first;

          // Assert - Should return empty because Firebase is not initialized in test
          expect(result, isEmpty);
        },
      );

      test('getListById should return null when Firebase unavailable', () async {
        // Act
        final stream = FirestoreService.getListById('test-list');
        final result = await stream.first;

        // Assert - Should return null because Firebase is not initialized in test
        expect(result, isNull);
      });

      test(
        'getListItems should return empty stream when Firebase unavailable',
        () async {
          // Act
          final stream = FirestoreService.getListItems('test-list');
          final result = await stream.first;

          // Assert - Should return empty because Firebase is not initialized in test
          expect(result, isEmpty);
        },
      );
    });

    group('Firebase Availability', () {
      test('isFirebaseAvailable should return false in test environment', () {
        // Act
        final result = FirestoreService.isFirebaseAvailable;

        // Assert - Firebase is not initialized in test environment
        expect(result, isFalse);
      });
    });

    group('Error Handling', () {
      test('custom exceptions should be properly defined', () {
        // Test UserNotFoundException
        final userNotFound = UserNotFoundException('test@example.com');
        expect(userNotFound.email, equals('test@example.com'));
        expect(userNotFound.toString(), contains('UserNotFoundException'));
        expect(userNotFound.toString(), contains('test@example.com'));

        // Test UserAlreadyMemberException
        final alreadyMember = UserAlreadyMemberException('Test User');
        expect(alreadyMember.userName, equals('Test User'));
        expect(
          alreadyMember.toString(),
          contains('UserAlreadyMemberException'),
        );
        expect(alreadyMember.toString(), contains('Test User'));
      });
    });
  });
}
