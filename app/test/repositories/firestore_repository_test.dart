import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baskit/repositories/firestore_repository.dart';

void main() {
  group('FirestoreRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreRepository firestoreRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreRepository = FirestoreRepository(firestore: fakeFirestore);
    });

    group('DocumentSnapshot Conversion', () {
      test(
        'documentToShoppingList should convert valid document with items',
        () async {
          // Arrange - Set up fake Firestore data
          final listId = 'test-list-id';
          final now = DateTime.now();

          // Create list document
          await fakeFirestore.collection('lists').doc(listId).set({
            'name': 'Test Shopping List',
            'description': 'Test Description',
            'color': '#FF0000',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'members': {
              'user1': {
                'userId': 'user1',
                'displayName': 'Test User',
                'email': 'test@example.com',
              },
              'current-user': {
                'userId': 'current-user',
                'displayName': 'Current User',
                'email': 'current@example.com',
              },
            },
          });

          // Add items to the list
          await fakeFirestore
              .collection('lists')
              .doc(listId)
              .collection('items')
              .add({
                'name': 'Test Item 1',
                'quantity': '2',
                'completed': false,
                'createdAt': Timestamp.fromDate(now),
              });

          await fakeFirestore
              .collection('lists')
              .doc(listId)
              .collection('items')
              .add({
                'name': 'Test Item 2',
                'quantity': '1',
                'completed': true,
                'createdAt': Timestamp.fromDate(
                  now.add(const Duration(minutes: 1)),
                ),
                'completedAt': Timestamp.fromDate(
                  now.add(const Duration(minutes: 5)),
                ),
              });

          // Get the document
          final doc = await fakeFirestore.collection('lists').doc(listId).get();

          // Act
          final result = await firestoreRepository.documentToShoppingList(doc);

          // Assert
          expect(result.id, equals(listId));
          expect(result.name, equals('Test Shopping List'));
          expect(result.description, equals('Test Description'));
          expect(result.color, equals('#FF0000'));
          expect(result.createdAt, equals(now));
          expect(result.updatedAt, equals(now));
          expect(result.items.length, equals(2));
          expect(
            result.members.length,
            equals(2),
          ); // Both members in fake firestore
          expect(result.members, containsAll(['Test User', 'Current User']));

          // Check items
          expect(result.items[0].name, equals('Test Item 1'));
          expect(result.items[0].quantity, equals('2'));
          expect(result.items[0].isCompleted, isFalse);

          expect(result.items[1].name, equals('Test Item 2'));
          expect(result.items[1].quantity, equals('1'));
          expect(result.items[1].isCompleted, isTrue);
          expect(result.items[1].completedAt, isNotNull);
        },
      );

      test(
        'documentToShoppingList should handle missing fields gracefully',
        () async {
          // Arrange - Minimal document data
          final listId = 'minimal-list';
          await fakeFirestore.collection('lists').doc(listId).set({
            // Only minimal fields
          });

          final doc = await fakeFirestore.collection('lists').doc(listId).get();

          // Act
          final result = await firestoreRepository.documentToShoppingList(doc);

          // Assert - Should use fallback values
          expect(result.id, equals(listId));
          expect(result.name, equals('Unnamed List'));
          expect(result.description, equals(''));
          expect(result.color, equals('#2196F3'));
          expect(result.createdAt, isA<DateTime>());
          expect(result.updatedAt, isA<DateTime>());
          expect(result.items, isEmpty);
          expect(result.members, isEmpty);
        },
      );

      test(
        'documentToShoppingList should throw for non-existent document',
        () async {
          // Arrange
          final doc =
              await fakeFirestore.collection('lists').doc('non-existent').get();

          // Act & Assert
          expect(
            () async => await firestoreRepository.documentToShoppingList(doc),
            throwsA(
              isA<FirestoreRepositoryException>().having(
                (e) => e.message,
                'message',
                contains('Failed to convert document to ShoppingList'),
              ),
            ),
          );
        },
      );

      test(
        'documentToShoppingItem should convert valid item document',
        () async {
          // Arrange
          final now = DateTime.now();
          final completedAt = now.add(const Duration(hours: 1));

          await fakeFirestore.collection('items').doc('test-item').set({
            'name': 'Test Item',
            'quantity': '3',
            'completed': true,
            'createdAt': Timestamp.fromDate(now),
            'completedAt': Timestamp.fromDate(completedAt),
          });

          final doc =
              await fakeFirestore.collection('items').doc('test-item').get();

          // Act
          final result = firestoreRepository.documentToShoppingItem(doc);

          // Assert
          expect(result.id, equals('test-item'));
          expect(result.name, equals('Test Item'));
          expect(result.quantity, equals('3'));
          expect(result.isCompleted, isTrue);
          expect(result.createdAt, equals(now));
          expect(result.completedAt, equals(completedAt));
        },
      );

      test('documentToShoppingItem should handle missing fields', () async {
        // Arrange
        await fakeFirestore.collection('items').doc('basic-item').set({
          'name': 'Basic Item',
          // Missing other fields
        });

        final doc =
            await fakeFirestore.collection('items').doc('basic-item').get();

        // Act
        final result = firestoreRepository.documentToShoppingItem(doc);

        // Assert
        expect(result.id, equals('basic-item'));
        expect(result.name, equals('Basic Item'));
        expect(result.quantity, isNull);
        expect(result.isCompleted, isFalse);
        expect(result.createdAt, isA<DateTime>());
        expect(result.completedAt, isNull);
      });

      test(
        'documentToShoppingItem should throw for non-existent document',
        () async {
          // Arrange
          final doc =
              await fakeFirestore.collection('items').doc('missing').get();

          // Act & Assert
          expect(
            () => firestoreRepository.documentToShoppingItem(doc),
            throwsA(
              isA<FirestoreRepositoryException>().having(
                (e) => e.message,
                'message',
                contains('Failed to convert document to ShoppingItem'),
              ),
            ),
          );
        },
      );
    });

    group('Query Execution with Real Firestore Operations', () {
      test(
        'executeListsQuery should return lists for authenticated user',
        () async {
          // Arrange - Create test data
          final userId = 'test-user-123';
          final now = DateTime.now();

          // List 1 - User is member
          await fakeFirestore.collection('lists').doc('list1').set({
            'name': 'User List 1',
            'description': 'First list',
            'color': '#FF0000',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'memberIds': [userId, 'other-user'],
            'members': {
              userId: {
                'userId': userId,
                'displayName': 'Test User',
                'role': 'owner',
              },
              'other-user': {
                'userId': 'other-user',
                'displayName': 'Other User',
                'role': 'member',
              },
            },
          });

          // List 2 - User is NOT member (should be excluded)
          await fakeFirestore.collection('lists').doc('list2').set({
            'name': 'Other List',
            'description': 'Not user list',
            'color': '#00FF00',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'memberIds': ['other-user'],
            'members': {},
          });

          // List 3 - User is member
          await fakeFirestore.collection('lists').doc('list3').set({
            'name': 'User List 2',
            'description': 'Second list',
            'color': '#0000FF',
            'createdAt': Timestamp.fromDate(
              now.subtract(const Duration(hours: 1)),
            ),
            'updatedAt': Timestamp.fromDate(
              now.subtract(const Duration(hours: 1)),
            ),
            'memberIds': [userId],
            'members': {
              userId: {
                'userId': userId,
                'displayName': 'Test User',
                'role': 'owner',
              },
            },
          });

          // Act - Now this will use the fake firestore!
          final stream = firestoreRepository.executeListsQuery(userId: userId);
          final result = await stream.first;

          // Assert - Should return the 2 lists where user is a member
          expect(result.length, equals(2));
          expect(
            result.map((list) => list.name),
            containsAll(['User List 1', 'User List 2']),
          );
          // Should be ordered by updatedAt descending (newest first)
          expect(result.first.name, equals('User List 1')); // More recent
        },
      );

      test(
        'executeListQuery should return list when user has access',
        () async {
          // Arrange
          final userId = 'test-user';
          final listId = 'accessible-list';
          final now = DateTime.now();

          await fakeFirestore.collection('lists').doc(listId).set({
            'name': 'Accessible List',
            'description': 'User can access this',
            'color': '#00FF00',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'memberIds': [userId],
            'members': {
              userId: {
                'userId': userId,
                'displayName': 'Test User',
                'role': 'owner',
              },
            },
          });

          // Act
          final stream = firestoreRepository.executeListQuery(
            listId: listId,
            userId: userId,
          );
          final result = await stream.first;

          // Assert
          expect(result, isNotNull);
          expect(result!.name, equals('Accessible List'));
          expect(result.id, equals(listId));
        },
      );

      test(
        'executeListQuery should return null when user lacks access',
        () async {
          // Arrange
          final listId = 'private-list';
          final now = DateTime.now();

          await fakeFirestore.collection('lists').doc(listId).set({
            'name': 'Private List',
            'memberIds': ['other-user'], // Current user not included
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });

          // Act
          final stream = firestoreRepository.executeListQuery(
            listId: listId,
            userId: 'unauthorized-user',
          );
          final result = await stream.first;

          // Assert
          expect(result, isNull);
        },
      );

      test('executeItemsQuery should return items for a list', () async {
        // Arrange
        final listId = 'test-list';
        final now = DateTime.now();

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Item 1',
              'quantity': '1',
              'completed': false,
              'createdAt': Timestamp.fromDate(now),
            });

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Item 2',
              'quantity': '2',
              'completed': true,
              'createdAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 1)),
              ),
            });

        // Act
        final stream = firestoreRepository.executeItemsQuery(listId: listId);
        final result = await stream.first;

        // Assert
        expect(result.length, equals(2));
        expect(
          result.map((item) => item.name),
          containsAll(['Item 1', 'Item 2']),
        );
        // Should be ordered by createdAt ascending
        expect(result.first.name, equals('Item 1')); // Created first
      });
    });

    group('Validation Methods', () {
      test('validateUserAccess should return true for valid member', () async {
        // Arrange
        await fakeFirestore.collection('lists').doc('test-list').set({
          'memberIds': ['user1', 'user2', 'test-user-id'],
        });

        final doc =
            await fakeFirestore.collection('lists').doc('test-list').get();

        // Act
        final result = firestoreRepository.validateUserAccess(
          doc,
          'test-user-id',
        );

        // Assert
        expect(result, isTrue);
      });

      test('validateUserAccess should return false for non-member', () async {
        // Arrange
        await fakeFirestore.collection('lists').doc('test-list').set({
          'memberIds': ['user1', 'user2'],
        });

        final doc =
            await fakeFirestore.collection('lists').doc('test-list').get();

        // Act
        final result = firestoreRepository.validateUserAccess(
          doc,
          'non-member-id',
        );

        // Assert
        expect(result, isFalse);
      });

      test(
        'validateUserAccess should return false for non-existent document',
        () async {
          // Arrange
          final doc =
              await fakeFirestore.collection('lists').doc('missing').get();

          // Act
          final result = firestoreRepository.validateUserAccess(
            doc,
            'any-user-id',
          );

          // Assert
          expect(result, isFalse);
        },
      );

      test(
        'validateUserAccess should handle missing memberIds gracefully',
        () async {
          // Arrange
          await fakeFirestore.collection('lists').doc('test-list').set({
            // No memberIds field
            'name': 'Test List',
          });

          final doc =
              await fakeFirestore.collection('lists').doc('test-list').get();

          // Act
          final result = firestoreRepository.validateUserAccess(
            doc,
            'any-user-id',
          );

          // Assert
          expect(result, isFalse);
        },
      );
    });

    group('Error Handling', () {
      test('FirestoreRepositoryException should contain error details', () {
        // Arrange
        final originalError = Exception('Original error');

        // Act
        final exception = FirestoreRepositoryException(
          'Test error message',
          code: 'TEST_ERROR',
          originalError: originalError,
        );

        // Assert
        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_ERROR'));
        expect(exception.originalError, equals(originalError));
        expect(
          exception.toString(),
          equals('FirestoreRepositoryException: Test error message'),
        );
      });
    });

    group('Firebase Availability (Test Environment)', () {
      test('isFirebaseAvailable should return true in test mode', () {
        // Act - Using instance method now
        final result = firestoreRepository.isFirebaseAvailable;

        // Assert - In test mode with fake firestore, should return true
        expect(result, isTrue);
      });

      test('currentUserId should return null in test environment', () {
        // Act - Using instance method now
        final result = firestoreRepository.currentUserId;

        // Assert - No authenticated user in test environment
        expect(result, isNull);
      });
    });
  });
}
