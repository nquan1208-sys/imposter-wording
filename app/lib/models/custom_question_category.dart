import 'package:untitled/models/content.dart';

class CustomQuestionEntry {
  final String civilianQuestion, imposterQuestion;
  final String? imageId;

  CustomQuestionEntry(String civilian, String imposter, {this.imageId})
    : civilianQuestion = civilian.trim(),
      imposterQuestion = imposter.trim() {
    if ((imageId != null && !validLocalImageId(imageId!)) ||
        civilianQuestion.isEmpty ||
        imposterQuestion.isEmpty ||
        civilianQuestion.toLowerCase() == imposterQuestion.toLowerCase()) {
      throw const FormatException('Invalid question pair');
    }
  }

  (String, String) get key =>
      (civilianQuestion.toLowerCase(), imposterQuestion.toLowerCase());

  factory CustomQuestionEntry.fromJson(JsonMap json) => CustomQuestionEntry(
    requiredText(json, 'civilianQuestion'),
    requiredText(json, 'imposterQuestion'),
    imageId: json['imageId'] as String?,
  );

  JsonMap toJson() => {
    'civilianQuestion': civilianQuestion,
    'imposterQuestion': imposterQuestion,
    'imageId': imageId,
  };
}

class QuestionImportException implements Exception {
  final List<int> rows;
  final bool unequalCounts;
  QuestionImportException(Iterable<int> rows, {this.unequalCounts = false})
    : rows = List.unmodifiable(rows);
}

List<CustomQuestionEntry> parseQuestionPairs(
  String civilian,
  String imposter, {
  bool batch = false,
  List<CustomQuestionEntry> existing = const [],
}) {
  List<String> lines(String text) {
    final rows = text.replaceAll('\r\n', '\n').split('\n');
    if (rows.length > 1 && rows.last.isEmpty) rows.removeLast();
    return rows;
  }

  final civilians = batch ? lines(civilian) : [civilian];
  final imposters = batch ? lines(imposter) : [imposter];
  final count = civilians.length > imposters.length
      ? civilians.length
      : imposters.length;
  final invalid = <int>{};
  final seen = {for (final entry in existing) entry.key: 0};
  final entries = <CustomQuestionEntry>[];
  for (var i = 0; i < count; i++) {
    if (i >= civilians.length || i >= imposters.length) {
      invalid.add(i + 1);
      continue;
    }
    try {
      final entry = CustomQuestionEntry(civilians[i], imposters[i]);
      if (seen.containsKey(entry.key)) {
        invalid.add(i + 1);
        if (seen[entry.key]! > 0) invalid.add(seen[entry.key]!);
      } else {
        seen[entry.key] = i + 1;
        entries.add(entry);
      }
    } on FormatException {
      invalid.add(i + 1);
    }
  }
  if (invalid.isNotEmpty) {
    throw QuestionImportException(
      invalid.toList()..sort(),
      unequalCounts: civilians.length != imposters.length,
    );
  }
  return entries;
}

class CustomQuestionCategory {
  final String id, name, contentLocale;
  final List<CustomQuestionEntry> pairs;

  CustomQuestionCategory({
    required this.id,
    required this.name,
    required this.contentLocale,
    required List<CustomQuestionEntry> pairs,
  }) : pairs = List.unmodifiable(pairs) {
    if (!RegExp(r'^custom-question-[1-9][0-9]*$').hasMatch(id) ||
        name.trim().isEmpty ||
        name != name.trim() ||
        contentLocale.trim().isEmpty ||
        pairs.isEmpty ||
        pairs.map((p) => p.key).toSet().length != pairs.length) {
      throw const FormatException('Invalid custom question category');
    }
  }

  factory CustomQuestionCategory.fromJson(JsonMap json) =>
      CustomQuestionCategory(
        id: requiredText(json, 'id'),
        name: requiredText(json, 'name'),
        contentLocale: requiredText(json, 'contentLocale'),
        pairs: (json['pairs'] as List)
            .map((p) => CustomQuestionEntry.fromJson(p as JsonMap))
            .toList(),
      );

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'contentLocale': contentLocale,
    'pairs': pairs.map((p) => p.toJson()).toList(),
  };

  ContentCategory get category => ContentCategory.local(
    id: id,
    name: name,
    contentLocale: contentLocale,
    gameType: 'question',
    isFamilyFriendly: false,
  );

  List<QuestionPair> get prompts => [
    for (var i = 0; i < pairs.length; i++)
      QuestionPair.local(
        id: '$id-pair-$i',
        categoryId: id,
        civilianQuestion: pairs[i].civilianQuestion,
        localImageId: pairs[i].imageId,
        imposterQuestion: pairs[i].imposterQuestion,
        contentLocale: contentLocale,
      ),
  ];
}
