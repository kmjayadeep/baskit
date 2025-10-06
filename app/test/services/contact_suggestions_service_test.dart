import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/contact_suggestions_service.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/list_member_model.dart';

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
          memberDetails: members,
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
        // Test empty lists and lists without memberDetails
        final emptyLists = [
          ShoppingList(
            id: 'empty',
            name: 'Empty List',
            description: 'No members',
            color: '#FF0000',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            memberDetails: null,
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
