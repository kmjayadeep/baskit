import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../utils/snackbar_extensions.dart';
import '../view_models/list_detail_view_model.dart';
import 'dialogs/edit_item_dialog.dart';
import 'have_at_home_item_card.dart';
import 'run_out_section_widget.dart';

/// The "Have at Home" tab: an add-item form plus the list of items the user
/// already has at home, each with a "Finished" action.
///
/// Self-contained so it can host its own input controllers without entangling
/// the shopping tab's UI. Reads the same shared ViewModel as the rest of the
/// screen, so adds/finishes update the list in place.
class HaveAtHomeTab extends ConsumerStatefulWidget {
  final String listId;
  final ShoppingList list;
  final bool canWrite;

  const HaveAtHomeTab({
    super.key,
    required this.listId,
    required this.list,
    required this.canWrite,
  });

  @override
  ConsumerState<HaveAtHomeTab> createState() => _HaveAtHomeTabState();
}

class _HaveAtHomeTabState extends ConsumerState<HaveAtHomeTab> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _showQuantity = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canAdd =>
      !ref.read(listDetailViewModelProvider(widget.listId)).isAddingItem &&
      _nameController.text.trim().isNotEmpty;

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.addItemToHaveAtHome(
      name,
      _quantityController.text.trim().isEmpty
          ? null
          : _quantityController.text.trim(),
    );

    if (result.isSuccess && mounted) {
      _nameController.clear();
      _quantityController.clear();
      _nameFocusNode.requestFocus();
    }
  }

  void _toggleQuantity() {
    setState(() => _showQuantity = !_showQuantity);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listDetailViewModelProvider(widget.listId));
    final haveAtHomeItems = widget.list.items
        .where((item) => item.listItemType == ItemType.haveAtHome)
        .toList();
    final runOutItems = widget.list.items
        .where((item) => item.listItemType == ItemType.runOut)
        .toList();

    return Column(
      children: [
        // Add form (write permission only)
        if (widget.canWrite)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        enabled: !state.isAddingItem,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _canAdd ? _addItem() : null,
                        decoration: InputDecoration(
                          hintText: state.isAddingItem
                              ? 'Adding item...'
                              : 'Add an item you have at home',
                          prefixIcon: state.isAddingItem
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.home_filled),
                          suffixIcon: IconButton(
                            tooltip: 'Quantity, note, or type',
                            onPressed:
                                state.isAddingItem ? null : _toggleQuantity,
                            icon: Icon(
                              _showQuantity
                                  ? Icons.keyboard_arrow_up
                                  : Icons.notes_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _canAdd ? _addItem : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: state.isAddingItem
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: _showQuantity
                      ? Padding(
                          key: const ValueKey('have-at-home-quantity'),
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: _quantityController,
                            enabled: !state.isAddingItem,
                            decoration: const InputDecoration(
                              hintText: 'Qty, note, or type',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                            onSubmitted: (_) => _canAdd ? _addItem() : null,
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('have-at-home-quantity-hidden'),
                        ),
                ),
              ],
            ),
          ),

        // Items
        Expanded(
          child: haveAtHomeItems.isEmpty && runOutItems.isEmpty
              ? _HaveAtHomeEmptyState(
                  onAddFirstItem:
                      widget.canWrite ? _nameFocusNode.requestFocus : null,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    for (final item in haveAtHomeItems)
                      HaveAtHomeItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        isProcessing: state.processingItems.contains(item.id),
                        onFinished:
                            widget.canWrite ? () => _finish(item) : null,
                        onDelete:
                            widget.canWrite ? () => _delete(item) : null,
                        onEdit: widget.canWrite ? () => _edit(item) : null,
                      ),
                    if (runOutItems.isNotEmpty)
                      RunOutSection(
                        runOutItems: runOutItems,
                        processingItems: state.processingItems,
                        onMoveBack:
                            widget.canWrite
                                ? (item) => _moveBack(item)
                                : null,
                        onDelete:
                            widget.canWrite ? (item) => _delete(item) : null,
                        onEdit: widget.canWrite ? (item) => _edit(item) : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _moveBack(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.markBackToHaveAtHome(item);
    if (result.isSuccess && mounted) {
      HapticFeedback.lightImpact();
      context.showSuccessSnackBar('${item.name} moved back to Have at Home');
    } else if (!result.isSuccess && mounted) {
      context.showErrorSnackBar(
        result.errorMessage ?? 'Error moving item back',
      );
    }
  }

  Future<void> _finish(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.finishHaveAtHomeItem(item);
    if (result.isSuccess && mounted) {
      HapticFeedback.lightImpact();
      context.showSuccessSnackBar('${item.name} marked finished');
    } else if (!result.isSuccess && mounted) {
      context.showErrorSnackBar(result.errorMessage ?? 'Error finishing item');
    }
  }

  Future<void> _delete(ShoppingItem item) async {
    final viewModel = ref.read(
      listDetailViewModelProvider(widget.listId).notifier,
    );
    final result = await viewModel.deleteItem(item);
    if (result.isSuccess && mounted) {
      HapticFeedback.mediumImpact();
      context.showSuccessSnackBar('${item.name} deleted');
    } else if (!result.isSuccess && mounted) {
      context.showErrorSnackBar(result.errorMessage ?? 'Error deleting item');
    }
  }

  Future<void> _edit(ShoppingItem item) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
    if (result != null && mounted) {
      final viewModel = ref.read(
        listDetailViewModelProvider(widget.listId).notifier,
      );
      final actionResult = await viewModel.editItem(
        item,
        result['name']!,
        result['quantity'],
      );
      if (!actionResult.isSuccess && mounted) {
        context.showErrorSnackBar(actionResult.errorMessage ?? 'Error updating item');
      }
    }
  }
}

class _HaveAtHomeEmptyState extends StatelessWidget {
  final VoidCallback? onAddFirstItem;

  const _HaveAtHomeEmptyState({this.onAddFirstItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.home_filled,
                size: 28,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add the things you already have at home so you can track '
              'what you use up.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onAddFirstItem != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddFirstItem,
                icon: const Icon(Icons.add),
                label: const Text('Add first item'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
