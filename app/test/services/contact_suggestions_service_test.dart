import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/services/contact_suggestions_service.dart';

void main() {
  group('ContactSuggestionsService', () {
    test('should throw UnimplementedError for getUserContacts', () {
      expect(
        () => ContactSuggestionsService.getUserContacts('test_user_id'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('should clear cache without error', () {
      expect(() => ContactSuggestionsService.clearCache(), returnsNormally);
    });

    test('should refresh cache without error', () async {
      await expectLater(
        ContactSuggestionsService.refreshContactCache('test_user_id'),
        completes,
      );
    });
  });
}
