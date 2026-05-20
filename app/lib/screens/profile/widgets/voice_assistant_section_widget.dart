import 'package:flutter/material.dart';

import '../../../models/list_member_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../services/alexa_link_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_service.dart';

class VoiceAssistantSectionWidget extends StatefulWidget {
  final bool isAnonymous;
  final bool isFirebaseAvailable;

  const VoiceAssistantSectionWidget({
    super.key,
    required this.isAnonymous,
    required this.isFirebaseAvailable,
  });

  @override
  State<VoiceAssistantSectionWidget> createState() =>
      _VoiceAssistantSectionWidgetState();
}

class _VoiceAssistantSectionWidgetState
    extends State<VoiceAssistantSectionWidget> {
  String? _defaultListId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLinkingAlexa = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultList();
  }

  Future<void> _loadDefaultList() async {
    final defaultListId = await FirestoreService.getDefaultVoiceListId();
    if (!mounted) return;
    setState(() {
      _defaultListId = defaultListId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnonymous || !widget.isFirebaseAvailable) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.record_voice_over),
          title: const Text('Voice Assistant'),
          subtitle: const Text(
            'Sign in with a cloud account to connect Alexa. Local guest lists cannot be used by voice assistants.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ShoppingList>>(
          stream: FirestoreService.getUserLists(),
          builder: (context, snapshot) {
            final writableLists =
                (snapshot.data ?? const <ShoppingList>[])
                    .where(_canCurrentUserWrite)
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.record_voice_over),
                    SizedBox(width: 12),
                    Text(
                      'Voice Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the default cloud list Alexa should use when you do not name a list.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _isLoading)
                  const LinearProgressIndicator()
                else if (writableLists.isEmpty)
                  const Text('Create or join a writable cloud list first.')
                else
                  DropdownButtonFormField<String>(
                    initialValue:
                        writableLists.any((list) => list.id == _defaultListId)
                            ? _defaultListId
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'Default Alexa list',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        writableLists
                            .map(
                              (list) => DropdownMenuItem(
                                value: list.id,
                                child: Text(list.name),
                              ),
                            )
                            .toList(),
                    onChanged: _isSaving ? null : _setDefaultList,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Link or manage Baskit from the Alexa app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isSaving || _defaultListId == null
                              ? null
                              : _clearDefaultList,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLinkingAlexa ? null : _linkAlexaAccount,
                    icon:
                        _isLinkingAlexa
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link),
                    label: Text(
                      _isLinkingAlexa
                          ? 'Linking...'
                          : 'Link Alexa',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _canCurrentUserWrite(ShoppingList list) {
    final userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) return false;

    final member = list.members.where((member) => member.userId == userId);
    if (member.isEmpty) return false;

    final currentMember = member.first;
    if (!currentMember.isActive) return false;
    if (currentMember.role == MemberRole.owner) return true;
    return currentMember.permissions['write'] == true;
  }

  Future<void> _setDefaultList(String? listId) async {
    if (listId == null) return;

    setState(() => _isSaving = true);
    final success = await FirestoreService.setDefaultVoiceListId(listId);
    if (!mounted) return;
    setState(() {
      _defaultListId = success ? listId : _defaultListId;
      _isSaving = false;
    });
    _showResult(
      success ? 'Default Alexa list updated' : 'Could not update list',
    );
  }

  Future<void> _clearDefaultList() async {
    setState(() => _isSaving = true);
    final success = await FirestoreService.clearDefaultVoiceListId();
    if (!mounted) return;
    setState(() {
      _defaultListId = success ? null : _defaultListId;
      _isSaving = false;
    });
    _showResult(
      success ? 'Default Alexa list cleared' : 'Could not clear list',
    );
  }

  Future<void> _linkAlexaAccount() async {
    setState(() => _isLinkingAlexa = true);

    try {
      final user = FirebaseAuthService.currentUser;
      if (user == null) {
        _showResult('Please sign in first.');
        return;
      }

      // Get a fresh Firebase ID token (force refresh)
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        _showResult('Could not get sign-in token. Please sign in again.');
        return;
      }

      final success = await AlexaLinkService.linkAlexaAccount(idToken);

      if (!mounted) return;

      if (success) {
        _showResult('Opening Alexa to complete account linking...');
      } else {
        _showResult('Could not start Alexa linking. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showResult('Could not start Alexa linking. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLinkingAlexa = false);
      }
    }
  }

  void _showResult(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
