import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/list_form_field_widget.dart';
import 'widgets/color_picker_widget.dart';
import 'widgets/list_preview_widget.dart';
import 'widgets/create_button_widget.dart';
import 'view_models/list_form_view_model.dart';

class ListFormScreen extends ConsumerStatefulWidget {
  const ListFormScreen({super.key});

  @override
  ConsumerState<ListFormScreen> createState() => _ListFormScreenState();
}

class _ListFormScreenState extends ConsumerState<ListFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Handle list creation with ViewModel
  Future<void> _handleCreateList() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = ref.read(listFormViewModelProvider.notifier);
    final success = await viewModel.createList();

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'List "${ref.read(listFormViewModelProvider).name}" created successfully!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to lists screen
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New List'),
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
            onPressed: state.isLoading ? null : _handleCreateList,
            child:
                state.isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Create'),
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

              // Create Button
              CreateButtonWidget(
                isLoading: state.isLoading,
                selectedColor: state.selectedColor,
                onPressed: _handleCreateList,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
