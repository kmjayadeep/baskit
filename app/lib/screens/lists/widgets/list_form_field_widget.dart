import 'package:flutter/material.dart';

/// Widget for form fields in the create list screen
class ListFormFieldWidget extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback onChanged;
  final TextCapitalization textCapitalization;
  final int maxLines;

  const ListFormFieldWidget({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          validator: validator,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
