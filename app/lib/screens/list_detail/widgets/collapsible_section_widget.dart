import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Builds the collapsed-header preview text from a list of item names.
///
/// Shows the first two non-empty names joined by ", " followed by
/// " · Tap to show". When more than two names survive the empty-name filter,
/// a "+N more" suffix is appended, where N counts the remaining non-empty
/// names beyond the previewed two.
///
/// Shared by the completed-items and run-out sections so both render the
/// identical collapsed summary without duplicating the logic.
String buildCollapsedSummary(List<String> names) {
  final previewNames = names
      .take(2)
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  if (previewNames.isEmpty) {
    return 'Tap to show';
  }

  // The "+N more" count reflects items hidden from the preview. Only names
  // that survived the empty-name filter are shown, so count the remaining
  // names (total minus those previewed) rather than assuming two are shown.
  final remainingCount = names.length - previewNames.length;
  final moreLabel = remainingCount > 0 ? ' +$remainingCount more' : '';
  return '${previewNames.join(', ')}$moreLabel · Tap to show';
}

/// A collapsible section that groups items under a tappable header.
///
/// Shows a count badge and an expand/collapse chevron; tapping the header
/// toggles visibility of the items. Header styling and the per-item widget are
/// supplied by the caller so this single implementation backs both
/// [CompletedItemsSection] and [RunOutSection].
class CollapsibleListSection extends StatefulWidget {
  /// Full title, e.g. "Completed (3)".
  final String title;
  final IconData icon;
  final Color iconColor;

  /// The item names, in display order. Used to build the collapsed summary.
  final List<String> itemNames;

  /// Pre-built per-item widgets, in display order.
  final List<Widget> items;

  /// Builds the collapsed summary text from the item names.
  final String Function(List<String> names) collapsedSummaryBuilder;

  const CollapsibleListSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.itemNames,
    required this.items,
    required this.collapsedSummaryBuilder,
  });

  @override
  State<CollapsibleListSection> createState() =>
      _CollapsibleListSectionState();
}

class _CollapsibleListSectionState extends State<CollapsibleListSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summaryText =
        _isExpanded ? 'Hide' : widget.collapsedSummaryBuilder(widget.itemNames);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsible header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.iconColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: widget.iconColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Items list
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: widget.items,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
