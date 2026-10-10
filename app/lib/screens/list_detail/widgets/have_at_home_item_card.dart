import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'common_item_card.dart';

/// A card for a single "Have at Home" item.
///
/// Offers a "Finished" action and an edit/delete menu, matching the spec.
/// Layout and interaction live in the shared [ShoppingItemCard]; this wrapper
/// keeps the existing public API for callers and tests.
class HaveAtHomeItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final VoidCallback? onFinished;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const HaveAtHomeItemCard({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onFinished,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ShoppingItemCard(
      item: item,
      isProcessing: isProcessing,
      icon: Icons.home_filled,
      iconColor: AppColors.basketOrange,
      primaryLabel: onFinished == null ? '' : 'Finished',
      onPrimary: onFinished,
      onDelete: onDelete,
      onEdit: onEdit,
    );
  }
}
