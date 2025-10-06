import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/contact_suggestion_model.dart';

void main() {
  group('ContactSuggestion', () {
    test('should create with required fields', () {
      const contact = ContactSuggestion(
        userId: 'user123',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
        sharedListsCount: 3,
      );

      expect(contact.userId, 'user123');
      expect(contact.email, 'john.doe@example.com');
      expect(contact.displayName, 'John Doe');
      expect(contact.sharedListsCount, 3);
    });

    group('matches', () {
      const contact = ContactSuggestion(
        userId: 'user123',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
        sharedListsCount: 3,
      );

      test('should return true for empty query', () {
        expect(contact.matches(''), isTrue);
        expect(contact.matches('   '), isTrue);
      });

      test('should match display name case-insensitively', () {
        expect(contact.matches('john'), isTrue);
        expect(contact.matches('JOHN'), isTrue);
        expect(contact.matches('doe'), isTrue);
      });

      test('should match email case-insensitively', () {
        expect(contact.matches('john.doe'), isTrue);
        expect(contact.matches('example.com'), isTrue);
      });

      test('should not match non-existing strings', () {
        expect(contact.matches('jane'), isFalse);
        expect(contact.matches('notfound'), isFalse);
      });
    });

    test('should handle JSON serialization', () {
      const contact = ContactSuggestion(
        userId: 'user123',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
        sharedListsCount: 3,
      );

      final json = contact.toJson();
      final restored = ContactSuggestion.fromJson(json);

      expect(restored.userId, contact.userId);
      expect(restored.email, contact.email);
      expect(restored.displayName, contact.displayName);
      expect(restored.sharedListsCount, contact.sharedListsCount);
    });
  });
}
