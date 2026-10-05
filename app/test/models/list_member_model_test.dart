import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/list_member_model.dart';

void main() {
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
  });
}
