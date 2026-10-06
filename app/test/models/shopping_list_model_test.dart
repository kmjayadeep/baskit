import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';

void main() {
  group('ShoppingList JSON compatibility', () {
    test('round-trips nested items and members', () {
      final now = DateTime.utc(2026, 1, 2);
      final item = ShoppingItem(
        id: 'item',
        name: 'Rice',
        createdAt: now,
        listItemType: ItemType.haveAtHome,
      );
      final member = ListMember(
        userId: 'owner',
        displayName: 'Owner',
        role: MemberRole.owner,
        joinedAt: now,
        permissions: {'read': true},
      );
      final list = ShoppingList(
        id: 'list',
        name: 'Pantry',
        description: 'Weekly',
        color: '#FFFFFF',
        createdAt: now,
        updatedAt: now,
        items: [item],
        ownerId: 'owner',
        members: [member],
      );
      final decoded = ShoppingList.fromJson(list.toJson());
      expect(decoded.id, list.id);
      expect(decoded.name, list.name);
      expect(decoded.createdAt, now);
      expect(decoded.updatedAt, now);
      expect(decoded.ownerId, 'owner');
      expect(decoded.items.single.listItemType, ItemType.haveAtHome);
      expect(decoded.members.single.role, MemberRole.owner);
    });

    test('defaults missing and invalid dates without losing nested data', () {
      final list = ShoppingList.fromJson({
        'createdAt': 'invalid',
        'updatedAt': 'invalid',
        'items': [
          <String, dynamic>{'name': 'Milk'},
        ],
        'members': [
          <String, dynamic>{'displayName': 'Member'},
        ],
      });
      expect(list.id, '');
      expect(list.name, 'Unnamed List');
      expect(list.description, '');
      expect(list.color, '#F59E0B');
      expect(list.createdAt, isA<DateTime>());
      expect(list.updatedAt, isA<DateTime>());
      expect(list.items.single.name, 'Milk');
      expect(list.members.single.displayName, 'Member');
      expect(ShoppingList.fromJson({}).items, isEmpty);
      expect(ShoppingList.fromJson({}).members, isEmpty);
    });
  });
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
      expect(list.sharedMemberCount, list.sharedMembers.length);
    });

    test('counts all members when the owner ID is absent', () {
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        role: MemberRole.member,
        joinedAt: DateTime.utc(2026, 1, 2),
        permissions: const {'read': true},
      );
      final list = ShoppingList(
        id: 'list-4',
        name: 'Shared list',
        description: '',
        color: '#FFFFFF',
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 2),
        members: [member],
      );

      expect(list.sharedMemberCount, 1);
      expect(list.sharedMemberCount, list.sharedMembers.length);
      expect(list.isShared, isTrue);
    });

    test('counts members when the owner is missing from the members map', () {
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        role: MemberRole.member,
        joinedAt: DateTime.utc(2026, 1, 2),
        permissions: const {'read': true},
      );
      final list = ShoppingList(
        id: 'list-5',
        name: 'Shared list',
        description: '',
        color: '#FFFFFF',
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 2),
        ownerId: 'missing-owner',
        members: [member],
      );

      expect(list.sharedMemberCount, 1);
      expect(list.sharedMemberCount, list.sharedMembers.length);
    });
  });
}
