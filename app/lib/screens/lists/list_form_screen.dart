import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/list_form_field_widget.dart';
import 'widgets/color_picker_widget.dart';
import 'widgets/list_preview_widget.dart';
import 'widgets/submit_button_widget.dart';
import 'view_models/list_form_view_model.dart';
import '../../models/shopping_list_model.dart';

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
    final bool success;

    // Determine operation based on existing list
    if (widget.existingList != null) {
      success = await viewModel.updateList();
    } else {
      success = await viewModel.createList();
    }

    if (success && mounted) {
      // Show success message
      final listName = ref.read(listFormViewModelProvider).name;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listFormViewModelProvider);
    final viewModel = ref.read(listFormViewModelProvider.notifier);

    // Determine UI elements based on mode
    final isEditMode = widget.existingList != null;
    final title = isEditMode ? 'Edit List' : 'Create New List';
    final actionText = isEditMode ? 'Update' : 'Create';

    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // List Name Field
              ListFormFieldWidget(
                label: 'List Name',
                hintText: 'e.g., Groceries, Party Supplies',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: viewModel.validateName,
                onChanged: () {
                  viewModel.updateName(_nameController.text);
                },
              ),
              const SizedBox(height: 24),

              // Description Field
              ListFormFieldWidget(
                label: 'Description (Optional)',
                hintText: 'Add a description for your list',
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                validator: (value) => null, // No validation for optional field
                onChanged: () {
                  viewModel.updateDescription(_descriptionController.text);
                },
              ),
              const SizedBox(height: 24),

              // Color Selection
              ColorPickerWidget(
                selectedColor: state.selectedColor,
                availableColors: ListFormState.availableColors,
                onColorSelected: viewModel.updateSelectedColor,
              ),
              const SizedBox(height: 32),

              // Preview
              ListPreviewWidget(
                name: _nameController.text,
                description: _descriptionController.text,
                selectedColor: state.selectedColor,
              ),

              const Spacer(),

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
