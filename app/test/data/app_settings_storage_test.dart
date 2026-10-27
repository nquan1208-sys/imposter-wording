import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/models/app_settings.dart';

void main() {
  late Directory directory;
  late HiveLocalStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('app-settings-');
    storage = HiveLocalStorage(directory: () async => directory);
  });

  tearDown(() async {
    await storage.close();
    await directory.delete(recursive: true);
  });

  test('app settings survive a storage restart', () async {
    const settings = AppSettings(
      uiLocale: 'en',
      installationId: '00112233445566778899aabbccddeeff',
    );
    await storage.writeAppSettings(settings);
    await storage.close();
    storage = HiveLocalStorage(directory: () async => directory);

    final restored = await storage.readAppSettings();
    expect(restored?.uiLocale, 'en');
    expect(restored?.installationId, settings.installationId);
  });

  test('a corrupt app settings record is not replaced while reading', () async {
    final box = await Hive.openBox<String>(
      'app_preferences',
      path: '${directory.path}/hive',
    );
    await box.put('settings', '{bad json');
    await box.close();

    await expectLater(storage.readAppSettings(), throwsFormatException);
    await storage.close();
    final reopened = await Hive.openBox<String>(
      'app_preferences',
      path: '${directory.path}/hive',
    );
    expect(reopened.get('settings'), '{bad json');
    await reopened.close();
  });

  test('persisted installation IDs must be 128-bit lowercase hex', () {
    expect(
      () => AppSettings.fromJson({
        'ui_locale': 'vi',
        'installation_id': 'not-an-id',
      }),
      throwsFormatException,
    );
  });
}
