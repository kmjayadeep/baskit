import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle app version detection and tracking for "What's New" feature
class VersionService {
  static const String _lastSeenVersionKey = 'last_seen_version';
  static const String _firstLaunchKey = 'first_launch';

  /// Check if we should show the "What's New" dialog
  ///
  /// Returns true if:
  /// - This is not the first app launch (don't show for new users)
  /// - Current version is newer than last seen version
  static Future<bool> shouldShowWhatsNew() async {
    try {
      // Check if this is the first launch
      if (await _isFirstLaunch()) {
        // Mark as not first launch and save current version
        await _markFirstLaunchComplete();
        await markVersionAsSeen();
        return false;
      }

      final currentVersion = await getCurrentVersion();
      final lastSeenVersion = await getLastSeenVersion();

      if (lastSeenVersion == null) {
        // No previous version recorded, mark current and don't show
        await markVersionAsSeen();
        return false;
      }

      // Show if current version is newer than last seen
      final shouldShow = _isNewerVersion(currentVersion, lastSeenVersion);

      debugPrint('🔍 VersionService.shouldShowWhatsNew():');
      debugPrint('   - Current version: $currentVersion');
      debugPrint('   - Last seen version: $lastSeenVersion');
      debugPrint('   - Should show: $shouldShow');

      return shouldShow;
    } catch (e) {
      debugPrint('❌ Error in shouldShowWhatsNew: $e');
      return false;
    }
  }

  /// Mark the current version as seen by the user
  static Future<void> markVersionAsSeen() async {
    try {
      final currentVersion = await getCurrentVersion();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenVersionKey, currentVersion);

      debugPrint('✅ Marked version $currentVersion as seen');
    } catch (e) {
      debugPrint('❌ Error marking version as seen: $e');
    }
  }

  /// Get the current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('❌ Error getting current version: $e');
      return '1.0.0'; // Fallback version
    }
  }

  /// Get the last seen version from storage
  static Future<String?> getLastSeenVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSeenVersionKey);
    } catch (e) {
      debugPrint('❌ Error getting last seen version: $e');
      return null;
    }
  }

  /// Compare two version strings to determine if first is newer than second
  static bool _isNewerVersion(String current, String lastSeen) {
    try {
      final currentVer = Version.parse(current);
      final lastSeenVer = Version.parse(lastSeen);
      return currentVer > lastSeenVer;
    } catch (e) {
      debugPrint('❌ Error comparing versions: $e');
      // If version parsing fails, assume it's not newer to be safe
      return false;
    }
  }

  /// Check if this is the first app launch
  static Future<bool> _isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey(_firstLaunchKey);
    } catch (e) {
      debugPrint('❌ Error checking first launch: $e');
      return false;
    }
  }

  /// Mark that the first launch is complete
  static Future<void> _markFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
      debugPrint('✅ Marked first launch as complete');
    } catch (e) {
      debugPrint('❌ Error marking first launch complete: $e');
    }
  }

  /// Get app build number (for debugging)
  static Future<String> getBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      debugPrint('❌ Error getting build number: $e');
      return '1';
    }
  }

  /// Get full version info (for debugging)
  static Future<String> getFullVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('❌ Error getting full version info: $e');
      return '1.0.0+1';
    }
  }

  /// Reset version tracking (for testing/debugging)
  static Future<void> resetVersionTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSeenVersionKey);
      await prefs.remove(_firstLaunchKey);
      debugPrint('🔄 Reset version tracking');
    } catch (e) {
      debugPrint('❌ Error resetting version tracking: $e');
    }
  }
}
