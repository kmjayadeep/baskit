import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/contact_suggestions_service.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/list_member_model.dart';

void main() {
  group('ContactSuggestionsService', () {
    test('should throw UnimplementedError for getUserContacts', () {
      expect(
        () => ContactSuggestionsService.getUserContacts('test_user_id'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('should clear cache without error', () {
      expect(() => ContactSuggestionsService.clearCache(), returnsNormally);
    });

    test('should refresh cache without error', () async {
      await expectLater(
        ContactSuggestionsService.refreshContactCache('test_user_id'),
        completes,
      );
    });
  });

  group('_extractContactsFromLists', () {
    final currentUserId = 'current_user';

    // Helper method to create test shopping lists
    ShoppingList createTestList(String listId, List<ListMember> memberDetails) {
      return ShoppingList(
        id: listId,
        name: 'Test List',
        description: 'Test Description',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        memberDetails: memberDetails,
      );
    }

    // Helper method to create test members
    ListMember createTestMember({
      required String userId,
      required String displayName,
      String? email,
      String? avatarUrl,
    }) {
      return ListMember(
        userId: userId,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
    }

    test('should extract contacts from lists with memberDetails', () async {
      final member1 = createTestMember(
        userId: 'user1',
        displayName: 'John Doe',
        email: 'john@example.com',
      );
      final member2 = createTestMember(
        userId: 'user2',
        displayName: 'Jane Smith',
        email: 'jane@example.com',
      );

      final lists = [
        createTestList('list1', [member1, member2]),
      ];

      // Test the exposed method
      final contacts = await ContactSuggestionsService.extractContactsFromLists(
        lists,
        currentUserId,
      );

      expect(contacts.length, 2);
      expect(contacts[0].displayName, 'Jane Smith'); // Sorted alphabetically
      expect(contacts[0].email, 'jane@example.com');
      expect(contacts[0].sharedListsCount, 1);
      expect(contacts[1].displayName, 'John Doe');
      expect(contacts[1].email, 'john@example.com');
      expect(contacts[1].sharedListsCount, 1);
    });

    test('should exclude current user from suggestions', () async {
      final currentUserMember = createTestMember(
        userId: currentUserId,
        displayName: 'Current User',
        email: 'current@example.com',
      );
      final otherMember = createTestMember(
        userId: 'other_user',
        displayName: 'Other User',
        email: 'other@example.com',
      );

      final lists = [
        createTestList('list1', [currentUserMember, otherMember]),
      ];

      final contacts = await ContactSuggestionsService.extractContactsFromLists(
        lists,
        currentUserId,
      );

      expect(contacts.length, 1);
      expect(contacts[0].userId, 'other_user');
      expect(contacts[0].displayName, 'Other User');
    });

    test('should count shared lists correctly', () async {
      final member = createTestMember(
        userId: 'shared_user',
        displayName: 'Shared User',
        email: 'shared@example.com',
      );

      final lists = [
        createTestList('list1', [member]),
        createTestList('list2', [member]),
        createTestList('list3', [member]),
      ];

      final contacts = await ContactSuggestionsService.extractContactsFromLists(
        lists,
        currentUserId,
      );

      expect(contacts.length, 1);
      expect(contacts[0].sharedListsCount, 3);
    });

    test('should skip members without email', () async {
      final memberWithEmail = createTestMember(
        userId: 'user1',
        displayName: 'With Email',
        email: 'valid@example.com',
      );
      final memberWithoutEmail = createTestMember(
        userId: 'user2',
        displayName: 'Without Email',
        email: null,
      );

      final lists = [
        createTestList('list1', [memberWithEmail, memberWithoutEmail]),
      ];

      final contacts = await ContactSuggestionsService.extractContactsFromLists(
        lists,
        currentUserId,
      );

      expect(contacts.length, 1);
      expect(contacts[0].email, 'valid@example.com');
    });

    test('should return empty list for lists without memberDetails', () async {
      final lists = [
        ShoppingList(
          id: 'list1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          memberDetails: null, // No memberDetails
        ),
      ];

      final contacts = await ContactSuggestionsService.extractContactsFromLists(
        lists,
        currentUserId,
      );

      expect(contacts.isEmpty, true);
    });
  });
}
