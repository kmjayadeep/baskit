import 'package:baskit/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreService permission helpers', () {
    const ownerId = 'owner-1';
    const memberId = 'member-1';
    const limitedMemberId = 'member-2';

    final listData = <String, dynamic>{
      'ownerId': ownerId,
      'members': {
        ownerId: {
          'role': 'owner',
          'permissions': {
            'read': false,
            'write': false,
            'delete': false,
            'share': false,
          },
        },
        memberId: {
          'role': 'member',
          'permissions': {'read': true, 'write': true, 'share': true},
        },
        limitedMemberId: {
          'role': 'member',
          'permissions': {'read': true},
        },
      },
    };

    test('treats list owners as having all list permissions', () {
      expect(
        FirestoreService.hasListPermissionInDataForTest(
          listData,
          ownerId,
          'share',
        ),
        isTrue,
      );
    });

    test('uses granular permissions for non-owner members', () {
      expect(
        FirestoreService.hasListPermissionInDataForTest(
          listData,
          memberId,
          'write',
        ),
        isTrue,
      );
      expect(
        FirestoreService.hasListPermissionInDataForTest(
          listData,
          limitedMemberId,
          'write',
        ),
        isFalse,
      );
    });

    test('allows members to remove themselves but not other members', () {
      expect(
        FirestoreService.canRemoveMemberForTest(listData, memberId, memberId),
        isTrue,
      );
      expect(
        FirestoreService.canRemoveMemberForTest(
          listData,
          memberId,
          limitedMemberId,
        ),
        isFalse,
      );
    });

    test('allows owners to remove members but never the owner', () {
      expect(
        FirestoreService.canRemoveMemberForTest(listData, ownerId, memberId),
        isTrue,
      );
      expect(
        FirestoreService.canRemoveMemberForTest(listData, ownerId, ownerId),
        isFalse,
      );
    });
  });
}
