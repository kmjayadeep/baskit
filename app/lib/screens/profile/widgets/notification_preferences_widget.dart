import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../services/notification_preferences_service.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  NotificationPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await NotificationPreferencesService.load();
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  Future<void> _updatePreferences(NotificationPreferences preferences) async {
    setState(() => _preferences = preferences);
    await NotificationPreferencesService.save(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose which shared-list updates should alert you.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preferences == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _PreferenceSwitch(
              title: 'Shared list changes',
              subtitle:
                  'Items are added, edited, or removed from shared lists.',
              value: preferences.sharedListChanges,
              onChanged:
                  (value) => _updatePreferences(
                    preferences.copyWith(sharedListChanges: value),
                  ),
            ),
            _PreferenceSwitch(
              title: 'Item completions',
              subtitle: 'Someone marks an item complete or incomplete.',
              value: preferences.itemCompletions,
              onChanged:
                  (value) => _updatePreferences(
                    preferences.copyWith(itemCompletions: value),
                  ),
            ),
            _PreferenceSwitch(
              title: 'New members',
              subtitle: 'People join or are added to a shared list.',
              value: preferences.newMembers,
              onChanged:
                  (value) => _updatePreferences(
                    preferences.copyWith(newMembers: value),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: AppColors.primaryGreen,
      onChanged: onChanged,
    );
  }
}
