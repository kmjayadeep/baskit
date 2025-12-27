import 'package:flutter/foundation.dart';
import '../models/contact_suggestion_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/storage_shopping_repository.dart';

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
  static Stream<List<ContactSuggestion>> getUserContacts(
    String currentUserId,
  ) async* {
    // Yield cached contacts first if available for the same user (for immediate UI response)
    if (_cachedContacts != null && _cachedUserId == currentUserId) {
      debugPrint(
        '💾 Yielding cached contacts (${_cachedContacts!.length} contacts)',
      );
      yield _cachedContacts!;
      // Don't return - continue listening to the stream for updates
    }

    try {
      debugPrint('🔍 Fetching contacts for user: $currentUserId');

      // Get repository instance
      final repository = StorageShoppingRepository.instance();

      // Listen to user's lists and extract contacts
      await for (final lists in repository.watchLists()) {
        // Extract contacts from the lists
        final contacts = await extractContactsFromLists(lists, currentUserId);

        // Cache the results
        _cachedContacts = contacts;
        _cachedUserId = currentUserId;

        debugPrint('✅ Extracted and cached ${contacts.length} contacts');
        yield contacts;
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      // Silently handle permission errors (happens during sign-in race condition)
      // The stream will retry when user profile is properly initialized
      if (errorString.contains('permission') ||
          errorString.contains('denied')) {
        debugPrint('⚠️  Permission error (user profile not ready yet): $e');
        // Yield empty list but don't set error state
        yield [];
      } else {
        // Log other errors
        debugPrint('❌ Error fetching user contacts: $e');
        yield [];
      }
    }
  }

  /// Extract contact suggestions from a list of shopping lists
  ///
  /// Processes the members from each list to build contact suggestions.
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
        // Skip lists without member data
        if (list.members.isEmpty) {
          continue;
        }

        for (final member in list.members) {
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
