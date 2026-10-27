import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:untitled/models/content.dart';

class LocalImageException implements Exception {
  final bool oversized;
  const LocalImageException({this.oversized = false});
}

/// Owns copied attachments only; source-library files are never deleted.
class LocalImageStore {
  final Future<Directory> Function() directory;
  final Future<Set<String>> Function() inventory;
  final _owners = <Object, Set<String>>{};
  Future<void> _queue = Future.value();
  LocalImageStore({
    required this.inventory,
    this.directory = getApplicationSupportDirectory,
  });

  Future<T> _run<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // Keep setup commits and reference inventories in the same file-operation queue.
  Future<void> persist(Future<void> Function() write) => _run(write);

  void retain(Object owner, Iterable<String> ids) {
    final values = ids.toSet();
    if (values.any((id) => !validLocalImageId(id))) {
      throw const FormatException('Invalid local image ID');
    }
    _owners[owner] = values;
  }

  void release(Object owner) {
    _owners.remove(owner);
    cleanup();
  }

  Future<Directory> get _root async =>
      Directory('${(await directory()).path}/custom-images');
  Future<File> file(String id) async {
    if (!validLocalImageId(id)) {
      throw const FormatException('Invalid local image ID');
    }
    return File('${(await _root).path}/$id');
  }

  Future<String> import(File source, Object owner) => _run(() async {
    const limit = 5 * 1024 * 1024;
    late List<int> bytes;
    try {
      if (await source.length() > limit) {
        throw const LocalImageException(oversized: true);
      }
      bytes = await source
          .openRead(0, limit + 1)
          .fold<List<int>>([], (a, b) => a..addAll(b));
    } on FileSystemException {
      throw const LocalImageException();
    }
    if (bytes.length > limit) throw const LocalImageException(oversized: true);
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(bytes),
      );
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          final codec = await descriptor.instantiateCodec(targetWidth: 512);
          try {
            final frame = await codec.getNextFrame();
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } catch (_) {
      throw const LocalImageException();
    }
    final root = await _root;
    await root.create(recursive: true);
    final random = Random.secure();
    final id =
        '${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}.img';
    final temporary = File('${root.path}/$id.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename('${root.path}/$id');
      _owners.putIfAbsent(owner, () => {}).add(id);
      return id;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  });
  Future<void> cleanup() => _run(() async {
    try {
      final persisted = await inventory();
      final root = await _root;
      if (!await root.exists()) return;
      await for (final entry in root.list(followLinks: false)) {
        if (entry is File &&
            !persisted.contains(entry.uri.pathSegments.last) &&
            !_owners.values.any(
              (ids) => ids.contains(entry.uri.pathSegments.last),
            )) {
          try {
            await entry.delete();
          } catch (_) {
            /* Retry on next cleanup. */
          }
        }
      }
    } catch (_) {
      /* An unreadable inventory must never trigger pruning. */
    }
  });
}
