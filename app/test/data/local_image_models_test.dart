import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/custom_word_category.dart';
import 'package:untitled/models/custom_question_category.dart';
import 'package:untitled/models/game_setup.dart';

const imageId = '0123456789abcdef0123456789abcdef.img';
void main() {
  CustomWordCategory words({Map<String, String> images = const {}}) =>
      CustomWordCategory(
        id: 'custom-word-1',
        name: 'Words',
        contentLocale: 'vi',
        isFamilyFriendly: true,
        words: ['Apple'],
        imageIds: images,
      );
  test(
    'legacy fields default empty; immutable maps and local-only prompt fields',
    () {
      final legacy = words().toJson()..remove('imageIds');
      expect(CustomWordCategory.fromJson(legacy).imageIds, isEmpty);
      final original = {'Apple': imageId};
      final category = words(images: original);
      original.clear();
      expect(category.imageIds, {'Apple': imageId});
      expect(() => category.imageIds.clear(), throwsUnsupportedError);
      final prompt = category.prompts.single;
      expect(prompt.localImageId, imageId);
      expect(prompt.imagePath, isNull);
      final pair = CustomQuestionEntry.fromJson({
        'civilianQuestion': 'A',
        'imposterQuestion': 'B',
      });
      expect(pair.imageId, isNull);
      expect(CustomQuestionEntry('A', 'B', imageId: imageId).key, pair.key);
      expect(
        () => parseQuestionPairs(
          'A',
          'B',
          existing: [CustomQuestionEntry('A', 'B', imageId: imageId)],
        ),
        throwsA(isA<QuestionImportException>()),
      );
    },
  );
  test(
    'round trip preserves references, IDs, counters and preset exclusions',
    () {
      final setup = GameSetup.defaults().copyWith(
        customWordCategories: [
          words(images: {'Apple': imageId}),
        ],
        nextCustomWordCategoryId: 2,
        customQuestionCategories: [
          CustomQuestionCategory(
            id: 'custom-question-1',
            name: 'Questions',
            contentLocale: 'vi',
            pairs: [CustomQuestionEntry('A', 'B', imageId: imageId)],
          ),
        ],
        nextCustomQuestionCategoryId: 2,
      );
      final restored = GameSetup.fromJson(setup.toJson());
      expect(restored.toJson(), setup.toJson());
      expect(restored.localImageIds, {imageId});
      expect(restored.rosterJson().toString(), isNot(contains('imageId')));
      expect(
        restored.customQuestionCategories.single.prompts.single.localImageId,
        imageId,
      );
    },
  );
  test('rejects orphaned keys and invalid IDs in both category types', () {
    expect(() => words(images: {'Other': imageId}), throwsFormatException);
    for (final id in ['../image', '/tmp/image', 'x.png']) {
      expect(() => words(images: {'Apple': id}), throwsFormatException);
      expect(
        () => CustomQuestionEntry('A', 'B', imageId: id),
        throwsFormatException,
      );
    }
  });
}
