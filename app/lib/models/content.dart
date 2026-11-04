bool validLocalImageId(String id) =>
    RegExp(r'^[a-f0-9]{32}\.img$').hasMatch(id);

typedef JsonMap = Map<String, dynamic>;

String requiredText(JsonMap json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key');
  }
  return value;
}

JsonMap translation(JsonMap row, String locale) {
  final translations = row['t'] as List;
  if (translations.length != 1) {
    throw const FormatException('Missing translation');
  }
  final t = Map<String, dynamic>.from(translations.single as Map);
  if (t['locale'] != locale || t['status'] != 'published') {
    throw const FormatException('Invalid translation');
  }
  return t;
}

class ContentCategory {
  final String id, gameType, name, slug, contentLocale;
  final String? description;
  final int sortOrder;
  final bool isFamilyFriendly;
  const ContentCategory.local({
    required this.id,
    required this.name,
    required this.contentLocale,
    required this.isFamilyFriendly,
    this.gameType = 'word',
  }) : slug = id,
       description = null,
       sortOrder = 0;
  ContentCategory(JsonMap row, this.contentLocale)
    : id = requiredText(row, 'id'),
      gameType = requiredText(row, 'game_type'),
      slug = requiredText(row, 'slug'),
      sortOrder = row['sort_order'] as int,
      isFamilyFriendly = row['is_family_friendly'] as bool? ?? false,
      name = requiredText(translation(row, contentLocale), 'name'),
      description = translation(row, contentLocale)['description'] as String? {
    if (!const ['word', 'question'].contains(gameType) ||
        row['is_active'] != true ||
        sortOrder < 0 ||
        translation(row, contentLocale)['category_id'] != id) {
      throw const FormatException('Invalid category');
    }
  }
}

class WordPrompt {
  final String id, categoryId, difficulty, text, contentLocale;
  final String? imagePath;
  final String? localImageId;
  const WordPrompt.local({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.contentLocale,
    this.localImageId,
  }) : difficulty = 'easy',
       imagePath = null;
  WordPrompt(JsonMap row, this.contentLocale)
    : localImageId = null,
      id = requiredText(row, 'id'),
      categoryId = requiredText(row, 'category_id'),
      difficulty = requiredText(row, 'difficulty'),
      imagePath = row['image_path'] as String?,
      text = requiredText(translation(row, contentLocale), 'text') {
    validatePrompt(row, contentLocale, id, difficulty);
    if (imagePath != null &&
        (imagePath!.trim().isEmpty ||
            imagePath!.startsWith('/') ||
            imagePath!
                .split('/')
                .any((p) => p.isEmpty || p == '.' || p == '..') ||
            imagePath!.contains('://'))) {
      throw const FormatException('Invalid image path');
    }
  }
}

class QuestionPair {
  final String? localImageId;
  final String id,
      categoryId,
      difficulty,
      civilianQuestion,
      imposterQuestion,
      contentLocale;
  const QuestionPair.local({
    required this.id,
    required this.categoryId,
    required this.civilianQuestion,
    required this.imposterQuestion,
    required this.contentLocale,
    this.localImageId,
  }) : difficulty = 'easy';
  QuestionPair(JsonMap row, this.contentLocale)
    : localImageId = null,
      id = requiredText(row, 'id'),
      categoryId = requiredText(row, 'category_id'),
      difficulty = requiredText(row, 'difficulty'),
      civilianQuestion = requiredText(
        translation(row, contentLocale),
        'civilian_question',
      ),
      imposterQuestion = requiredText(
        translation(row, contentLocale),
        'imposter_question',
      ) {
    validatePrompt(row, contentLocale, id, difficulty);
    if (civilianQuestion.trim().toLowerCase() ==
        imposterQuestion.trim().toLowerCase()) {
      throw const FormatException('Questions must differ');
    }
  }
}

void validatePrompt(JsonMap row, String locale, String id, String difficulty) {
  if (translation(row, locale)['prompt_id'] != id ||
      !const ['easy', 'medium', 'hard'].contains(difficulty)) {
    throw const FormatException('Invalid prompt metadata');
  }
}

class ContentSnapshot {
  final String contentLocale;
  final List<ContentCategory> categories;
  final List<WordPrompt> words;
  final List<QuestionPair> questions;
  ContentSnapshot.fromJson(JsonMap json, this.contentLocale)
    : categories = (json['categories'] as List)
          .map(
            (r) => ContentCategory(
              Map<String, dynamic>.from(r as Map),
              contentLocale,
            ),
          )
          .toList(),
      words = (json['words'] as List)
          .map(
            (r) =>
                WordPrompt(Map<String, dynamic>.from(r as Map), contentLocale),
          )
          .toList(),
      questions = (json['questions'] as List)
          .map(
            (r) => QuestionPair(
              Map<String, dynamic>.from(r as Map),
              contentLocale,
            ),
          )
          .toList() {
    final byId = {for (final c in categories) c.id: c};
    if (byId.length != categories.length ||
        words.map((w) => w.id).toSet().length != words.length ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw const FormatException('Duplicate IDs in snapshot');
    }
    for (final w in words) {
      if (byId[w.categoryId]?.gameType != 'word') {
        throw const FormatException('Incompatible word category');
      }
    }
    for (final q in questions) {
      if (byId[q.categoryId]?.gameType != 'question') {
        throw const FormatException('Incompatible question category');
      }
    }
  }
}
