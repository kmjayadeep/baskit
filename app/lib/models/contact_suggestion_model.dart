/// Model representing a contact suggestion for sharing shopping lists
///
/// This model captures contacts extracted from existing shared lists to provide
/// intelligent autocomplete suggestions when sharing new lists.
class ContactSuggestion {
  /// Firebase user ID of the suggested contact
  final String userId;

  /// Email address of the contact
  final String email;

  /// Display name to show in the UI
  final String displayName;

  /// Profile picture URL if available
  final String? avatarUrl;

  /// Number of lists shared with this contact
  final int sharedListsCount;

  const ContactSuggestion({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.sharedListsCount,
  });

  /// Check if this contact matches a search query
  /// Performs case-insensitive matching against display name and email
  bool matches(String query) {
    if (query.trim().isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();
    final lowerDisplayName = displayName.toLowerCase();
    final lowerEmail = email.toLowerCase();

    return lowerDisplayName.contains(lowerQuery) ||
        lowerEmail.contains(lowerQuery);
  }

  /// Create from JSON (for potential caching/storage)
  factory ContactSuggestion.fromJson(Map<String, dynamic> json) {
    return ContactSuggestion(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      sharedListsCount: json['sharedListsCount'] as int,
    );
  }

  /// Convert to JSON (for potential caching/storage)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'sharedListsCount': sharedListsCount,
    };
  }

  /// Create a copy with updated fields
  ContactSuggestion copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    int? sharedListsCount,
  }) {
    return ContactSuggestion(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sharedListsCount: sharedListsCount ?? this.sharedListsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContactSuggestion &&
        other.userId == userId &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.sharedListsCount == sharedListsCount;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        avatarUrl.hashCode ^
        sharedListsCount.hashCode;
  }

  @override
  String toString() {
    return 'ContactSuggestion(userId: $userId, email: $email, displayName: $displayName, sharedListsCount: $sharedListsCount)';
  }
}
