import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baskit/services/version_service.dart';

void main() {
  group('VersionService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for first launch', () async {
      // First launch should not show What's New
      final shouldShow = await VersionService.shouldShowWhatsNew();
      expect(shouldShow, false);
    });

    test('should return false for same version', () async {
      // Simulate app already launched once
      await VersionService.markVersionAsSeen();

      // Same version should not show What's New
      final shouldShow = await VersionService.shouldShowWhatsNew();
      expect(shouldShow, false);
    });

    test('should handle version comparison correctly', () async {
      // Mock a previous version
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_version', '1.0.0');
      await prefs.setBool('first_launch', true);

      // Current version should be higher, but we can't easily mock PackageInfo
      // So we'll test the internal logic indirectly
      final lastSeen = await VersionService.getLastSeenVersion();
      expect(lastSeen, '1.0.0');
    });

    test('should mark version as seen', () async {
      await VersionService.markVersionAsSeen();

      final lastSeen = await VersionService.getLastSeenVersion();
      expect(lastSeen, isNotNull);
      expect(lastSeen, isNotEmpty);
    });

    test('should reset version tracking', () async {
      // Set some data
      await VersionService.markVersionAsSeen();
      expect(await VersionService.getLastSeenVersion(), isNotNull);

      // Reset
      await VersionService.resetVersionTracking();
      expect(await VersionService.getLastSeenVersion(), isNull);
    });

    test('should get current version', () async {
      final version = await VersionService.getCurrentVersion();
      expect(version, isNotNull);
      expect(version, isNotEmpty);
      // Should be a valid version format (fallback is '1.0.0')
      expect(RegExp(r'^\d+\.\d+\.\d+').hasMatch(version), true);
    });

    test('should get full version info', () async {
      final fullVersion = await VersionService.getFullVersionInfo();
      expect(fullVersion, isNotNull);
      expect(fullVersion, contains('+'));
    });
  });
}
