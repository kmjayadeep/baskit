import 'package:baskit/services/firestore_members_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreMembersService', () {
    group('shareListWithUser', () {
      test('returns false when Firebase unavailable', () async {
        final result =
            await FirestoreMembersService.shareListWithUser('list-1', 'user@test.com');
        expect(result, isFalse);
      });

      test('handles empty list ID', () async {
        final result =
            await FirestoreMembersService.shareListWithUser('', 'user@test.com');
        expect(result, isFalse);
      });

      test('handles empty email', () async {
        final result =
            await FirestoreMembersService.shareListWithUser('list-1', '');
        expect(result, isFalse);
      });

      test('handles invalid email format', () async {
        final result = await FirestoreMembersService.shareListWithUser(
          'list-1',
          'not-an-email',
        );
        expect(result, isFalse);
      });

      test('handles null-like email', () async {
        final result = await FirestoreMembersService.shareListWithUser(
          'list-1',
          '@',
        );
        expect(result, isFalse);
      });
    });

    group('removeMemberFromList', () {
      test('returns false when Firebase unavailable', () async {
        final result =
            await FirestoreMembersService.removeMemberFromList('list-1', 'user-1');
        expect(result, isFalse);
      });

      test('handles empty list ID', () async {
        final result =
            await FirestoreMembersService.removeMemberFromList('', 'user-1');
        expect(result, isFalse);
      });

      test('handles empty user ID', () async {
        final result =
            await FirestoreMembersService.removeMemberFromList('list-1', '');
        expect(result, isFalse);
      });

      test('handles very long IDs', () async {
        final longId = 'a' * 1000;
        final result = await FirestoreMembersService.removeMemberFromList(
          longId,
          longId,
        );
        expect(result, isFalse);
      });
    });

    group('hasListPermission', () {
      test('returns false when Firebase unavailable', () async {
        final result = await FirestoreMembersService.hasListPermission(
          'list-1',
          'read',
        );
        expect(result, isFalse);
      });

      test('handles permission as string', () async {
        final result = await FirestoreMembersService.hasListPermission(
          'list-1',
          'write',
        );
        expect(result, isFalse);
      });

      test('handles permission as enum', () async {
        final result = await FirestoreMembersService.hasListPermission(
          'list-1',
          ListPermission.read,
        );
        expect(result, isFalse);
      });

      test('handles permission as integer', () async {
        final result = await FirestoreMembersService.hasListPermission(
          'list-1',
          0,
        );
        expect(result, isFalse);
      });
    });
  });
}
