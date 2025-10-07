import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../models/contact_suggestion_model.dart';
import '../../../../view_models/contact_suggestions_view_model.dart';

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
  bool _isLoading = false;
  String _currentEmailText = '';

  @override
  void dispose() {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage:
            contact.avatarUrl != null ? NetworkImage(contact.avatarUrl!) : null,
        child:
            contact.avatarUrl == null
                ? Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
      ),
      title: Text(
        contact.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.email,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (contact.sharedListsCount > 1)
            Text(
              '${contact.sharedListsCount} shared lists',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
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
    final contactSuggestions = contactSuggestionsState.contacts;
    final isLoadingContacts = contactSuggestionsState.isLoading;

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
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
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
        _handleShare(contact.email);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            setState(() {
              _currentEmailText = value;
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
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email),
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
      title: Row(
        children: [
          const Icon(Icons.share, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Share "${widget.list.name}"',
              overflow: TextOverflow.ellipsis,
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
            const Text(
              'Enter an email address or select from your contacts:',
              style: TextStyle(fontSize: 14),
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
            Text(
              'The person will be able to view and edit this list.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
