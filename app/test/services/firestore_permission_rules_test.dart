import 'package:baskit/services/firestore_permission_rules.dart';
import 'package:baskit/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestorePermissionRules', () {
    final listData = <String, dynamic>{
      'ownerId': 'owner-1',
      'members': {
        'owner-1': {
          'role': 'owner',
          'permissions': {
            'read': false,
            'write': false,
            'delete': false,
            'share': false,
          },
        },
        'member-1': {
          'role': 'member',
          'permissions': {'read': true, 'write': true, 'share': true},
        },
        'member-2': {
          'role': 'member',
          'permissions': {'read': true},
        },
        'member-3': {
          'role': 'member',
          'permissions': {},
        },
      },
    };

    group('hasPermission', () {
      test('returns true for owner regardless of permissions', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'owner-1',
            ListPermission.read,
          ),
          isTrue,
        );
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'owner-1',
            ListPermission.deleteItems,
          ),
          isTrue,
        );
      });

      test('returns true when member has matching permission', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-1',
            ListPermission.read,
          ),
          isTrue,
        );
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-1',
            ListPermission.write,
          ),
          isTrue,
        );
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-1',
            ListPermission.share,
          ),
          isTrue,
        );
      });

      test('returns false when member lacks permission', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-2',
            ListPermission.write,
          ),
          isFalse,
        );
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-3',
            ListPermission.read,
          ),
          isFalse,
        );
      });

      test('returns false for non-member', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'non-member',
            ListPermission.read,
          ),
          isFalse,
        );
      });

      test('returns false for member without permissions map', () {
        final dataWithoutPermissions = <String, dynamic>{
          'ownerId': 'owner-1',
          'members': {
            'member-4': {'role': 'member'},
          },
        };
        expect(
          FirestorePermissionRules.hasPermission(
            dataWithoutPermissions,
            'member-4',
            ListPermission.read,
          ),
          isFalse,
        );
      });

      test('supports string permission', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-1',
            'read',
          ),
          isTrue,
        );
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-2',
            'write',
          ),
          isFalse,
        );
      });

      test('returns false for unknown permission type', () {
        expect(
          FirestorePermissionRules.hasPermission(
            listData,
            'member-1',
            123,
          ),
          isFalse,
        );
      });

      test('handles empty members map', () {
        final dataNoMembers = <String, dynamic>{
          'ownerId': 'owner-1',
          'members': <String, dynamic>{},
        };
        expect(
          FirestorePermissionRules.hasPermission(
            dataNoMembers,
            'member-1',
            ListPermission.read,
          ),
          isFalse,
        );
      });

      test('handles missing members key', () {
        final dataNoMembersKey = <String, dynamic>{
          'ownerId': 'owner-1',
        };
        expect(
          FirestorePermissionRules.hasPermission(
            dataNoMembersKey,
            'member-1',
            ListPermission.read,
          ),
          isFalse,
        );
      });
    });

    group('canRemoveMember', () {
      test('returns false when removing the owner', () {
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'owner-1',
            'owner-1',
          ),
          isFalse,
        );
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'member-1',
            'owner-1',
          ),
          isFalse,
        );
      });

      test('returns true when a member removes themselves', () {
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'member-1',
            'member-1',
          ),
          isTrue,
        );
      });

      test('returns true when owner removes a member', () {
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'owner-1',
            'member-1',
          ),
          isTrue,
        );
      });

      test('returns true when owner removes another member', () {
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'owner-1',
            'member-3',
          ),
          isTrue,
        );
      });

      test('returns false when a member tries to remove another member', () {
        expect(
          FirestorePermissionRules.canRemoveMember(
            listData,
            'member-1',
            'member-2',
          ),
          isFalse,
        );
      });

      test('uses manageMembers permission for non-owner members', () {
        final dataWithManage = <String, dynamic>{
          'ownerId': 'owner-1',
          'members': {
            'owner-1': {'role': 'owner', 'permissions': {}},
            'member-1': {
              'role': 'member',
              'permissions': {'manageMembers': true},
            },
            'member-2': {
              'role': 'member',
              'permissions': {},
            },
          },
        };
        expect(
          FirestorePermissionRules.canRemoveMember(
            dataWithManage,
            'member-1',
            'member-2',
          ),
          isTrue,
        );
      });
    });
  });
}
