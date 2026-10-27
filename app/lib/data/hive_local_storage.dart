import 'dart:convert';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';

class HiveLocalStorage {
  final Future<Directory> Function() directory;
  final _boxes = <String, Future<Box<String>>>{};
  Future<void> _operations = Future.value();
  Future<void>? _closing;
  final _pendingWriters = <Future<void>>[];
  bool _closed = false;

  HiveLocalStorage({this.directory = getApplicationSupportDirectory});

  LocalJsonStore scoped({
    required String environment,
    required String backendUrl,
    required String locale,
    required String name,
  }) {
    if (name != 'setup' && name != 'snapshot') {
      throw ArgumentError.value(name, 'name');
    }
    return _HiveJsonStore(
      this,
      ScopedJsonFile(
        environment: environment,
        backendUrl: backendUrl,
        locale: locale,
        name: name,
        directory: directory,
      ),
      locale,
    );
  }

  /// Read all locales without importing or changing legacy records.
  /// A corrupt inventory throws so callers cannot prune potentially used images.
  Future<Set<String>> imageReferences(String backendUrl) => _run(() async {
    final backend = ScopedJsonFile.normalizeUrl(backendUrl);
    final paths = <String>{};
    void collect(String scope, JsonMap envelope) {
      final parts = jsonDecode(scope) as List;
      if (parts.length != 3 || parts.any((p) => p is! String)) {
        throw const FormatException('Invalid snapshot scope');
      }
      if (parts[1] != backend) return;
      if (envelope['version'] != 1 || envelope['scope'] != scope) {
        throw const FormatException('Invalid snapshot envelope');
      }
      final snapshot = ContentSnapshot.fromJson(
        envelope['data'] as JsonMap,
        parts[2] as String,
      );
      paths.addAll(snapshot.words.map((w) => w.imagePath).whereType<String>());
    }

    final box = await _box('content_cache');
    for (final key in box.keys) {
      collect(key as String, jsonDecode(box.get(key)!) as JsonMap);
    }
    final legacyRoot = Directory('${(await directory()).path}/content');
    if (await legacyRoot.exists()) {
      await for (final entry in legacyRoot.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is File && entry.uri.pathSegments.last == 'snapshot.json') {
          final envelope = jsonDecode(await entry.readAsString()) as JsonMap;
          collect(envelope['scope'] as String, envelope);
        }
      }
    }
    return paths;
  });

  Future<Set<String>> localImageReferences() => _run(() async {
    final ids = <String>{};
    void collect(String scope, JsonMap envelope) {
      final parts = jsonDecode(scope) as List;
      if (parts.length != 3 ||
          parts.any((p) => p is! String) ||
          envelope['version'] != 1 ||
          envelope['scope'] != scope) {
        throw const FormatException('Invalid setup inventory');
      }
      ids.addAll(GameSetup.fromJson(envelope['data'] as JsonMap).localImageIds);
    }

    final box = await _box('settings');
    for (final key in box.keys) {
      collect(key as String, jsonDecode(box.get(key)!) as JsonMap);
    }
    final legacyRoot = Directory('${(await directory()).path}/content');
    if (await legacyRoot.exists()) {
      await for (final entry in legacyRoot.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is File && entry.uri.pathSegments.last == 'setup.json') {
          final envelope = jsonDecode(await entry.readAsString()) as JsonMap;
          final scope = envelope['scope'] as String;
          if (!box.containsKey(scope)) collect(scope, envelope);
        }
      }
    }
    return ids;
  });

  Future<Box<String>> _box(String name) => _boxes.putIfAbsent(name, () async {
    try {
      final root = await directory();
      return await Hive.openBox<String>(name, path: '${root.path}/hive');
    } catch (_) {
      _boxes.remove(name);
      rethrow;
    }
  });

  // Serialize migration and writes so a late import cannot replace newer data.
  Future<T> _run<T>(Future<T> Function() action) {
    if (_closed) return Future.error(StateError('Storage is closed'));
    final result = _operations.then((_) => action());
    _operations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  // Owners hand off their write queues when disposed before this dependency.
  void waitBeforeClose(Future<void> writes) => _pendingWriters.add(writes);

  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    await Future.wait(_pendingWriters);
    _closed = true;
    await _operations;
    for (final box in _boxes.values) {
      await (await box).close();
    }
    _boxes.clear();
  }
}

class _HiveJsonStore implements LocalJsonStore {
  final HiveLocalStorage storage;
  final ScopedJsonFile legacy;
  final String locale;
  _HiveJsonStore(this.storage, this.legacy, this.locale);
  String get boxName => legacy.name == 'setup' ? 'settings' : 'content_cache';

  void _validate(JsonMap data) {
    if (legacy.name == 'setup') {
      GameSetup.fromJson(data);
    } else {
      ContentSnapshot.fromJson(data, locale);
    }
  }

  String _encode(JsonMap data) =>
      jsonEncode({'version': 1, 'scope': legacy.scope, 'data': data});

  @override
  Future<JsonMap?> read() => storage._run(() async {
    final box = await storage._box(boxName);
    if (box.containsKey(legacy.scope)) {
      final envelope = jsonDecode(box.get(legacy.scope)!) as JsonMap;
      if (envelope['version'] != 1 || envelope['scope'] != legacy.scope) {
        throw const FormatException('Unsupported record or mismatched scope');
      }
      final data = envelope['data'] as JsonMap;
      _validate(data);
      return data;
    }
    final data = await legacy.read();
    if (data != null) {
      _validate(data);
      await box.put(legacy.scope, _encode(data));
    }
    return data;
  });

  @override
  Future<void> write(JsonMap data) {
    // Capture the value before it waits behind other operations.
    _validate(data);
    final encoded = _encode(data);
    return storage._run(() async {
      final box = await storage._box(boxName);
      await box.put(legacy.scope, encoded);
    });
  }
}
