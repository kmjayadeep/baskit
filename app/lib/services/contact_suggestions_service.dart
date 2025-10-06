import 'package:flutter/foundation.dart';
import '../models/contact_suggestion_model.dart';
import '../models/shopping_list_model.dart';

/// Service to provide intelligent contact suggestions for sharing shopping lists
///
/// Extracts contacts from existing shared lists to provide autocomplete
/// suggestions when users share new lists.
class ContactSuggestionsService {
  // Simple in-memory cache for contact suggestions
  static List<ContactSuggestion>? _cachedContacts;
  static String? _cachedUserId;

  /// Get contact suggestions for the current user
  ///
  /// Returns a stream of contact suggestions extracted from the user's
  /// existing shared lists. Results are cached for performance.
  ///
  /// [currentUserId] - Firebase UID of the current user
  static Stream<List<ContactSuggestion>> getUserContacts(String currentUserId) {
    // Return cached contacts if available for the same user
    if (_cachedContacts != null && _cachedUserId == currentUserId) {
      return Stream.value(_cachedContacts!);
    }

    // TODO: Implement contact extraction from user's lists
    // Will use _extractContactsFromLists helper method
    throw UnimplementedError('getUserContacts not implemented yet');
  }

  /// Extract contact suggestions from a list of shopping lists
  ///
  /// Processes the memberDetails from each list to build contact suggestions.
  /// Excludes the current user from suggestions.
  ///
  /// [lists] - Shopping lists to extract contacts from
  /// [currentUserId] - Current user's ID to exclude from suggestions
  @visibleForTesting
  static Future<List<ContactSuggestion>> extractContactsFromLists(
    List<ShoppingList> lists,
    String currentUserId,
  ) async {
    // Map to track contacts and count shared lists
    final Map<String, ContactSuggestion> contactMap = {};

    try {
      for (final list in lists) {
        // Skip lists without rich member data
        if (list.memberDetails == null || list.memberDetails!.isEmpty) {
          continue;
        }

        for (final member in list.memberDetails!) {
          // Skip the current user
          if (member.userId == currentUserId) {
            continue;
          }

          // Skip members without email (can't share with them)
          if (member.email == null || member.email!.trim().isEmpty) {
            continue;
          }

          final userId = member.userId;

          if (contactMap.containsKey(userId)) {
            // Increment shared lists count for existing contact
            final existingContact = contactMap[userId]!;
            contactMap[userId] = existingContact.copyWith(
              sharedListsCount: existingContact.sharedListsCount + 1,
            );
          } else {
            // Add new contact suggestion
            contactMap[userId] = ContactSuggestion(
              userId: member.userId,
              email: member.email!,
              displayName: member.displayName,
              avatarUrl: member.avatarUrl,
              sharedListsCount: 1,
            );
          }
        }
      }

      // Convert to list and sort by display name
      final contacts =
          contactMap.values.toList()..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

      debugPrint(
        '📋 Extracted ${contacts.length} contacts from ${lists.length} lists',
      );
      return contacts;
    } catch (e) {
      debugPrint('❌ Error extracting contacts: $e');
      return [];
    }
  }

  /// Refresh the contact cache for the current user
  ///
  /// Forces a refresh of cached contact suggestions. Useful when
  /// new lists are shared or members are added.
  ///
  /// [currentUserId] - Firebase UID of the user to refresh cache for
  static Future<void> refreshContactCache(String currentUserId) async {
    try {
      _cachedContacts = null;
      _cachedUserId = null;
      debugPrint('🔄 Contact cache refreshed for user: $currentUserId');
    } catch (e) {
      debugPrint('❌ Error refreshing contact cache: $e');
    }
  }

  /// Clear all cached contact suggestions
  ///
  /// Useful for memory management or when user signs out
  static void clearCache() {
    _cachedContacts = null;
    _cachedUserId = null;
    debugPrint('🧹 Contact cache cleared');
  }
}
