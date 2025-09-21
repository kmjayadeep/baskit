import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list_model.dart';
import '../../services/storage_service.dart';
import 'widgets/list_form_field_widget.dart';
import 'widgets/color_picker_widget.dart';
import 'widgets/list_preview_widget.dart';
import 'widgets/create_button_widget.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Color selectedColor = Colors.blue;
  bool _isLoading = false;

  final List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Convert Color to hex string for storage
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  // Create and save the list
  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uuid = const Uuid();
      final now = DateTime.now();

      final newList = ShoppingList(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _colorToHex(selectedColor),
        createdAt: now,
        updatedAt: now,
      );

      final success = await StorageService.instance.createList(newList);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('List "${newList.name}" created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to lists screen
        context.go('/lists');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create list. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _isLoading ? null : _createList,
            child:
                _isLoading
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a list name';
                  }
                  if (value.trim().length < 2) {
                    return 'List name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: () => setState(() {}),
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
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Color Selection
              ColorPickerWidget(
                selectedColor: selectedColor,
                availableColors: availableColors,
                onColorSelected: (color) {
                  setState(() {
                    selectedColor = color;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Preview
              ListPreviewWidget(
                name: _nameController.text,
                description: _descriptionController.text,
                selectedColor: selectedColor,
              ),

              const Spacer(),

              // Create Button
              CreateButtonWidget(
                isLoading: _isLoading,
                selectedColor: selectedColor,
                onPressed: _createList,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
