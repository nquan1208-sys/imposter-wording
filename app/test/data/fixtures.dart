import 'dart:io';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/models/content.dart';

JsonMap category(String id, {String type = 'word', String locale = 'vi'}) => {
  'id': id,
  'game_type': type,
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
JsonMap word(
  String id,
  String categoryId, {
  bool family = false,
  String locale = 'vi',
}) => {
  'id': id,
  'category_id': categoryId,
  'difficulty': 'easy',
  'is_family_friendly': family,
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
JsonMap question(String id, String categoryId) => {
  'id': id,
  'category_id': categoryId,
  'difficulty': 'hard',
  'is_family_friendly': true,
  't': [
    {
      'prompt_id': id,
      'locale': 'vi',
      'status': 'published',
      'civilian_question': 'Favorite food?',
      'imposter_question': 'Worst food?',
    },
  ],
};
JsonMap fixture() => {
  'categories': [
    category('a'),
    category('b'),
    category('empty'),
    category('q', type: 'question'),
  ],
  'words': [word('1', 'a'), word('2', 'a', family: true), word('3', 'b')],
  'questions': [question('4', 'q')],
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
