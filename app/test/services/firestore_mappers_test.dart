import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/services/firestore_mappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void _expectSameMoment(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(actual!.isAtSameMomentAs(expected), isTrue);
}

void main() {
  group('FirestoreMappers.membersFromData', () {
    test('returns an empty list when members data is missing or null', () {
      expect(FirestoreMappers.membersFromData({}), isEmpty);
      expect(FirestoreMappers.membersFromData({'members': null}), isEmpty);
    });

    test(
      'converts member maps, applies defaults, and ignores invalid entries',
      () {
        final ownerJoinedAt = DateTime.utc(2024, 1, 2, 3, 4, 5);
        final memberJoinedAt = DateTime.utc(2024, 2, 3, 4, 5, 6);

        final members = FirestoreMappers.membersFromData({
          'members': <String, dynamic>{
            'owner-1': <String, dynamic>{
              'displayName': 'Owner One',
              'email': 'owner@example.com',
              'avatarUrl': 'https://example.com/owner.png',
              'role': 'owner',
              'joinedAt': Timestamp.fromDate(ownerJoinedAt),
              'isActive': false,
              'permissions': <String, dynamic>{
                'read': true,
                'write': false,
                'delete': 'ignored',
              },
            },
            'member-1': <String, dynamic>{
              'role': 'unexpected-role',
              'joinedAt': memberJoinedAt.toIso8601String(),
              'permissions': <String, dynamic>{'share': true},
            },
            'invalid-entry': 'not-a-member-map',
          },
        });

        expect(members, hasLength(2));

        final owner = members.singleWhere(
          (member) => member.userId == 'owner-1',
        );
        expect(owner.displayName, 'Owner One');
        expect(owner.email, 'owner@example.com');
        expect(owner.avatarUrl, 'https://example.com/owner.png');
        expect(owner.role, MemberRole.owner);
        _expectSameMoment(owner.joinedAt, ownerJoinedAt);
        expect(owner.isActive, isFalse);
        expect(owner.permissions, {'read': true, 'write': false});

        final member = members.singleWhere(
          (member) => member.userId == 'member-1',
        );
        expect(member.displayName, 'Unknown User');
        expect(member.email, isNull);
        expect(member.avatarUrl, isNull);
        expect(member.role, MemberRole.member);
        _expectSameMoment(member.joinedAt, memberJoinedAt);
        expect(member.isActive, isTrue);
        expect(member.permissions, {'share': true});
      },
    );
  });

  group('FirestoreMappers.itemFromData', () {
    test('converts item fields from Firestore data', () {
      final createdAt = DateTime.utc(2024, 3, 4, 5, 6, 7);
      final completedAt = DateTime.utc(2024, 3, 5, 6, 7, 8);

      final item = FirestoreMappers.itemFromData('item-1', {
        'name': 'Milk',
        'quantity': 2,
        'completed': true,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': Timestamp.fromDate(completedAt),
      });

      expect(item.id, 'item-1');
      expect(item.name, 'Milk');
      expect(item.quantity, '2');
      expect(item.isCompleted, isTrue);
      _expectSameMoment(item.createdAt, createdAt);
      _expectSameMoment(item.completedAt, completedAt);
    });

    test('applies defaults when optional item fields are absent', () {
      final before = DateTime.now();
      final item = FirestoreMappers.itemFromData('item-2', {});
      final after = DateTime.now();

      expect(item.id, 'item-2');
      expect(item.name, '');
      expect(item.quantity, isNull);
      expect(item.isCompleted, isFalse);
      expect(item.completedAt, isNull);
      expect(item.createdAt.isBefore(before), isFalse);
      expect(item.createdAt.isAfter(after), isFalse);
    });
  });

  group('FirestoreMappers.listFromData', () {
    test(
      'converts list fields, items, owner, and members from Firestore data',
      () {
        final createdAt = DateTime.utc(2024, 4, 5, 6, 7, 8);
        final updatedAt = DateTime.utc(2024, 4, 6, 7, 8, 9);
        final memberJoinedAt = DateTime.utc(2024, 4, 7, 8, 9, 10);
        final items = [
          ShoppingItem(
            id: 'item-1',
            name: 'Bread',
            createdAt: DateTime.utc(2024, 4, 1),
          ),
        ];

        final list = FirestoreMappers.listFromData(
          id: 'list-1',
          data: {
            'name': 'Groceries',
            'description': 'Weekly shop',
            'color': '#FF0000',
            'createdAt': Timestamp.fromDate(createdAt),
            'updatedAt': Timestamp.fromDate(updatedAt),
            'ownerId': 'owner-1',
            'members': <String, dynamic>{
              'owner-1': <String, dynamic>{
                'displayName': 'Owner One',
                'role': 'owner',
                'joinedAt': Timestamp.fromDate(memberJoinedAt),
              },
            },
          },
          items: items,
        );

        expect(list.id, 'list-1');
        expect(list.name, 'Groceries');
        expect(list.description, 'Weekly shop');
        expect(list.color, '#FF0000');
        _expectSameMoment(list.createdAt, createdAt);
        _expectSameMoment(list.updatedAt, updatedAt);
        expect(list.items, same(items));
        expect(list.ownerId, 'owner-1');
        expect(list.members, hasLength(1));
        expect(list.members.single.userId, 'owner-1');
        expect(list.members.single.role, MemberRole.owner);
        _expectSameMoment(list.members.single.joinedAt, memberJoinedAt);
      },
    );

    test('applies defaults when optional list fields are absent', () {
      final before = DateTime.now();
      final list = FirestoreMappers.listFromData(
        id: 'list-2',
        data: {},
        items: const [],
      );
      final after = DateTime.now();

      expect(list.id, 'list-2');
      expect(list.name, 'Unnamed List');
      expect(list.description, '');
      expect(list.color, '#2196F3');
      expect(list.items, isEmpty);
      expect(list.ownerId, isNull);
      expect(list.members, isEmpty);
      expect(list.createdAt.isBefore(before), isFalse);
      expect(list.createdAt.isAfter(after), isFalse);
      expect(list.updatedAt.isBefore(before), isFalse);
      expect(list.updatedAt.isAfter(after), isFalse);
    });
  });
}
