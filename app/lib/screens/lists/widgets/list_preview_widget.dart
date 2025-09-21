import 'package:flutter/material.dart';

/// Widget that shows a preview of how the list will look
class ListPreviewWidget extends StatelessWidget {
  final String name;
  final String description;
  final Color selectedColor;

  const ListPreviewWidget({
    super.key,
    required this.name,
    required this.description,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name.trim().isEmpty ? 'Your List Name' : name.trim(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description.trim(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '0 items',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(selectedColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
