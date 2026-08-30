part of 'whats_new_model.dart';

/// Represents a single item in the What's New dialog.
class WhatsNewItem {
  final String title;
  final String description;
  final String iconName;
  final WhatsNewItemType type;
  final WhatsNewItemImportance importance;
  final bool userFacing;
  final String? group;

  const WhatsNewItem({
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    this.importance = WhatsNewItemImportance.medium,
    this.userFacing = true,
    this.group,
  });

  /// Create from JSON.
  factory WhatsNewItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'info',
      type: WhatsNewItemType.fromString(json['type'] as String? ?? 'feature'),
      importance: WhatsNewItemImportance.fromString(
        json['importance'] as String? ?? 'medium',
      ),
      userFacing: json['userFacing'] as bool? ?? false,
      group: json['group'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'importance': importance.name,
    'userFacing': userFacing,
    if (group != null) 'group': group,
    'title': title,
    'description': description,
    'icon': iconName,
  };

  /// Get the Flutter icon for this item.
  IconData get icon => _whatsNewIcons[iconName.toLowerCase()] ?? Icons.info;

  /// Get the color for this item type.
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    return switch (type) {
      WhatsNewItemType.feature => theme.primaryColor,
      WhatsNewItemType.improvement => Colors.orange,
      WhatsNewItemType.bugfix => Colors.green,
    };
  }

  /// Get the emoji for this item type.
  String get emoji => switch (type) {
    WhatsNewItemType.feature => '✨',
    WhatsNewItemType.improvement => '🚀',
    WhatsNewItemType.bugfix => '🛠️',
  };
}

const _whatsNewIcons = <String, IconData>{
  'person_search': Icons.person_search,
  'contact_search': Icons.person_search,
  'person_remove': Icons.person_remove,
  'account_delete': Icons.person_remove,
  'group': Icons.group,
  'people': Icons.group,
  'share': Icons.share,
  'security': Icons.security,
  'shield': Icons.security,
  'auto_complete': Icons.auto_awesome,
  'autocomplete': Icons.auto_awesome,
  'sync': Icons.sync,
  'speed': Icons.speed,
  'fast': Icons.speed,
  'design': Icons.palette,
  'palette': Icons.palette,
  'accessibility': Icons.accessibility,
  'mobile': Icons.phone_android,
  'phone': Icons.phone_android,
  'bug_fix': Icons.bug_report,
  'bug': Icons.bug_report,
  'fix': Icons.build,
  'build': Icons.build,
  'stable': Icons.verified,
  'verified': Icons.verified,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'thumb_up': Icons.thumb_up,
  'celebration': Icons.celebration,
  'new': Icons.fiber_new,
  'fiber_new': Icons.fiber_new,
  'update': Icons.update,
  'info': Icons.info,
};

/// Types of What's New items.
enum WhatsNewItemType {
  feature,
  improvement,
  bugfix;

  /// Create from string.
  static WhatsNewItemType fromString(String value) {
    return switch (value.toLowerCase()) {
      'feature' || 'new' => WhatsNewItemType.feature,
      'improvement' || 'enhance' || 'enhancement' =>
        WhatsNewItemType.improvement,
      'bugfix' || 'fix' || 'bug' => WhatsNewItemType.bugfix,
      _ => WhatsNewItemType.feature,
    };
  }

  /// Get display name.
  String get displayName => switch (this) {
    WhatsNewItemType.feature => 'New Feature',
    WhatsNewItemType.improvement => 'Improvement',
    WhatsNewItemType.bugfix => 'Bug Fix',
  };
}

/// Importance levels for selecting release highlights.
enum WhatsNewItemImportance {
  low(1),
  medium(2),
  high(3);

  const WhatsNewItemImportance(this.rank);

  /// Sort rank, where higher values are more important.
  final int rank;

  /// Create from string.
  static WhatsNewItemImportance fromString(String value) {
    return switch (value.toLowerCase()) {
      'high' => WhatsNewItemImportance.high,
      'low' => WhatsNewItemImportance.low,
      _ => WhatsNewItemImportance.medium,
    };
  }
}
