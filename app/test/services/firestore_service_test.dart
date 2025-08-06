import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baskit/services/firestore_service.dart';
import 'package:baskit/repositories/firestore_repository.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

// Test wrapper class to allow dependency injection for FirestoreService
class TestableFirestoreService {
  final FirestoreRepository _firestoreRepository;

  TestableFirestoreService(this._firestoreRepository);

  // Wrapper methods that delegate to FirestoreRepository (like the real FirestoreService)
  Stream<List<ShoppingList>> getUserLists({required String userId}) {
    return _firestoreRepository.executeListsQuery(userId: userId);
  }

  Stream<ShoppingList?> getListById({
    required String listId,
    required String userId,
  }) {
    return _firestoreRepository.executeListQuery(
      listId: listId,
      userId: userId,
    );
  }

  Stream<List<ShoppingItem>> getListItems({required String listId}) {
    return _firestoreRepository.executeItemsQuery(listId: listId);
  }
}

void main() {
  group('FirestoreService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreRepository firestoreRepository;
    late TestableFirestoreService testableService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreRepository = FirestoreRepository(firestore: fakeFirestore);
      testableService = TestableFirestoreService(firestoreRepository);
    });

    group('User Lists Management', () {
      test(
        'getUserLists should return only lists where user is a member',
        () async {
          // Arrange
          final userId = 'test-user-123';
          final now = DateTime.now();

          // Create lists with different membership
          await fakeFirestore.collection('lists').doc('accessible-list-1').set({
            'name': 'My First List',
            'description': 'User has access',
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
            },
          });

          await fakeFirestore.collection('lists').doc('accessible-list-2').set({
            'name': 'My Second List',
            'description': 'User also has access',
            'color': '#00FF00',
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

          // List user should NOT see
          await fakeFirestore.collection('lists').doc('private-list').set({
            'name': 'Private List',
            'description': 'User has no access',
            'color': '#0000FF',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'memberIds': ['other-user'],
            'members': {
              'other-user': {
                'userId': 'other-user',
                'displayName': 'Other User',
                'role': 'owner',
              },
            },
          });

          // Act
          final stream = testableService.getUserLists(userId: userId);
          final result = await stream.first;

          // Assert
          expect(result.length, equals(2));
          expect(
            result.map((list) => list.name),
            containsAll(['My First List', 'My Second List']),
          );
          expect(
            result.map((list) => list.name),
            isNot(contains('Private List')),
          );

          // Verify ordering (updatedAt descending - newest first)
          expect(
            result.first.name,
            equals('My First List'),
          ); // More recent updatedAt
          expect(result.last.name, equals('My Second List')); // Older updatedAt
        },
      );

      test(
        'getUserLists should return empty list when user has no accessible lists',
        () async {
          // Arrange
          final userId = 'lonely-user';

          // Create lists that user cannot access
          await fakeFirestore.collection('lists').doc('other-list').set({
            'name': 'Other User List',
            'memberIds': ['different-user'],
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });

          // Act
          final stream = testableService.getUserLists(userId: userId);
          final result = await stream.first;

          // Assert
          expect(result, isEmpty);
        },
      );

      test('getUserLists should handle lists with items correctly', () async {
        // Arrange
        final userId = 'test-user';
        final listId = 'list-with-items';
        final now = DateTime.now();

        // Create list
        await fakeFirestore.collection('lists').doc(listId).set({
          'name': 'Shopping List',
          'description': 'Has some items',
          'color': '#FF0000',
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

        // Add items to the list
        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Milk',
              'quantity': '1 gallon',
              'completed': false,
              'createdAt': Timestamp.fromDate(now),
            });

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Bread',
              'quantity': '1 loaf',
              'completed': true,
              'createdAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 1)),
              ),
              'completedAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 10)),
              ),
            });

        // Act
        final stream = testableService.getUserLists(userId: userId);
        final result = await stream.first;

        // Assert
        expect(result.length, equals(1));
        final list = result.first;
        expect(list.name, equals('Shopping List'));
        expect(list.items.length, equals(2));
        expect(
          list.items.map((item) => item.name),
          containsAll(['Milk', 'Bread']),
        );

        // Check item properties
        final milkItem = list.items.firstWhere((item) => item.name == 'Milk');
        expect(milkItem.isCompleted, isFalse);
        expect(milkItem.completedAt, isNull);

        final breadItem = list.items.firstWhere((item) => item.name == 'Bread');
        expect(breadItem.isCompleted, isTrue);
        expect(breadItem.completedAt, isNotNull);
      });
    });

    group('Individual List Access', () {
      test('getListById should return list when user has access', () async {
        // Arrange
        final userId = 'authorized-user';
        final listId = 'accessible-list';
        final now = DateTime.now();

        await fakeFirestore.collection('lists').doc(listId).set({
          'name': 'Accessible List',
          'description': 'User can see this',
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
        final stream = testableService.getListById(
          listId: listId,
          userId: userId,
        );
        final result = await stream.first;

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(listId));
        expect(result.name, equals('Accessible List'));
        expect(result.description, equals('User can see this'));
        expect(result.color, equals('#00FF00'));
      });

      test('getListById should return null when user lacks access', () async {
        // Arrange
        final listId = 'private-list';
        final now = DateTime.now();

        await fakeFirestore.collection('lists').doc(listId).set({
          'name': 'Private List',
          'memberIds': ['owner-user'],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });

        // Act
        final stream = testableService.getListById(
          listId: listId,
          userId: 'unauthorized-user',
        );
        final result = await stream.first;

        // Assert
        expect(result, isNull);
      });

      test('getListById should return null for non-existent list', () async {
        // Act
        final stream = testableService.getListById(
          listId: 'does-not-exist',
          userId: 'any-user',
        );
        final result = await stream.first;

        // Assert
        expect(result, isNull);
      });
    });

    group('List Items Management', () {
      test('getListItems should return all items for a list', () async {
        // Arrange
        final listId = 'test-list';
        final now = DateTime.now();

        // Add multiple items with different properties
        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'First Item',
              'quantity': '1',
              'completed': false,
              'createdAt': Timestamp.fromDate(now),
            });

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Second Item',
              'quantity': '2 kg',
              'completed': true,
              'createdAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 1)),
              ),
              'completedAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 15)),
              ),
            });

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Third Item',
              'completed': false,
              'createdAt': Timestamp.fromDate(
                now.add(const Duration(minutes: 2)),
              ),
            });

        // Act
        final stream = testableService.getListItems(listId: listId);
        final result = await stream.first;

        // Assert
        expect(result.length, equals(3));
        expect(
          result.map((item) => item.name),
          containsAll(['First Item', 'Second Item', 'Third Item']),
        );

        // Verify ordering (by createdAt ascending)
        expect(result[0].name, equals('First Item'));
        expect(result[1].name, equals('Second Item'));
        expect(result[2].name, equals('Third Item'));

        // Verify item properties
        final completedItem = result.firstWhere(
          (item) => item.name == 'Second Item',
        );
        expect(completedItem.isCompleted, isTrue);
        expect(completedItem.quantity, equals('2 kg'));
        expect(completedItem.completedAt, isNotNull);

        final incompleteItem = result.firstWhere(
          (item) => item.name == 'Third Item',
        );
        expect(incompleteItem.isCompleted, isFalse);
        expect(incompleteItem.quantity, isNull);
        expect(incompleteItem.completedAt, isNull);
      });

      test(
        'getListItems should return empty list for list with no items',
        () async {
          // Act
          final stream = testableService.getListItems(listId: 'empty-list');
          final result = await stream.first;

          // Assert
          expect(result, isEmpty);
        },
      );

      test('getListItems should handle items with minimal data', () async {
        // Arrange
        final listId = 'minimal-items-list';

        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Minimal Item',
              // Missing quantity, completed, etc.
            });

        // Act
        final stream = testableService.getListItems(listId: listId);
        final result = await stream.first;

        // Assert
        expect(result.length, equals(1));
        final item = result.first;
        expect(item.name, equals('Minimal Item'));
        expect(item.quantity, isNull);
        expect(item.isCompleted, isFalse); // Default value
        expect(item.completedAt, isNull);
        expect(item.createdAt, isA<DateTime>()); // Fallback value
      });
    });

    group('Real-time Updates', () {
      test('getUserLists should emit updates when lists change', () async {
        // Arrange
        final userId = 'stream-user';
        final listId = 'dynamic-list';
        final now = DateTime.now();

        // Get stream and listen to it
        final stream = testableService.getUserLists(userId: userId);
        final results = <List<ShoppingList>>[];
        final subscription = stream.listen((data) => results.add(data));

        // Wait for initial empty result
        await Future.delayed(const Duration(milliseconds: 10));
        expect(results.length, greaterThan(0));
        expect(results.first, isEmpty);

        // Add a list
        await fakeFirestore.collection('lists').doc(listId).set({
          'name': 'New List',
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

        // Wait for the update
        await Future.delayed(const Duration(milliseconds: 10));
        expect(results.length, greaterThan(1));
        expect(results.last.length, equals(1));
        expect(results.last.first.name, equals('New List'));

        await subscription.cancel();
      });

      test('getListItems should emit updates when items change', () async {
        // Arrange
        final listId = 'live-list';
        final now = DateTime.now();

        // Get stream and listen to it
        final stream = testableService.getListItems(listId: listId);
        final results = <List<ShoppingItem>>[];
        final subscription = stream.listen((data) => results.add(data));

        // Wait for initial empty result
        await Future.delayed(const Duration(milliseconds: 10));
        expect(results.length, greaterThan(0));
        expect(results.first, isEmpty);

        // Add an item
        await fakeFirestore
            .collection('lists')
            .doc(listId)
            .collection('items')
            .add({
              'name': 'Live Item',
              'completed': false,
              'createdAt': Timestamp.fromDate(now),
            });

        // Wait for the update
        await Future.delayed(const Duration(milliseconds: 10));
        expect(results.length, greaterThan(1));
        expect(results.last.length, equals(1));
        expect(results.last.first.name, equals('Live Item'));

        await subscription.cancel();
      });
    });

    group('Static Service Methods (Firebase Unavailable)', () {
      // These test the actual static methods when Firebase is unavailable
      test(
        'getUserLists should return empty stream when Firebase unavailable',
        () async {
          // Act - Call actual static method (Firebase not initialized in tests)
          final stream = FirestoreService.getUserLists();
          final result = await stream.first;

          // Assert - Should return empty because no authenticated user
          expect(result, isEmpty);
        },
      );

      test(
        'getListById should return null when Firebase unavailable',
        () async {
          // Act - Call actual static method
          final stream = FirestoreService.getListById('test-list');
          final result = await stream.first;

          // Assert - Should return null because no authenticated user
          expect(result, isNull);
        },
      );

      test('getListItems should fail when Firebase unavailable', () async {
        // Act & Assert - Static service tries to access real Firebase which fails
        expect(
          () => FirestoreService.getListItems('test-list'),
          throwsA(anything), // Expect Firebase initialization error
        );
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

      test('Firebase availability should return false in test environment', () {
        // Act
        final result = FirestoreService.isFirebaseAvailable;

        // Assert - Firebase is not initialized in test environment
        expect(result, isFalse);
      });
    });
  });
}
