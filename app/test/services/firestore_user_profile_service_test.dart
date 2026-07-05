import 'package:baskit/services/firestore_user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreUserProfileService.updatedMemberProfileData', () {
    test('adds missing avatar URL from current user profile', () {
      final result = FirestoreUserProfileService.updatedMemberProfileData(
        {
          'role': 'member',
          'displayName': 'Jane Doe',
          'email': 'jane@example.com',
          'permissions': {'read': true},
        },
        displayName: 'Jane Doe',
        email: 'jane@example.com',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(result, isNotNull);
      expect(result!['avatarUrl'], 'https://example.com/avatar.png');
      expect(result['role'], 'member');
      expect(result['permissions'], {'read': true});
    });

    test('does not replace existing display name or email', () {
      final result = FirestoreUserProfileService.updatedMemberProfileData(
        {
          'displayName': 'Preferred Name',
          'email': 'old@example.com',
          'avatarUrl': 'https://example.com/old.png',
        },
        displayName: 'New Name',
        email: 'new@example.com',
        avatarUrl: 'https://example.com/new.png',
      );

      expect(result, isNotNull);
      expect(result!['displayName'], 'Preferred Name');
      expect(result['email'], 'old@example.com');
      expect(result['avatarUrl'], 'https://example.com/new.png');
    });

    test('fills placeholder display name and missing email', () {
      final result = FirestoreUserProfileService.updatedMemberProfileData(
        {'displayName': 'Unknown User', 'email': ''},
        displayName: 'Alex Smith',
        email: 'alex@example.com',
        avatarUrl: null,
      );

      expect(result, isNotNull);
      expect(result!['displayName'], 'Alex Smith');
      expect(result['email'], 'alex@example.com');
    });

    test('returns null when no member profile fields need changing', () {
      final result = FirestoreUserProfileService.updatedMemberProfileData(
        {
          'displayName': 'Alex Smith',
          'email': 'alex@example.com',
          'avatarUrl': 'https://example.com/avatar.png',
        },
        displayName: 'Alex Smith',
        email: 'alex@example.com',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(result, isNull);
    });
  });
}
