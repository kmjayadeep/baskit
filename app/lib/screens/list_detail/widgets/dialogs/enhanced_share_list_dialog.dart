import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../models/contact_suggestion_model.dart';
import '../../../../view_models/contact_suggestions_view_model.dart';
import '../../../../constants/app_colors.dart';

/// Enhanced share dialog with autocomplete for contact suggestions
///
/// This version provides intelligent contact suggestions based on previously
/// shared lists while maintaining fallback to manual email entry.
class EnhancedShareListDialog extends ConsumerStatefulWidget {
  final ShoppingList list;
  final Future<void> Function(String email) onShare;

  const EnhancedShareListDialog({
    super.key,
    required this.list,
    required this.onShare,
  });

  @override
  ConsumerState<EnhancedShareListDialog> createState() =>
      _EnhancedShareListDialogState();
}

class _EnhancedShareListDialogState
    extends ConsumerState<EnhancedShareListDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _currentEmailText = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Handle sharing action
  Future<void> _handleShare(String email) async {
    final trimmedEmail = email.trim();
    if (_validateEmail(trimmedEmail) != null) return;

    setState(() => _isLoading = true);

    try {
      await widget.onShare(trimmedEmail);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Build contact suggestion item in dropdown
  Widget _buildContactSuggestionItem(ContactSuggestion contact) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        backgroundImage:
            contact.avatarUrl != null ? NetworkImage(contact.avatarUrl!) : null,
        child:
            contact.avatarUrl == null
                ? Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
      title: Text(
        contact.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.email,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if (contact.sharedListsCount > 1)
            Text(
              '${contact.sharedListsCount} shared lists',
              style: TextStyle(fontSize: 12, color: AppColors.primaryGreen),
            ),
        ],
      ),
      dense: true,
    );
  }

  /// Build the autocomplete field
  Widget _buildAutocompleteField() {
    // Get contact suggestions from ViewModel
    final contactSuggestionsState = ref.watch(
      contactSuggestionsViewModelProvider,
    );
    final allContactSuggestions = contactSuggestionsState.contacts;
    final isLoadingContacts = contactSuggestionsState.isLoading;

    // Filter out contacts who are already members of this list
    final currentMemberUserIds =
        widget.list.members.map((member) => member.userId).toSet();

    final contactSuggestions =
        allContactSuggestions
            .where((contact) => !currentMemberUserIds.contains(contact.userId))
            .toList();

    return Autocomplete<ContactSuggestion>(
      displayStringForOption: (ContactSuggestion option) => option.email,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ContactSuggestion>.empty();
        }

        return contactSuggestions.where((ContactSuggestion contact) {
          return contact.matches(textEditingValue.text);
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final ContactSuggestion contact = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(contact),
                    child: _buildContactSuggestionItem(contact),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (ContactSuggestion contact) {
        // Just populate the field, don't share immediately
        setState(() {
          _emailController.text = contact.email;
          _currentEmailText = contact.email;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        // Sync the autocomplete controller with our email controller
        _emailController.text = controller.text;

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            setState(() {
              _currentEmailText = value;
              _emailController.text = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'Email address',
            hintText:
                isLoadingContacts
                    ? 'Loading contacts...'
                    : contactSuggestions.isEmpty
                    ? 'user@example.com'
                    : 'Start typing to see suggestions...',
            prefixIcon: const Icon(Icons.email_outlined),
            suffixIcon:
                isLoadingContacts
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : contactSuggestions.isNotEmpty
                    ? Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                    : null,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          onFieldSubmitted: (value) {
            if (!_isLoading) {
              _handleShare(value);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.ios_share_outlined,
              size: 20,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Share "${widget.list.name}"',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite someone by email. Suggestions hide people who already have access.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _buildAutocompleteField(),
            // Show error if contact suggestions failed to load
            Consumer(
              builder: (context, ref, child) {
                final contactState = ref.watch(
                  contactSuggestionsViewModelProvider,
                );
                if (contactState.error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Unable to load contact suggestions: ${contactState.error}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_outlined,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invitees can view, edit, and check off items.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleShare(_currentEmailText),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Share'),
        ),
      ],
    );
  }
}
