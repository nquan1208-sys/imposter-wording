import 'dart:convert';
import 'dart:io';
import 'package:untitled/data/local_json_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/models/content.dart';

class ScopedJsonFile implements LocalJsonStore {
  final Future<Directory> Function() directory;
  final String scope;
  final String name;
  ScopedJsonFile({
    required String environment,
    required String backendUrl,
    required String locale,
    required this.name,
    this.directory = getApplicationSupportDirectory,
  }) : scope = jsonEncode([environment, normalizeUrl(backendUrl), locale]);

  static String normalizeUrl(String url) {
    final uri = Uri.parse(url.trim());
    return uri
        .replace(path: uri.path.replaceAll(RegExp(r'/+$'), ''))
        .toString();
  }

  Future<File> get file async {
    final root = await directory();
    final id = base64Url.encode(utf8.encode(scope)).replaceAll('=', '');
    return File('${root.path}/content/$id/$name.json');
  }

  @override
  Future<JsonMap?> read() async {
    final target = await file;
    if (!await target.exists()) return null;
    final json = jsonDecode(await target.readAsString()) as JsonMap;
    if (json['version'] != 1 || json['scope'] != scope) {
      throw const FormatException('Unsupported file or mismatched scope');
    }
    return json['data'] as JsonMap;
  }

  @override
  Future<void> write(JsonMap data) async {
    final target = await file;
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({'version': 1, 'scope': scope, 'data': data}),
        flush: true,
      );
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
