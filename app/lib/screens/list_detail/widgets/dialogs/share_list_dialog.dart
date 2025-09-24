import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';

class ShareListDialog extends StatefulWidget {
  final ShoppingList list;
  final Future<void> Function(String email) onShare;

  const ShareListDialog({super.key, required this.list, required this.onShare});

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  late final TextEditingController emailController;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        await widget.onShare(emailController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share, size: 24),
          const SizedBox(width: 8),
          Text('Share "${widget.list.name}"'),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email address of the person you want to share this list with:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              autofocus: true,
              onFieldSubmitted: (_) => _handleShare(),
            ),
            const SizedBox(height: 16),
            const Text(
              'The person will be able to view and edit this list.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _handleShare,
          child:
              isLoading
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
