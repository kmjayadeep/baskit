import 'package:flutter/material.dart';

/// Widget for picking colors in the create list screen
class ColorPickerWidget extends StatelessWidget {
  final Color selectedColor;
  final List<Color> availableColors;
  final Function(Color) onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.availableColors,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Color',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              availableColors.map((color) {
                final isSelected = color == selectedColor;
                return GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border:
                          isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
