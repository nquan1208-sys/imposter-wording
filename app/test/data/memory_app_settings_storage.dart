import 'dart:async';
import 'dart:io';

import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/models/app_settings.dart';

class MemoryAppSettingsStorage extends HiveLocalStorage {
  MemoryAppSettingsStorage({
    this.settings,
    this.failRead = false,
    this.failWrite = false,
  }) : super(directory: () async => Directory.systemTemp);

  AppSettings? settings;
  bool failRead;
  bool failWrite;
  int writes = 0;
  Completer<AppSettings?>? readGate;
  Completer<void>? writeGate;

  @override
  Future<AppSettings?> readAppSettings() async {
    if (failRead) throw const FormatException('read failed');
    if (readGate != null) return readGate!.future;
    return settings;
  }

  @override
  Future<void> writeAppSettings(AppSettings value) async {
    writes++;
    await writeGate?.future;
    if (failWrite) throw const FileSystemException('write failed');
    settings = value;
  }
}
