import 'package:baskit/services/version_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('VersionService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false and save baseline for first install', () async {
      final shouldShow = await VersionService.shouldShowWhatsNew(
        currentVersion: '2.0.0',
      );

      expect(shouldShow, false);
      expect(await VersionService.getLastSeenVersion(), '2.0.0');
    });

    test('should return false for same version', () async {
      await VersionService.markVersionAsSeen(version: '2.0.0');

      final shouldShow = await VersionService.shouldShowWhatsNew(
        currentVersion: '2.0.0',
      );

      expect(shouldShow, false);
      expect(await VersionService.getLastSeenVersion(), '2.0.0');
    });

    test('should return true for one-version update', () async {
      await VersionService.markVersionAsSeen(version: '2.0.0');

      final shouldShow = await VersionService.shouldShowWhatsNew(
        currentVersion: '2.0.1',
      );

      expect(shouldShow, true);
      expect(await VersionService.getLastSeenVersion(), '2.0.0');
    });

    test('should return true for skipped-version update', () async {
      await VersionService.markVersionAsSeen(version: '2.0.0');

      final shouldShow = await VersionService.shouldShowWhatsNew(
        currentVersion: '2.2.0',
      );

      expect(shouldShow, true);
      expect(await VersionService.getLastSeenVersion(), '2.0.0');
    });

    test(
      'should honor existing last_seen_version without first_launch flag',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_seen_version', '1.0.0');

        final shouldShow = await VersionService.shouldShowWhatsNew(
          currentVersion: '1.0.1',
        );

        expect(shouldShow, true);
      },
    );

    test('should mark version as seen', () async {
      await VersionService.markVersionAsSeen(version: '3.0.0');

      final lastSeen = await VersionService.getLastSeenVersion();
      expect(lastSeen, '3.0.0');
    });

    test('should reset version tracking', () async {
      await VersionService.markVersionAsSeen(version: '3.0.0');
      expect(await VersionService.getLastSeenVersion(), isNotNull);

      await VersionService.resetVersionTracking();
      expect(await VersionService.getLastSeenVersion(), isNull);
    });

    test('should compare versions correctly', () {
      expect(VersionService.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionService.compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(VersionService.compareVersions('2.0.0', '10.0.0'), lessThan(0));
      expect(VersionService.compareVersions('1.0', '1.0.0'), 0);
      expect(VersionService.isNewerVersion('1.0.1', '1.0.0'), true);
      expect(VersionService.isNewerVersion('1.0.0', '1.0.0'), false);
    });
  });
}
