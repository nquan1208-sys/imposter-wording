import 'package:untitled/models/content.dart';

class ContentLanguage {
  final String code, displayName;
  final int sortOrder;
  ContentLanguage.fromJson(JsonMap json)
    : code = requiredText(json, 'code'),
      displayName = requiredText(json, 'display_name'),
      sortOrder = json['sort_order'] as int {
    if (code != code.trim() || sortOrder < 0) {
      throw const FormatException('Invalid content language');
    }
  }

  static List<ContentLanguage> parse(JsonMap json) {
    final languages = (json['languages'] as List)
        .map(
          (row) =>
              ContentLanguage.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if (languages.map((l) => l.code).toSet().length != languages.length) {
      throw const FormatException('Duplicate content languages');
    }
    languages.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.code.compareTo(b.code) : order;
    });
    return languages;
  }
}
