import 'package:untitled/data/content_language_repository.dart';
import 'dart:io';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/models/content.dart';

JsonMap category(
  String id, {
  String type = 'word',
  String locale = 'vi',
  bool family = false,
}) => {
  'id': id,
  'game_type': type,
  'is_family_friendly': family,
  'slug': id,
  'sort_order': 0,
  'is_active': true,
  't': [
    {
      'category_id': id,
      'locale': locale,
      'status': 'published',
      'name': 'Category $id',
      'description': null,
    },
  ],
};
JsonMap word(String id, String categoryId, {String locale = 'vi'}) => {
  'id': id,
  'category_id': categoryId,
  'difficulty': 'easy',
  'image_path': '$id/image.png',
  't': [
    {
      'prompt_id': id,
      'locale': locale,
      'status': 'published',
      'text': 'Word $id',
    },
  ],
};
JsonMap question(String id, String categoryId, {String locale = 'vi'}) => {
  'id': id,
  'category_id': categoryId,
  'difficulty': 'hard',
  't': [
    {
      'prompt_id': id,
      'locale': locale,
      'status': 'published',
      'civilian_question': 'Favorite food?',
      'imposter_question': 'Worst food?',
    },
  ],
};
JsonMap fixture({String locale = 'vi'}) => {
  'categories': [
    category('a', family: true, locale: locale),
    category('b', locale: locale),
    category('empty', locale: locale),
    category('q', type: 'question', locale: locale),
  ],
  'words': [
    word('1', 'a', locale: locale),
    word('2', 'a', locale: locale),
    word('3', 'b', locale: locale),
  ],
  'questions': [question('4', 'q', locale: locale)],
};

Future<List<JsonMap>> fixturePage(
  JsonMap data,
  String table,
  String locale,
  int from,
  int to,
) async {
  final key = {
    'game_categories': 'categories',
    'word_prompts': 'words',
    'question_prompts': 'questions',
  }[table]!;
  return (data[key] as List)
      .cast<JsonMap>()
      .skip(from)
      .take(to - from + 1)
      .toList();
}

class MemoryStorage implements LocalJsonStore {
  JsonMap? data;
  bool failRead = false, failWrite = false;
  int writes = 0;
  MemoryStorage([this.data]);
  @override
  Future<JsonMap?> read() async {
    if (failRead) throw const FileSystemException('read');
    return data;
  }

  @override
  Future<void> write(JsonMap data) async {
    writes++;
    if (failWrite) throw const FileSystemException('write');
    this.data = data;
  }
}

ContentLanguageRepository fixtureLanguages() => ContentLanguageRepository(
  cache: MemoryStorage(),
  fetchPage: (from, to) async => [
    {'code': 'vi', 'display_name': 'Tiếng Việt', 'sort_order': 0},
    {'code': 'en', 'display_name': 'English', 'sort_order': 1},
    {'code': 'ja', 'display_name': '日本語', 'sort_order': 2},
  ].skip(from).take(to - from + 1).toList(),
);

JsonMap localizedFixture(String locale) {
  final data = fixture();
  for (final rows in data.values) {
    for (final row in rows as List) {
      row['t'][0]['locale'] = locale;
      if (row['t'][0].containsKey('name')) {
        row['t'][0]['name'] = '$locale ${row['id']}';
      }
      if (row['t'][0].containsKey('text')) {
        row['t'][0]['text'] = '$locale ${row['id']}';
      }
    }
  }
  return data;
}
