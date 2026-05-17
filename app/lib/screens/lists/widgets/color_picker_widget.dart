import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

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
          'Choose color',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? color.withValues(alpha: 0.14)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
