import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/models/content.dart';

class WordImageCache extends ChangeNotifier {
  static const maxBytes = 5 * 1024 * 1024;
  final String backendUrl;
  final Future<Directory> Function() directory;
  final Future<String> Function(String path) signedUrl;
  final Future<Set<String>> Function() inventory;
  final Duration requestTimeout;
  final _files = <String, File>{};
  final _pending = <String>{};
  final _failed = <String>{};
  final _pins = <String, int>{};
  final _snapshots = <String, Set<String>>{};
  Set<String> get _current =>
      _snapshots.values.expand((paths) => paths).toSet();
  Future<void> _queue = Future.value();
  bool _disposed = false;

  WordImageCache({
    required this.backendUrl,
    required this.signedUrl,
    required this.inventory,
    this.directory = getApplicationSupportDirectory,
    this.requestTimeout = const Duration(seconds: 15),
  });

  Future<void> get pending => _queue;
  File? file(String path) => _files[path];

  // Chunk encoded keys to respect filesystem component limits without collisions.
  String _key(String value) {
    final encoded = base64Url.encode(utf8.encode(value)).replaceAll('=', '');
    return [
      for (var i = 0; i < encoded.length; i += 120)
        encoded.substring(
          i,
          i + 120 > encoded.length ? encoded.length : i + 120,
        ),
    ].join('/');
  }

  Future<Directory> get _root async => Directory(
    '${(await directory()).path}/word-images/${_key(ScopedJsonFile.normalizeUrl(backendUrl))}',
  );
  Future<File> _target(String path) async =>
      File('${(await _root).path}/${_key(path)}/image');

  void _enqueue(Future<void> Function() action) {
    _queue = _queue
        .then((_) async {
          if (!_disposed) await action();
        })
        .catchError((Object _) {
          // An unavailable disk or image must never stop the remaining queue.
        });
  }

  void refresh(ContentSnapshot snapshot, {bool retryFailures = true}) {
    if (retryFailures) _failed.clear();
    _snapshots[snapshot.contentLocale] = snapshot.words
        .map((w) => w.imagePath)
        .whereType<String>()
        .toSet();
    final requested = {
      ..._current,
      ..._pins.keys,
    }.where((path) => !_failed.contains(path) && _pending.add(path)).toList();
    // Restore every offline file before a missing image can occupy the network queue.
    for (final path in requested) {
      _enqueue(() => _restore(path));
    }
    for (final path in requested) {
      _enqueue(() async {
        try {
          await _ensure(path);
        } catch (_) {
          _failed.add(path);
        } finally {
          _pending.remove(path);
        }
      });
    }
    _enqueue(_cleanup);
  }

  VoidCallback pin(String? path) {
    if (path == null) return () {};
    _pins.update(path, (n) => n + 1, ifAbsent: () => 1);
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (_pins[path] == 1) {
        _pins.remove(path);
      } else {
        _pins[path] = _pins[path]! - 1;
      }
      _enqueue(_cleanup);
    };
  }

  Future<void> _validate(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException('Invalid image size');
    }
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  }

  Future<Uint8List> _download(String url) async {
    final client = HttpClient();
    try {
      return await (() async {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          final error = BytesBuilder(copy: false);
          await for (final chunk in response) {
            error.add(chunk.take(4096 - error.length).toList());
            if (error.length >= 4096) break;
          }
          final message = utf8
              .decode(error.takeBytes(), allowMalformed: true)
              .toLowerCase();
          throw _DownloadFailure(
            response.statusCode == 401 ||
                response.statusCode == 403 ||
                (response.statusCode == 400 && message.contains('expired')),
          );
        }
        if (!const [
              'image/jpeg',
              'image/png',
              'image/webp',
            ].contains(response.headers.contentType?.mimeType) ||
            response.contentLength > maxBytes) {
          throw const FormatException('Invalid image response');
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response) {
          if (bytes.length + chunk.length > maxBytes) {
            throw const FormatException('Image too large');
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _restore(String path) async {
    final target = await _target(path);
    if (!await target.exists()) {
      if (_files.remove(path) != null && !_disposed) notifyListeners();
      return;
    }
    try {
      if (await target.length() > maxBytes) {
        throw const FormatException('Image too large');
      }
      await _validate(await target.readAsBytes());
      _publish(path, target);
      return;
    } catch (_) {
      if (_files.remove(path) != null && !_disposed) notifyListeners();
      await target.delete();
    }
  }

  Future<void> _ensure(String path) async {
    if (_files.containsKey(path)) return;
    final target = await _target(path);
    Uint8List? bytes;
    for (var attempt = 0; attempt < 2; attempt++) {
      final url = await signedUrl(path).timeout(requestTimeout);
      try {
        bytes = await _download(url);
        break;
      } on _DownloadFailure catch (e) {
        if (attempt != 0 || !e.renewUrl) {
          rethrow;
        }
      }
    }
    await _validate(bytes!);
    if (_disposed) return;
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
      _publish(path, target);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  void _publish(String path, File target) {
    if (_disposed) return;
    _files[path] = target;
    notifyListeners();
  }

  Future<void> _cleanup() async {
    // Validate inventory before listing, then recheck immediately before deletion.
    final persisted = await inventory();
    final root = await _root;
    if (!await root.exists()) return;
    final initialTargets = {
      for (final path in {...persisted, ..._current, ..._pins.keys})
        '${root.path}/${_key(path)}/image',
    };
    await for (final entry in root.list(recursive: true, followLinks: false)) {
      if (entry is! File || initialTargets.contains(entry.path)) continue;
      final retained = {...await inventory(), ..._current, ..._pins.keys};
      final targets = {
        for (final path in retained) '${root.path}/${_key(path)}/image',
      };
      if (!targets.contains(entry.path)) {
        await entry.delete();
        _files.removeWhere((_, file) => file.path == entry.path);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _DownloadFailure implements Exception {
  final bool renewUrl;
  _DownloadFailure(this.renewUrl);
}
