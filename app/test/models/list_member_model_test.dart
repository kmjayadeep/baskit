import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/list_member_model.dart';

void main() {
  group('ListMember JSON compatibility', () {
    test('round-trips role, joined date, and boolean permissions', () {
      final now = DateTime.utc(2026, 1, 2);
      final member = ListMember(
        userId: 'owner',
        displayName: 'Owner',
        email: 'owner@example.com',
        role: MemberRole.owner,
        joinedAt: now,
        permissions: {'read': true, 'share': false},
      );
      final parsed = ListMember.fromJsonSafe(member.toJson());
      expect(parsed.userId, member.userId);
      expect(parsed.displayName, member.displayName);
      expect(parsed.email, member.email);
      expect(parsed.joinedAt, now);
      expect(parsed.role, MemberRole.owner);
      expect(parsed.permissions, member.permissions);
    });

    test(
      'fromJson drops non-boolean permissions and handles invalid dates',
      () {
        final member = ListMember.fromJson({
          'userId': 'member-1',
          'joinedAt': 'invalid-date',
          'permissions': <String, dynamic>{'read': true, 'write': 'yes'},
        });
        expect(member.userId, 'member-1');
        expect(member.permissions, {'read': true});
        expect(member.joinedAt, isA<DateTime>());
      },
    );

    test(
      'defaults missing and invalid fields and drops non-bool permissions',
      () {
        final missing = ListMember.fromJson({});
        expect(missing.userId, '');
        expect(missing.displayName, 'Unknown User');
        expect(missing.role, MemberRole.member);
        expect(missing.joinedAt, isA<DateTime>());
        expect(missing.permissions, isEmpty);

        final malformed = ListMember.fromJsonSafe({
          'role': 'unexpected',
          'joinedAt': 'not-a-date',
          'permissions': <String, dynamic>{'read': true, 'write': 'yes'},
        });
        expect(malformed.role, MemberRole.member);
        expect(malformed.joinedAt, isA<DateTime>());
        expect(malformed.permissions, {'read': true});
      },
    );
  });
  group('ListMember.fromFirestore', () {
    test('parses joinedAt from Firestore Timestamp', () {
      final joinedAt = DateTime.utc(2024, 6, 1, 12, 30);

      final member = ListMember.fromFirestore('member-1', {
        'displayName': 'Member',
        'email': 'member@test.com',
        'role': 'member',
        'joinedAt': Timestamp.fromDate(joinedAt),
        'permissions': {'read': true, 'write': true},
      });

      expect(member.joinedAt.isAtSameMomentAs(joinedAt), isTrue);
    });

    test('continues to parse joinedAt from ISO strings', () {
      final joinedAt = DateTime.utc(2024, 6, 1, 12, 30);

      final member = ListMember.fromFirestore('member-1', {
        'displayName': 'Member',
        'role': 'member',
        'joinedAt': joinedAt.toIso8601String(),
        'permissions': {'read': true},
      });

      expect(member.joinedAt, joinedAt);
    });

    test('falls back to the current time for malformed Firestore dates', () {
      final before = DateTime.now();
      final member = ListMember.fromFirestore('member-1', {
        'joinedAt': 'invalid-date',
      });
      expect(member.joinedAt.isBefore(before), isFalse);
      expect(member.joinedAt.isAfter(DateTime.now()), isFalse);
    });
  });

  test(
    'fromJsonSafe accepts absent permissions and falls back on bad dates',
    () {
      final member = ListMember.fromJsonSafe({
        'userId': 'member-1',
        'joinedAt': 'invalid-date',
      });
      expect(member.userId, 'member-1');
      expect(member.permissions, isEmpty);
      expect(member.joinedAt, isA<DateTime>());
    },
  );
}
