import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/list_member_model.dart';
import '../../../models/shopping_list_model.dart';

part 'member_avatar_stack.dart';

/// A card widget that displays shopping list information in a compact format.
class ListCardWidget extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final String? currentUserId;

  const ListCardWidget({
    super.key,
    required this.list,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final color = list.displayColor;
    final now = DateTime.now();
    final updatedLabel = _updatedLabel(list.updatedAt, now: now);
    final updatedSemanticsLabel = _updatedSemanticsLabel(
      list.updatedAt,
      now: now,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 74,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            list.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${list.items.length} items',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    if (list.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: list.completionProgress),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: value,
                            backgroundColor: AppColors.border.withValues(
                              alpha: 0.65,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child:
                                list.isShared
                                    ? _MemberAvatarStack(
                                      members: _visibleMembers,
                                    )
                                    : const _StatusChip(
                                      icon: Icons.lock,
                                      text: 'Private',
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${list.completedItemsCount}/${list.totalItemsCount} done',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Semantics(
                              label: updatedSemanticsLabel,
                              container: true,
                              child: ExcludeSemantics(
                                child: Text(
                                  updatedLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ListMember> get _visibleMembers {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      return list.sharedMembers;
    }

    return list.members.where((member) => member.userId != userId).toList();
  }
}

String _updatedLabel(DateTime updatedAt, {DateTime? now}) {
  final localUpdatedAt = updatedAt.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  final updatedDate = DateTime(
    localUpdatedAt.year,
    localUpdatedAt.month,
    localUpdatedAt.day,
  );
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final daysSinceUpdate = today.difference(updatedDate).inDays;

  if (daysSinceUpdate <= 0) {
    return 'Updated today';
  }

  if (daysSinceUpdate == 1) {
    return 'Updated yesterday';
  }

  final month = _shortMonthNames[localUpdatedAt.month - 1];
  if (localUpdatedAt.year == localNow.year) {
    return 'Updated $month ${localUpdatedAt.day}';
  }

  return 'Updated $month ${localUpdatedAt.day}, ${localUpdatedAt.year}';
}

String _updatedSemanticsLabel(DateTime updatedAt, {DateTime? now}) {
  final relativeLabel = _updatedLabel(updatedAt, now: now);
  final localUpdatedAt = updatedAt.toLocal();
  final month = _longMonthNames[localUpdatedAt.month - 1];
  final fullDate = '$month ${localUpdatedAt.day}, ${localUpdatedAt.year}';

  if (relativeLabel == 'Updated today' ||
      relativeLabel == 'Updated yesterday') {
    return '$relativeLabel, $fullDate';
  }

  return 'Updated $fullDate';
}

const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _longMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
