part of 'list_form_screen.dart';

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
