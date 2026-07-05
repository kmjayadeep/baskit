import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_version.dart';
import '../models/whats_new_model.dart';

/// Service to handle app version detection and tracking for "What's New".
class VersionService {
  static const String _lastSeenVersionKey = 'last_seen_version';
  static const String _firstLaunchKey = 'first_launch';

  /// Check if we should attempt to show the "What's New" dialog.
  ///
  /// First installs are baselined to the current version and return false.
  /// Existing installs with an older stored baseline return true.
  static Future<bool> shouldShowWhatsNew({String? currentVersion}) async {
    try {
      final version = currentVersion ?? await getCurrentVersion();
      final lastSeenVersion = await getLastSeenVersion();

      if (lastSeenVersion == null) {
        await markVersionAsSeen(version: version);
        await _markFirstLaunchComplete();
        debugPrint('🔍 First What\'s New baseline saved: $version');
        return false;
      }

      final shouldShow = isNewerVersion(version, lastSeenVersion);

      debugPrint('🔍 VersionService.shouldShowWhatsNew():');
      debugPrint('   - Current version: $version');
      debugPrint('   - Last seen version: $lastSeenVersion');
      debugPrint('   - Should show: $shouldShow');

      return shouldShow;
    } on PlatformException catch (e) {
      debugPrint(
        '❌ Platform error in shouldShowWhatsNew [${e.code}]: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error in shouldShowWhatsNew: $e');
      return false;
    }
  }

  /// Mark a version as seen by the user.
  static Future<void> markVersionAsSeen({String? version}) async {
    try {
      final versionToSave = version ?? await getCurrentVersion();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenVersionKey, versionToSave);

      debugPrint('✅ Marked version $versionToSave as seen');
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error marking version [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error marking version as seen: $e');
    }
  }

  /// Get the current app version.
  static Future<String> getCurrentVersion() async {
    return AppVersion.version;
  }

  /// Get the last seen version from storage.
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

  /// Compare two version strings.
  static int compareVersions(String a, String b) {
    return WhatsNewVersion.compare(a, b);
  }

  /// Determine whether [current] is newer than [lastSeen].
  static bool isNewerVersion(String current, String lastSeen) {
    return compareVersions(current, lastSeen) > 0;
  }

  /// Mark that the legacy first-launch flag has been initialized.
  static Future<void> _markFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
      debugPrint('✅ Marked first launch as complete');
    } on PlatformException catch (e) {
      debugPrint(
        '❌ Platform error marking first launch [${e.code}]: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error marking first launch complete: $e');
    }
  }

  /// Reset version tracking (for testing/debugging).
  static Future<void> resetVersionTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSeenVersionKey);
      await prefs.remove(_firstLaunchKey);
      debugPrint('🔄 Reset version tracking');
    } on PlatformException catch (e) {
      debugPrint(
        '❌ Platform error resetting version [${e.code}]: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error resetting version tracking: $e');
    }
  }
}
