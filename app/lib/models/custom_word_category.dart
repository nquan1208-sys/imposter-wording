import 'package:untitled/models/content.dart';

List<String> uniqueWords(Iterable<String> entries) {
  final seen = <String>{};
  return [
    for (final entry in entries.map((e) => e.trim()))
      if (entry.isNotEmpty && seen.add(entry.toLowerCase())) entry,
  ];
}

class CustomWordCategory {
  final String id, name, contentLocale;
  final bool isFamilyFriendly;
  final List<String> words;

  CustomWordCategory({
    required this.id,
    required this.name,
    required this.contentLocale,
    required this.isFamilyFriendly,
    required List<String> words,
  }) : words = List.unmodifiable(words) {
    if (!RegExp(r'^custom-word-[1-9][0-9]*$').hasMatch(id) ||
        name.trim().isEmpty ||
        name != name.trim() ||
        contentLocale.trim().isEmpty ||
        words.isEmpty ||
        uniqueWords(words).length != words.length ||
        words.any((w) => w != w.trim())) {
      throw const FormatException('Invalid custom word category');
    }
  }

  factory CustomWordCategory.fromJson(JsonMap json) => CustomWordCategory(
    id: requiredText(json, 'id'),
    name: requiredText(json, 'name'),
    contentLocale: requiredText(json, 'contentLocale'),
    isFamilyFriendly: json['isFamilyFriendly'] as bool,
    words: (json['words'] as List).cast<String>(),
  );

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'contentLocale': contentLocale,
    'isFamilyFriendly': isFamilyFriendly,
    'words': words,
  };

  ContentCategory get category => ContentCategory.local(
    id: id,
    name: name,
    contentLocale: contentLocale,
    isFamilyFriendly: isFamilyFriendly,
  );

  List<WordPrompt> get prompts => [
    for (var i = 0; i < words.length; i++)
      WordPrompt.local(
        id: '$id-word-$i',
        categoryId: id,
        text: words[i],
        contentLocale: contentLocale,
      ),
  ];
}
