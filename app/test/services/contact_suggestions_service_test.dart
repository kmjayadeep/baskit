import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/contact_suggestion_model.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/share_result.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/services/contact_suggestions_service.dart';

class FakeShoppingRepository implements ShoppingRepository {
  FakeShoppingRepository(this.listsStream);

  final Stream<List<ShoppingList>> listsStream;
  int watchListsCalls = 0;

  @override
  Stream<List<ShoppingList>> watchLists() {
    watchListsCalls += 1;
    return listsStream;
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) =>
      throw UnimplementedError();

  @override
  Future<bool> clearCompleted(String listId) => throw UnimplementedError();

  @override
  Future<bool> createList(ShoppingList list) => throw UnimplementedError();

  @override
  Future<bool> deleteItem(String listId, String itemId) =>
      throw UnimplementedError();

  @override
  Future<bool> deleteList(String id) => throw UnimplementedError();

  @override
  void dispose() {}

  @override
  void disposeListStream(String id) {}

  @override
  Future<DateTime?> getLastSyncTime() => throw UnimplementedError();

  @override
  Future<void> init() => throw UnimplementedError();

  @override
  Future<bool> removeMember(String listId, String userId) =>
      throw UnimplementedError();

  @override
  Future<ShareResult> shareList(String listId, String email) =>
      throw UnimplementedError();

  @override
  Future<void> sync() => throw UnimplementedError();

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) => throw UnimplementedError();

  @override
  Future<bool> updateList(ShoppingList list) => throw UnimplementedError();

  @override
  Stream<ShoppingList?> watchList(String id) => throw UnimplementedError();
}

void main() {
  group('ContactSuggestionsService', () {
    setUp(() {
      ContactSuggestionsService.clearCache();
    });

    test('should handle cache operations', () async {
      // Test cache clearing and refresh work without error
      expect(() => ContactSuggestionsService.clearCache(), returnsNormally);
      await expectLater(
        ContactSuggestionsService.refreshContactCache('test_user'),
        completes,
      );
    });

    test('streams contacts from the injected shopping repository', () async {
      final controller = StreamController<List<ShoppingList>>();
      final repository = FakeShoppingRepository(controller.stream);
      addTearDown(controller.close);

      final contactsFuture = ContactSuggestionsService.getUserContacts(
        'current_user',
        repository,
      ).first;

      controller.add([
        ShoppingList(
          id: 'shared-list',
          name: 'Shared List',
          description: 'Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          members: [
            ListMember(
              userId: 'current_user',
              displayName: 'Current User',
              email: 'current@test.com',
              role: MemberRole.owner,
              joinedAt: DateTime.now(),
              permissions: const {'read': true, 'write': true},
            ),
            ListMember(
              userId: 'member_user',
              displayName: 'Member User',
              email: 'member@test.com',
              role: MemberRole.member,
              joinedAt: DateTime.now(),
              permissions: const {'read': true, 'write': true},
            ),
          ],
        ),
      ]);

      final contacts = await contactsFuture;

      expect(repository.watchListsCalls, equals(1));
      expect(contacts, hasLength(1));
      expect(contacts.single, isA<ContactSuggestion>());
      expect(contacts.single.userId, equals('member_user'));
      expect(contacts.single.email, equals('member@test.com'));
    });

    group('extractContactsFromLists', () {
      final currentUserId = 'current_user';

      // Helper to create test members
      ListMember createMember(String userId, String name, String? email) {
        return ListMember(
          userId: userId,
          displayName: name,
          email: email,
          role: MemberRole.member,
          joinedAt: DateTime.now(),
          permissions: const {'read': true, 'write': true},
        );
      }

      // Helper to create test lists
      ShoppingList createList(String id, List<ListMember> members) {
        return ShoppingList(
          id: id,
          name: 'Test List $id',
          description: 'Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          members: members,
        );
      }

      test(
        'should extract, filter, and deduplicate contacts correctly',
        () async {
          // Test multiple scenarios in one comprehensive test
          final members = [
            createMember(
              currentUserId,
              'Current User',
              'current@test.com',
            ), // Should be excluded
            createMember('user1', 'John Doe', 'john@test.com'),
            createMember('user2', 'Jane Smith', 'jane@test.com'),
            createMember('user3', 'No Email User', null), // Should be excluded
          ];

          final sharedMember = createMember(
            'shared_user',
            'Shared User',
            'shared@test.com',
          );

          final lists = [
            createList('list1', members),
            createList('list2', [sharedMember]), // Test deduplication
            createList('list3', [sharedMember]), // Same user in multiple lists
          ];

          final contacts =
              await ContactSuggestionsService.extractContactsFromLists(
                lists,
                currentUserId,
              );

          // Verify results
          expect(
            contacts.length,
            3,
          ); // john, jane, shared (current user and no-email excluded)

          // Check alphabetical sorting
          expect(contacts[0].displayName, 'Jane Smith');
          expect(contacts[1].displayName, 'John Doe');
          expect(contacts[2].displayName, 'Shared User');

          // Check shared list counting (deduplication)
          final sharedContact = contacts.firstWhere(
            (c) => c.userId == 'shared_user',
          );
          expect(
            sharedContact.sharedListsCount,
            2,
          ); // Appears in list2 and list3

          // Check single list contacts
          expect(contacts[0].sharedListsCount, 1);
          expect(contacts[1].sharedListsCount, 1);
        },
      );

      test('should handle edge cases', () async {
        // Test empty lists and lists without members
        final emptyLists = [
          ShoppingList(
            id: 'empty',
            name: 'Empty List',
            description: 'No members',
            color: '#FF0000',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final contacts =
            await ContactSuggestionsService.extractContactsFromLists(
              emptyLists,
              currentUserId,
            );

        expect(contacts, isEmpty);
      });
    });
  });
}
