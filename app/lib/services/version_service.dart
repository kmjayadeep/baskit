import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_version.dart';

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
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error in shouldShowWhatsNew [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error in shouldShowWhatsNew: $e');
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
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error marking version [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error marking version as seen: $e');
    }
  }

  /// Get the current app version
  static Future<String> getCurrentVersion() async {
    return AppVersion.version;
  }

  /// Get the last seen version from storage
  static Future<String?> getLastSeenVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSeenVersionKey);
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error getting version [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error getting last seen version: $e');
      return null;
    }
  }

  /// Compare two version strings to determine if first is newer than second
  static bool _isNewerVersion(String current, String lastSeen) {
    try {
      // Simple version comparison for semantic versions (X.Y.Z)
      final currentParts = current.split('.').map(int.parse).toList();
      final lastSeenParts = lastSeen.split('.').map(int.parse).toList();

      // Ensure both have at least 3 parts (major.minor.patch)
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (lastSeenParts.length < 3) {
        lastSeenParts.add(0);
      }

      // Compare major, minor, patch
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] > lastSeenParts[i]) return true;
        if (currentParts[i] < lastSeenParts[i]) return false;
      }

      return false; // Versions are equal
    } on FormatException catch (e) {
      debugPrint('❌ Version parse error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error comparing versions: $e');
      return false;
    }
  }

  /// Check if this is the first app launch
  static Future<bool> _isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey(_firstLaunchKey);
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error checking first launch [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error checking first launch: $e');
      return false;
    }
  }

  /// Mark that the first launch is complete
  static Future<void> _markFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
      debugPrint('✅ Marked first launch as complete');
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error marking first launch [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error marking first launch complete: $e');
    }
  }

  /// Reset version tracking (for testing/debugging)
  static Future<void> resetVersionTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSeenVersionKey);
      await prefs.remove(_firstLaunchKey);
      debugPrint('🔄 Reset version tracking');
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error resetting version [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error resetting version tracking: $e');
    }
  }
}
