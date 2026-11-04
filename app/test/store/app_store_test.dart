import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/app_settings.dart';
import '../data/memory_app_settings_storage.dart';
import 'package:untitled/store/app_store.dart';

void main() {
  late MemoryAppSettingsStorage storage;
  late AppStore store;

  setUp(() {
    storage = MemoryAppSettingsStorage();
    store = AppStore(storage);
  });

  tearDown(() {
    if (!store.isDispose) store.dispose();
  });

  test(
    'restoring missing settings keeps Vietnamese without writing defaults',
    () async {
      await store.restore();

      expect(store.locale.value, const Locale('vi'));
      expect(store.installationId.value, isNull);
      expect(store.readFailed.value, isFalse);
      expect(storage.writes, 0);
    },
  );

  test('restoring saved locale and ID applies both values', () async {
    storage.settings = const AppSettings(
      uiLocale: 'en',
      installationId: '00112233445566778899aabbccddeeff',
    );

    await store.restore();

    expect(store.locale.value, const Locale('en'));
    expect(store.installationId.value, storage.settings!.installationId);
  });

  test(
    'changing locale updates UI immediately and persists separately',
    () async {
      await store.restore();
      final change = store.setLocale(const Locale('en'));

      expect(store.locale.value, const Locale('en'));
      expect(await change, isTrue);
      expect(storage.settings?.uiLocale, 'en');
    },
  );

  test('unsupported locales are rejected', () async {
    await store.restore();

    expect(await store.setLocale(const Locale('fr')), isFalse);
    expect(store.locale.value, const Locale('vi'));
    expect(storage.writes, 0);
  });

  test('unsupported saved locale is not overwritten during restore', () async {
    storage.settings = const AppSettings(uiLocale: 'fr');

    await store.restore();

    expect(store.readFailed.value, isTrue);
    expect(store.locale.value, const Locale('vi'));
    expect(storage.settings?.uiLocale, 'fr');
    expect(storage.writes, 0);
  });

  test('read failure blocks writes until retry succeeds', () async {
    storage.failRead = true;
    await store.restore();

    expect(store.readFailed.value, isTrue);
    expect(await store.setLocale(const Locale('en')), isFalse);
    expect(storage.writes, 0);

    storage.failRead = false;
    await store.retryRead();
    expect(store.readFailed.value, isFalse);
    expect(await store.setLocale(const Locale('en')), isTrue);
  });

  test('write failure retains selected locale for retry', () async {
    await store.restore();
    storage.failWrite = true;

    expect(await store.setLocale(const Locale('en')), isFalse);
    expect(store.locale.value, const Locale('en'));
    expect(store.writeFailed.value, isTrue);

    storage.failWrite = false;
    expect(await store.retryWrite(), isTrue);
    expect(storage.settings?.uiLocale, 'en');
    expect(store.writeFailed.value, isFalse);
  });

  test('failed first ID save retries the same generated ID', () async {
    await store.restore();
    storage.failWrite = true;

    expect(await store.ensureInstallationId(), isFalse);
    final id = store.installationId.value!;

    storage.failWrite = false;
    expect(await store.retryWrite(), isTrue);
    expect(storage.settings?.installationId, id);
  });

  test(
    'installation ID is generated once and restored after restart',
    () async {
      await store.restore();
      expect(await store.ensureInstallationId(), isTrue);
      final id = store.installationId.value!;
      expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(id), isTrue);
      expect(storage.writes, 1);

      store.dispose();
      store = AppStore(storage);
      await store.restore();
      expect(store.installationId.value, id);
      expect(storage.writes, 1);
    },
  );

  test(
    'a pending storage read can finish after the store is disposed',
    () async {
      storage.readGate = Completer<AppSettings?>();
      final restoring = store.restore();
      store.dispose();
      storage.readGate!.complete(const AppSettings(uiLocale: 'en'));

      await expectLater(restoring, completes);
    },
  );

  test(
    'a pending storage write can finish after the store is disposed',
    () async {
      await store.restore();
      storage.writeGate = Completer<void>();
      final saving = store.setLocale(const Locale('en'));
      store.dispose();
      storage.writeGate!.complete();

      expect(await saving, isTrue);
      expect(storage.settings?.uiLocale, 'en');
    },
  );
}
