import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/shopping_list_model.dart';

/// Compact widget with circular progress replacing the old icon + linear bar.
class ListHeaderWidget extends StatelessWidget {
  final ShoppingList list;

  const ListHeaderWidget({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final listColor = list.displayColor;
    final progress = list.completionProgress;
    final hasProgress = progress > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: listColor.withValues(alpha: 0.11),
        border: Border(
          bottom: BorderSide(color: listColor.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular progress avatar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 2.8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          listColor.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    // Progress ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 2.8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(listColor),
                      ),
                    ),
                    // Center content
                    if (hasProgress)
                      Text(
                        '${(value * 100).round()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: listColor,
                          fontSize: 9,
                        ),
                      )
                    else
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 18,
                        color: listColor.withValues(alpha: 0.7),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (list.totalItemsCount > 0) {
      parts.add('${list.completedItemsCount}/${list.totalItemsCount} items');
    }
    if (list.description.isNotEmpty) {
      parts.add(list.description);
    }
    return parts.join(' · ');
  }
}
