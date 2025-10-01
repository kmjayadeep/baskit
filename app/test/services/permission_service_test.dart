import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/permission_service.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';

void main() {
  group('PermissionService', () {
    // Test data
    final testOwner = ListMember(
      userId: 'owner_123',
      displayName: 'Owner User',
      email: 'owner@test.com',
      role: MemberRole.owner,
      joinedAt: DateTime.now(),
      permissions: const {
        'read': true,
        'write': true,
        'delete': true,
        'share': true,
      },
    );

    final testMemberWithFullPermissions = ListMember(
      userId: 'member_full_123',
      displayName: 'Full Member',
      email: 'full@test.com',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
      permissions: const {
        'read': true,
        'write': true,
        'delete': true,
        'share': true,
      },
    );

    final testMemberWithLimitedPermissions = ListMember(
      userId: 'member_limited_123',
      displayName: 'Limited Member',
      email: 'limited@test.com',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
      permissions: const {
        'read': true,
        'write': true,
        'delete': false,
        'share': false,
      },
    );

    final testViewerMember = ListMember(
      userId: 'viewer_123',
      displayName: 'Viewer Member',
      email: 'viewer@test.com',
      role: MemberRole.member,
      joinedAt: DateTime.now(),
      permissions: const {
        'read': true,
        'write': false,
        'delete': false,
        'share': false,
      },
    );

    final testListWithRichData = ShoppingList(
      id: 'list_123',
      name: 'Test List',
      description: 'Test Description',
      color: '#FF0000',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      members: ['owner@test.com', 'full@test.com'],
      ownerId: 'owner_123',
      memberDetails: [
        testOwner,
        testMemberWithFullPermissions,
        testMemberWithLimitedPermissions,
      ],
    );

    final testListLocalOnly = ShoppingList(
      id: 'local_123',
      name: 'Local List',
      description: 'Local Description',
      color: '#00FF00',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      members: [],
      ownerId: null,
      memberDetails: null, // No rich data
    );

    group('hasPermission', () {
      test(
        'owner role always has all permissions regardless of permissions map',
        () {
          // Even if permissions map says false, owner should have access
          final ownerWithFalsePermissions = ListMember(
            userId: 'owner_false_123',
            displayName: 'Owner with False Permissions',
            email: 'owner_false@test.com',
            role: MemberRole.owner,
            joinedAt: DateTime.now(),
            permissions: const {
              'read': false,
              'write': false,
              'delete': false,
              'share': false,
            },
          );

          expect(
            PermissionService.hasPermission(ownerWithFalsePermissions, 'read'),
            true,
          );
          expect(
            PermissionService.hasPermission(ownerWithFalsePermissions, 'write'),
            true,
          );
          expect(
            PermissionService.hasPermission(
              ownerWithFalsePermissions,
              'delete',
            ),
            true,
          );
          expect(
            PermissionService.hasPermission(ownerWithFalsePermissions, 'share'),
            true,
          );
        },
      );

      test('member role uses individual permissions from permissions map', () {
        expect(
          PermissionService.hasPermission(
            testMemberWithLimitedPermissions,
            'read',
          ),
          true,
        );
        expect(
          PermissionService.hasPermission(
            testMemberWithLimitedPermissions,
            'write',
          ),
          true,
        );
        expect(
          PermissionService.hasPermission(
            testMemberWithLimitedPermissions,
            'delete',
          ),
          false,
        );
        expect(
          PermissionService.hasPermission(
            testMemberWithLimitedPermissions,
            'share',
          ),
          false,
        );
      });

      test('returns false for permissions not in the map', () {
        expect(
          PermissionService.hasPermission(
            testMemberWithLimitedPermissions,
            'unknown',
          ),
          false,
        );
      });
    });

    group('convenience permission methods', () {
      group('canEditItems', () {
        test('returns true for owner regardless of write permission', () {
          expect(PermissionService.canEditItems(testOwner), true);
        });

        test('returns true for member with write permission', () {
          expect(
            PermissionService.canEditItems(testMemberWithLimitedPermissions),
            true,
          );
        });

        test('returns false for member without write permission', () {
          expect(PermissionService.canEditItems(testViewerMember), false);
        });
      });

      group('canDeleteItems', () {
        test('returns true for owner regardless of delete permission', () {
          expect(PermissionService.canDeleteItems(testOwner), true);
        });

        test('returns true for member with delete permission', () {
          expect(
            PermissionService.canDeleteItems(testMemberWithFullPermissions),
            true,
          );
        });

        test('returns false for member without delete permission', () {
          expect(
            PermissionService.canDeleteItems(testMemberWithLimitedPermissions),
            false,
          );
        });
      });

      group('canDeleteList', () {
        test('returns true only for owner role', () {
          expect(PermissionService.canDeleteList(testOwner), true);
          expect(
            PermissionService.canDeleteList(testMemberWithFullPermissions),
            false,
          );
          expect(
            PermissionService.canDeleteList(testMemberWithLimitedPermissions),
            false,
          );
        });
      });

      group('canManageMembers', () {
        test('returns true only for owner role', () {
          expect(PermissionService.canManageMembers(testOwner), true);
          expect(
            PermissionService.canManageMembers(testMemberWithFullPermissions),
            false,
          );
          expect(
            PermissionService.canManageMembers(
              testMemberWithLimitedPermissions,
            ),
            false,
          );
        });
      });

      group('canShareList', () {
        test('returns true for owner regardless of share permission', () {
          expect(PermissionService.canShareList(testOwner), true);
        });

        test('returns true for member with share permission', () {
          expect(
            PermissionService.canShareList(testMemberWithFullPermissions),
            true,
          );
        });

        test('returns false for member without share permission', () {
          expect(
            PermissionService.canShareList(testMemberWithLimitedPermissions),
            false,
          );
        });
      });

      group('canEditListMetadata', () {
        test('returns true for owner regardless of write permission', () {
          expect(PermissionService.canEditListMetadata(testOwner), true);
        });

        test('returns true for member with write permission', () {
          expect(
            PermissionService.canEditListMetadata(
              testMemberWithLimitedPermissions,
            ),
            true,
          );
        });

        test('returns false for member without write permission', () {
          expect(
            PermissionService.canEditListMetadata(testViewerMember),
            false,
          );
        });
      });

      group('canViewList', () {
        test('returns true for active member with read permission', () {
          expect(PermissionService.canViewList(testOwner), true);
          expect(
            PermissionService.canViewList(testMemberWithLimitedPermissions),
            true,
          );
        });

        test('returns false for inactive member', () {
          final inactiveMember = testMemberWithLimitedPermissions.copyWith(
            isActive: false,
          );
          expect(PermissionService.canViewList(inactiveMember), false);
        });

        test('returns false for member without read permission', () {
          final noReadMember = ListMember(
            userId: 'no_read_123',
            displayName: 'No Read Member',
            email: 'no_read@test.com',
            role: MemberRole.member,
            joinedAt: DateTime.now(),
            permissions: const {
              'read': false,
              'write': true,
              'delete': true,
              'share': true,
            },
          );
          expect(PermissionService.canViewList(noReadMember), false);
        });
      });
    });

    group('getCurrentUserMember', () {
      test('returns correct member when user exists in rich data', () {
        final member = PermissionService.getCurrentUserMember(
          testListWithRichData,
          'owner_123',
        );
        expect(member, isNotNull);
        expect(member!.userId, 'owner_123');
        expect(member.displayName, 'Owner User');
        expect(member.role, MemberRole.owner);
      });

      test('returns null when user not found in rich data', () {
        final member = PermissionService.getCurrentUserMember(
          testListWithRichData,
          'unknown_user',
        );
        expect(member, isNull);
      });

      test('returns null when list has no rich member data', () {
        final member = PermissionService.getCurrentUserMember(
          testListLocalOnly,
          'any_user',
        );
        expect(member, isNull);
      });

      test('returns null when currentUserId is null', () {
        final member = PermissionService.getCurrentUserMember(
          testListWithRichData,
          null,
        );
        expect(member, isNull);
      });
    });

    group('hasListPermission', () {
      group('with rich member data', () {
        test('uses granular permissions for known users', () {
          // Test owner
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'owner_123',
              'write',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'owner_123',
              'delete_list',
            ),
            true,
          );

          // Test limited member
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'member_limited_123',
              'write',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'member_limited_123',
              'delete',
            ),
            false,
          );
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'member_limited_123',
              'share',
            ),
            false,
          );
        });

        test('returns false for unknown permission types', () {
          expect(
            PermissionService.hasListPermission(
              testListWithRichData,
              'owner_123',
              'unknown',
            ),
            false,
          );
        });
      });

      group('local-only mode fallback', () {
        test('returns true for all permissions when no rich data', () {
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'read',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'write',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'delete',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'share',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'manage_members',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'edit_metadata',
            ),
            true,
          );
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              'any_user',
              'delete_list',
            ),
            true,
          );
        });

        test('returns true even for null userId in local mode', () {
          expect(
            PermissionService.hasListPermission(
              testListLocalOnly,
              null,
              'write',
            ),
            true,
          );
        });
      });
    });

    group('validatePermission', () {
      test('returns null when permission is granted', () {
        final result = PermissionService.validatePermission(
          testListWithRichData,
          'owner_123',
          'write',
        );
        expect(result, isNull);
      });

      test('returns error message when permission is denied', () {
        final result = PermissionService.validatePermission(
          testListWithRichData,
          'member_limited_123',
          'delete',
        );
        expect(result, isNotNull);
        expect(result, contains('don\'t have permission to delete items'));
      });

      test(
        'returns appropriate error messages for different permission types',
        () {
          expect(
            PermissionService.validatePermission(
              testListWithRichData,
              'member_limited_123',
              'share',
            ),
            contains('don\'t have permission to share'),
          );
          expect(
            PermissionService.validatePermission(
              testListWithRichData,
              'member_limited_123',
              'delete_list',
            ),
            contains('Only the list owner can delete'),
          );
          expect(
            PermissionService.validatePermission(
              testListWithRichData,
              'member_limited_123',
              'manage_members',
            ),
            contains('Only the list owner can manage members'),
          );
        },
      );

      test('returns null for all permissions in local-only mode', () {
        expect(
          PermissionService.validatePermission(
            testListLocalOnly,
            'any_user',
            'write',
          ),
          isNull,
        );
        expect(
          PermissionService.validatePermission(
            testListLocalOnly,
            'any_user',
            'delete_list',
          ),
          isNull,
        );
        expect(
          PermissionService.validatePermission(
            testListLocalOnly,
            'any_user',
            'manage_members',
          ),
          isNull,
        );
      });
    });

    group('getPermissionSummary', () {
      test('returns correct summary for member with full permissions', () {
        final summary = PermissionService.getPermissionSummary(
          testMemberWithFullPermissions,
        );
        expect(summary, contains('View'));
        expect(summary, contains('Edit items'));
        expect(summary, contains('Delete items'));
        expect(summary, contains('Share'));
      });

      test('returns correct summary for member with limited permissions', () {
        final summary = PermissionService.getPermissionSummary(
          testMemberWithLimitedPermissions,
        );
        expect(summary, contains('View'));
        expect(summary, contains('Edit items'));
        expect(summary, isNot(contains('Delete items')));
        expect(summary, isNot(contains('Share')));
      });

      test('returns "No permissions" for member with no permissions', () {
        final noPermissionsMember = ListMember(
          userId: 'no_perms_123',
          displayName: 'No Permissions',
          email: 'none@test.com',
          role: MemberRole.member,
          joinedAt: DateTime.now(),
          permissions: const {
            'read': false,
            'write': false,
            'delete': false,
            'share': false,
          },
        );
        final summary = PermissionService.getPermissionSummary(
          noPermissionsMember,
        );
        expect(summary, 'No permissions');
      });

      test('returns full permissions summary for owner', () {
        final summary = PermissionService.getPermissionSummary(testOwner);
        expect(summary, contains('View'));
        expect(summary, contains('Edit items'));
        expect(summary, contains('Delete items'));
        expect(summary, contains('Share'));
      });
    });

    group('edge cases', () {
      test('handles member with empty permissions map', () {
        final emptyPermissionsMember = ListMember(
          userId: 'empty_123',
          displayName: 'Empty Permissions',
          email: 'empty@test.com',
          role: MemberRole.member,
          joinedAt: DateTime.now(),
          permissions: const {},
        );

        expect(
          PermissionService.hasPermission(emptyPermissionsMember, 'read'),
          false,
        );
        expect(PermissionService.canEditItems(emptyPermissionsMember), false);
        expect(PermissionService.canViewList(emptyPermissionsMember), false);
      });

      test('handles list with empty memberDetails', () {
        final emptyMembersList = testListWithRichData.copyWith(
          memberDetails: [],
        );
        final member = PermissionService.getCurrentUserMember(
          emptyMembersList,
          'any_user',
        );
        expect(member, isNull);

        // Should fallback to local-only mode
        expect(
          PermissionService.hasListPermission(
            emptyMembersList,
            'any_user',
            'write',
          ),
          true,
        );
      });
    });
  });
}
