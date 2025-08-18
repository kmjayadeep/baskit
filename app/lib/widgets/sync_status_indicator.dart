import 'package:flutter/material.dart';
import '../services/sync_service.dart';

/// Widget that displays the current sync status with visual indicators
/// Shows real-time sync activity (idle, syncing, synced, error)
class SyncStatusIndicator extends StatelessWidget {
  final bool showText;
  final bool showTooltip;

  const SyncStatusIndicator({
    super.key,
    this.showText = true,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncService.instance.syncStateNotifier,
      builder: (context, syncState, child) {
        final syncInfo = _getSyncInfo(syncState);

        Widget indicator = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncInfo),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                syncInfo.text,
                style: TextStyle(
                  color: syncInfo.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );

        // Wrap with tooltip if enabled
        if (showTooltip) {
          final errorMessage = SyncService.instance.lastErrorMessage;
          final tooltipMessage =
              syncState == SyncState.error && errorMessage != null
                  ? 'Sync Error: $errorMessage'
                  : _getTooltipMessage(syncState);

          indicator = Tooltip(message: tooltipMessage, child: indicator);
        }

        return indicator;
      },
    );
  }

  /// Build the appropriate icon for the sync state
  Widget _buildIcon(_SyncInfo syncInfo) {
    if (syncInfo.isAnimated) {
      // Animated icon for syncing state
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(syncInfo.color),
        ),
      );
    }

    return Icon(syncInfo.icon, color: syncInfo.color, size: 16);
  }

  /// Get sync information based on current state
  _SyncInfo _getSyncInfo(SyncState syncState) {
    switch (syncState) {
      case SyncState.idle:
        return _SyncInfo(
          icon: Icons.sync_disabled,
          color: Colors.grey,
          text: 'Idle',
          isAnimated: false,
        );
      case SyncState.syncing:
        return _SyncInfo(
          icon: Icons.sync,
          color: Colors.blue,
          text: 'Syncing',
          isAnimated: true,
        );
      case SyncState.synced:
        return _SyncInfo(
          icon: Icons.sync_alt,
          color: Colors.green,
          text: 'Synced',
          isAnimated: false,
        );
      case SyncState.error:
        return _SyncInfo(
          icon: Icons.sync_problem,
          color: Colors.red,
          text: 'Error',
          isAnimated: false,
        );
    }
  }

  /// Get tooltip message for the sync state
  String _getTooltipMessage(SyncState syncState) {
    switch (syncState) {
      case SyncState.idle:
        return 'Sync is idle - no active synchronization';
      case SyncState.syncing:
        return 'Synchronizing data with cloud...';
      case SyncState.synced:
        return 'Data successfully synchronized';
      case SyncState.error:
        return 'Sync error occurred - tap for details';
    }
  }
}

/// Internal class to hold sync display information
class _SyncInfo {
  final IconData icon;
  final Color color;
  final String text;
  final bool isAnimated;

  const _SyncInfo({
    required this.icon,
    required this.color,
    required this.text,
    required this.isAnimated,
  });
}
