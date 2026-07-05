import 'dart:convert';
import 'dart:typed_data';

import 'package:baskit/constants/app_version.dart';
import 'package:baskit/services/version_service.dart';
import 'package:baskit/widgets/whats_new_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsNewDialog', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    testWidgets('no-content update marks current version seen without dialog', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'last_seen_version': '4.13.53'});
      _mockReleasesAsset('''
{
  "releases": [
    {
      "version": "${AppVersion.version}",
      "title": "Baskit ${AppVersion.version}",
      "items": [
        {
          "type": "improvement",
          "importance": "high",
          "userFacing": false,
          "group": "internal",
          "title": "Internal cleanup",
          "description": "Internal cleanup that users should not see.",
          "icon": "build"
        }
      ]
    }
  ]
}
''');

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await WhatsNewDialog.showIfNeeded(testContext);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await VersionService.getLastSeenVersion(), AppVersion.version);
    });
  });
}

void _mockReleasesAsset(String assetJson) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key != 'assets/whats_new/releases.json') {
          return null;
        }

        return ByteData.sublistView(Uint8List.fromList(utf8.encode(assetJson)));
      });
}
