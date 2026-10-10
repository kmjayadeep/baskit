import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'common_item_card.dart';

/// A card for a single "Run Out" item (a Have-at-Home item marked finished).
///
/// Offers "Move back" (restore to Have at Home) and a Delete action, matching
/// the spec: "Move back / Delete". Layout and interaction live in the shared
/// [ShoppingItemCard]; this wrapper keeps the existing public API.
class RunOutItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final VoidCallback? onMoveBack;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RunOutItemCard({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onMoveBack,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ShoppingItemCard(
      item: item,
      isProcessing: isProcessing,
      icon: Icons.remove_shopping_cart_outlined,
      iconColor: AppColors.basketOrange,
      primaryLabel: onMoveBack == null ? '' : 'Move back',
      onPrimary: onMoveBack,
      onDelete: onDelete,
      onEdit: onEdit,
    );
  }
}
