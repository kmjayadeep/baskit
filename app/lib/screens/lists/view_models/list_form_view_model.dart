import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_list_model.dart';
import '../../../repositories/shopping_repository.dart';
import '../../../providers/repository_providers.dart';
import '../../../extensions/shopping_list_extensions.dart';

/// State class for the list form
class ListFormState {
  final String name;
  final String description;
  final Color selectedColor;
  final bool isLoading;
  final String? error;
  final bool isValid;
  final bool isEditMode;
  final ShoppingList? existingList;

  const ListFormState({
    required this.name,
    required this.description,
    required this.selectedColor,
    required this.isLoading,
    this.error,
    required this.isValid,
    required this.isEditMode,
    this.existingList,
  });

  // Initial state for create mode
  const ListFormState.initial()
    : this(
        name: '',
        description: '',
        selectedColor: Colors.blue,
        isLoading: false,
        isValid: false,
        isEditMode: false,
      );

  // Factory constructor for edit mode
  ListFormState.forEdit(ShoppingList list)
    : this(
        name: list.name,
        description: list.description,
        selectedColor: list.displayColor, // Use existing model method
        isLoading: false,
        isValid: true, // Existing list should be valid
        isEditMode: true,
        existingList: list,
      );

  // Copy with method for state updates
  ListFormState copyWith({
    String? name,
    String? description,
    Color? selectedColor,
    bool? isLoading,
    String? error,
    bool? isValid,
    bool? isEditMode,
    ShoppingList? existingList,
    bool clearError = false,
  }) {
    return ListFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      selectedColor: selectedColor ?? this.selectedColor,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isValid: isValid ?? this.isValid,
      isEditMode: isEditMode ?? this.isEditMode,
      existingList: existingList ?? this.existingList,
    );
  }

  // Available colors for list creation
  static const List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
}

/// ViewModel for managing list form state and business logic
class ListFormViewModel extends Notifier<ListFormState> {
  late final ShoppingRepository _repository;
  final Uuid _uuid = const Uuid();

  @override
  ListFormState build() {
    _repository = ref.read(shoppingRepositoryProvider);
    return const ListFormState.initial();
  }

  // Update list name and validate form
  void updateName(String name) {
    state = state.copyWith(
      name: name,
      isValid: _validateForm(name, state.description),
      clearError: true,
    );
  }

  // Update description and validate form
  void updateDescription(String description) {
    state = state.copyWith(
      description: description,
      isValid: _validateForm(state.name, description),
      clearError: true,
    );
  }

  // Update selected color
  void updateSelectedColor(Color color) {
    state = state.copyWith(selectedColor: color, clearError: true);
  }

  // Validate form data
  bool _validateForm(String name, String description) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  // Validate name field specifically
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a list name';
    }
    if (value.trim().length < 2) {
      return 'List name must be at least 2 characters';
    }
    return null;
  }

  // Convert Color to hex string for storage
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  // Initialize the form for editing an existing list
  void initializeForEdit(ShoppingList list) {
    state = ListFormState.forEdit(list);
  }

  // Update an existing list
  Future<bool> updateList() async {
    if (!state.isEditMode || state.existingList == null) {
      state = state.copyWith(error: 'Cannot update list: not in edit mode');
      return false;
    }

    // Validate before proceeding
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fix form errors before submitting');
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedList = state.existingList!.copyWith(
        name: state.name.trim(),
        description: state.description.trim(),
        color: _colorToHex(state.selectedColor),
        updatedAt: DateTime.now(),
      );

      final success = await _repository.updateList(updatedList);

      if (success) {
        // Keep the current state but clear loading
        state = state.copyWith(
          isLoading: false,
          existingList: updatedList, // Update with the new data
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update list. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating list: ${e.toString()}',
      );
      return false;
    }
  }

  // Create and save the list
  Future<bool> createList() async {
    // Validate before proceeding
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fix form errors before submitting');
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = DateTime.now();

      final newList = ShoppingList(
        id: _uuid.v4(),
        name: state.name.trim(),
        description: state.description.trim(),
        color: _colorToHex(state.selectedColor),
        createdAt: now,
        updatedAt: now,
      );

      final success = await _repository.createList(newList);

      if (success) {
        // Reset form on success
        state = const ListFormState.initial();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create list. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error creating list: ${e.toString()}',
      );
      return false;
    }
  }

  // Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider for ListFormViewModel
final listFormViewModelProvider =
    NotifierProvider<ListFormViewModel, ListFormState>(ListFormViewModel.new);
