import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/list_form_field_widget.dart';
import 'widgets/color_picker_widget.dart';
import 'widgets/list_preview_widget.dart';
import 'widgets/submit_button_widget.dart';
import 'view_models/list_form_view_model.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_list_template.dart';
import '../../constants/app_colors.dart';

class ListFormScreen extends ConsumerStatefulWidget {
  final ShoppingList? existingList; // For edit mode

  const ListFormScreen({super.key, this.existingList});

  @override
  ConsumerState<ListFormScreen> createState() => _ListFormScreenState();
}

class _ListFormScreenState extends ConsumerState<ListFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize for edit mode if existing list is provided
    if (widget.existingList != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
      });
    }
  }

  void _initializeForEdit() {
    final list = widget.existingList!;
    _nameController.text = list.name;
    _descriptionController.text = list.description;
    ref.read(listFormViewModelProvider.notifier).initializeForEdit(list);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Handle form submission (create or update)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = ref.read(listFormViewModelProvider.notifier);
    final submittedListName = _nameController.text.trim();
    final bool success;

    // Determine operation based on existing list
    if (widget.existingList != null) {
      success = await viewModel.updateList();
    } else {
      success = await viewModel.createList();
    }

    if (success && mounted) {
      // Show success message
      final listName = submittedListName;
      final message =
          widget.existingList != null
              ? 'List "$listName" updated successfully!'
              : 'List "$listName" created successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      context.go('/lists');
    } else if (mounted) {
      // Show error from ViewModel
      final error = ref.read(listFormViewModelProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyTemplate(ShoppingListTemplate template) {
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    ref.read(listFormViewModelProvider.notifier).applyTemplate(template);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listFormViewModelProvider);
    final viewModel = ref.read(listFormViewModelProvider.notifier);

    // Determine UI elements based on mode
    final isEditMode = widget.existingList != null;
    final title = isEditMode ? 'Edit List' : 'Create New List';
    final actionText = isEditMode ? 'Update' : 'Create';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/lists');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : _handleSubmit,
            child:
                state.isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(actionText),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (!isEditMode) ...[
                _TemplatePicker(
                  selectedTemplate: state.selectedTemplate,
                  onTemplateSelected: _applyTemplate,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'List details' : 'Start a list',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditMode
                          ? 'Update the name, description, and color people see.'
                          : 'Name it, pick a color, and keep shopping organized.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // List Name Field
                    ListFormFieldWidget(
                      label: 'List name',
                      hintText: 'Groceries, Party Supplies',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      validator: viewModel.validateName,
                      onChanged: () {
                        viewModel.updateName(_nameController.text);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    ListFormFieldWidget(
                      label: 'Description',
                      hintText: 'Optional note for this list',
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      validator: (value) => null,
                      onChanged: () {
                        viewModel.updateDescription(
                          _descriptionController.text,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ColorPickerWidget(
                  selectedColor: state.selectedColor,
                  availableColors: ListFormState.availableColors,
                  onColorSelected: viewModel.updateSelectedColor,
                ),
              ),
              const SizedBox(height: 16),

              // Preview
              ListPreviewWidget(
                name: _nameController.text,
                description: _descriptionController.text,
                selectedColor: state.selectedColor,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SubmitButtonWidget(
                isLoading: state.isLoading,
                selectedColor: state.selectedColor,
                onPressed: _handleSubmit,
                buttonText: isEditMode ? 'Update List' : 'Create List',
                loadingText: isEditMode ? 'Updating...' : 'Creating...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  final ShoppingListTemplate? selectedTemplate;
  final ValueChanged<ShoppingListTemplate> onTemplateSelected;

  const _TemplatePicker({
    required this.selectedTemplate,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start from a template',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a ready-made list and customize it before creating.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                builtInShoppingListTemplates.map((template) {
                  final isSelected = selectedTemplate == template;
                  return ChoiceChip(
                    selected: isSelected,
                    avatar: Icon(
                      template.icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    label: Text(template.name),
                    onSelected: (_) => onTemplateSelected(template),
                    selectedColor: template.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: isSelected ? template.color : AppColors.border,
                    ),
                  );
                }).toList(),
          ),
          if (selectedTemplate != null) ...[
            const SizedBox(height: 12),
            Text(
              '${selectedTemplate!.items.length} starter items will be added.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
