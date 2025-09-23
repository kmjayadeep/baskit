import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_list_model.dart';
import '../../../services/storage_service.dart';

/// State class for the list form
class ListFormState {
  final String name;
  final String description;
  final Color selectedColor;
  final bool isLoading;
  final String? error;
  final bool isValid;

  const ListFormState({
    required this.name,
    required this.description,
    required this.selectedColor,
    required this.isLoading,
    this.error,
    required this.isValid,
  });

  // Initial state
  const ListFormState.initial()
    : this(
        name: '',
        description: '',
        selectedColor: Colors.blue,
        isLoading: false,
        isValid: false,
      );

  // Copy with method for state updates
  ListFormState copyWith({
    String? name,
    String? description,
    Color? selectedColor,
    bool? isLoading,
    String? error,
    bool? isValid,
    bool clearError = false,
  }) {
    return ListFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      selectedColor: selectedColor ?? this.selectedColor,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isValid: isValid ?? this.isValid,
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
class ListFormViewModel extends StateNotifier<ListFormState> {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  ListFormViewModel(this._storageService)
    : super(const ListFormState.initial());

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

      final success = await _storageService.createList(newList);

      if (success && mounted) {
        // Reset form on success
        state = const ListFormState.initial();
        return true;
      } else if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create list. Please try again.',
        );
        return false;
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error creating list: ${e.toString()}',
        );
      }
      return false;
    }

    return false;
  }

  // Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider for ListFormViewModel
final listFormViewModelProvider =
    StateNotifierProvider<ListFormViewModel, ListFormState>((ref) {
      return ListFormViewModel(StorageService.instance);
    });
