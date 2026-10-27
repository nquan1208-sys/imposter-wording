import 'dart:math';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/models/app_settings.dart';

class AppStore extends StoreBase {
  static const defaultLocale = Locale('vi');

  final HiveLocalStorage storage;
  final _autoDisposeManager = AutoDisposeManager();
  AppSettings? _settings;
  Future<void>? _restore;
  bool _ready = false;

  late final locale = signal(defaultLocale).manageBy(_autoDisposeManager);
  late final installationId = signal<String?>(
    null,
  ).manageBy(_autoDisposeManager);
  late final loading = signal(false).manageBy(_autoDisposeManager);
  late final readFailed = signal(false).manageBy(_autoDisposeManager);
  late final writing = signal(false).manageBy(_autoDisposeManager);
  late final writeFailed = signal(false).manageBy(_autoDisposeManager);

  AppStore(this.storage);

  bool get ready => _ready;

  Future<void> restore() {
    if (_ready) return Future.value();
    return _restore ??= _restoreSettings();
  }

  Future<void> _restoreSettings() async {
    loading.value = true;
    readFailed.value = false;
    try {
      final saved = await storage.readAppSettings();
      if (isDispose) return;
      final settings = saved ?? const AppSettings(uiLocale: 'vi');
      if (!AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == settings.uiLocale,
      )) {
        throw const FormatException('Unsupported UI locale');
      }
      _settings = settings;
      locale.value = Locale(settings.uiLocale);
      installationId.value = settings.installationId;
      _ready = true;
    } catch (_) {
      if (!isDispose) {
        readFailed.value = true;
        _restore = null;
      }
    } finally {
      if (!isDispose) loading.value = false;
    }
  }

  Future<void> retryRead() {
    if (_ready && !readFailed.value) return Future.value();
    _restore = null;
    return restore();
  }

  Future<bool> setLocale(Locale value) {
    if (!_canWrite || !AppLocalizations.supportedLocales.contains(value)) {
      return Future.value(false);
    }
    final current = _settings!;
    if (current.uiLocale == value.languageCode) {
      return writeFailed.value ? retryWrite() : Future.value(true);
    }
    return _save(current.copyWith(uiLocale: value.languageCode));
  }

  Future<bool> ensureInstallationId() {
    if (!_canWrite) return Future.value(false);
    if (installationId.value != null) {
      return writeFailed.value ? retryWrite() : Future.value(true);
    }
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return _save(_settings!.copyWith(installationId: id));
  }

  Future<bool> retryWrite() {
    if (!_canWrite) return Future.value(false);
    return _save(_settings!);
  }

  bool get _canWrite => _ready && !readFailed.value && !writing.value;

  Future<bool> _save(AppSettings value) async {
    _settings = value;
    locale.value = Locale(value.uiLocale);
    installationId.value = value.installationId;
    writing.value = true;
    try {
      await storage.writeAppSettings(value);
      if (isDispose) return true;
      writeFailed.value = false;
      return true;
    } catch (_) {
      if (!isDispose) writeFailed.value = true;
      return false;
    } finally {
      if (!isDispose) writing.value = false;
    }
  }

  @override
  void dispose() {
    _autoDisposeManager.cancelAll();
    super.dispose();
  }
}
