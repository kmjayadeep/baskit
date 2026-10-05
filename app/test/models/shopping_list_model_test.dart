import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';

void main() {
  group('ShoppingList.sharedMemberCount', () {
    test('clamps at zero for list with no members', () {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Groceries',
        description: 'weekly',
        color: '#FFFFFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        members: const [],
      );

      expect(list.sharedMemberCount, equals(0));
    });

    test('returns zero when only owner exists', () {
      final owner = ListMember(
        userId: 'owner-1',
        displayName: 'Owner',
        email: 'owner@test.com',
        role: MemberRole.owner,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true, 'share': true},
      );
      final list = ShoppingList(
        id: 'list-2',
        name: 'Groceries',
        description: 'weekly',
        color: '#FFFFFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner],
      );

      expect(list.sharedMemberCount, equals(0));
    });

    test('returns count excluding owner for shared lists', () {
      final owner = ListMember(
        userId: 'owner-1',
        displayName: 'Owner',
        email: 'owner@test.com',
        role: MemberRole.owner,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true, 'share': true},
      );
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
      final list = ShoppingList(
        id: 'list-3',
        name: 'Groceries',
        description: 'weekly',
        color: '#FFFFFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner, member],
      );

      expect(list.sharedMemberCount, equals(1));
    });
  });
}
