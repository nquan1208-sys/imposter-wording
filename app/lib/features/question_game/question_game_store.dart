import 'dart:math';
import 'package:untitled/models/game_setup.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_assignment.dart';

enum QuestionGameStage { players, commonQuestion, discussion, result }

class QuestionGameSession {
  final GameAssignment assignment;
  final QuestionPair prompt;
  final String categoryName;
  GameSetup get setup => assignment.setup;
  Set<String> get imposterIds => assignment.imposterIds;
  String get startingPlayerId => assignment.startingPlayerId;
  String get contentLocale => prompt.contentLocale;

  QuestionGameSession._(this.assignment, this.prompt, this.categoryName);

  static QuestionGameSession? create(SetupStore store, {Random? random}) {
    if (!store.editable || !store.contentReady) return null;
    final setup = store.setup.value;
    if (setup.gameType != 'question' || !GameAssignment.validSetup(setup)) {
      return null;
    }
    final pairs = store.eligibleQuestions(
      family: setup.family,
      categoryIds: setup.categoryIds,
    );
    if (pairs.isEmpty) return null;
    final rng = random ?? Random();
    final prompt = pairs[rng.nextInt(pairs.length)];
    final category = store.categories.firstWhere(
      (c) => c.id == prompt.categoryId,
    );
    return QuestionGameSession._(
      GameAssignment.create(setup, rng),
      prompt,
      category.name,
    );
  }
}

class QuestionGameStore extends StoreBase {
  final QuestionGameSession session;
  final _disposers = AutoDisposeManager();
  late final stage = signal(QuestionGameStage.players).manageBy(_disposers);
  late final currentPlayerId = signal<String?>(null).manageBy(_disposers);
  late final revealed = signal(false).manageBy(_disposers);
  late final answers = signal<Map<String, String>>(
    const {},
  ).manageBy(_disposers);
  final _drafts = <String, String>{};

  QuestionGameStore(this.session);

  List<SetupPlayer> get teammates =>
      revealed.value &&
          session.setup.knowEachOther &&
          session.imposterIds.length > 1 &&
          session.imposterIds.contains(currentPlayerId.value)
      ? session.setup.players
            .where(
              (p) =>
                  p.id != currentPlayerId.value &&
                  session.imposterIds.contains(p.id),
            )
            .toList()
      : const [];

  String get draft => _drafts[currentPlayerId.value] ?? '';
  String get question => session.imposterIds.contains(currentPlayerId.value)
      ? session.prompt.imposterQuestion
      : session.prompt.civilianQuestion;

  void selectPlayer(String id) {
    if (stage.value != QuestionGameStage.players ||
        currentPlayerId.value != null ||
        answers.value.containsKey(id) ||
        !session.setup.players.any((p) => p.id == id)) {
      return;
    }
    revealed.value = false;
    currentPlayerId.value = id;
  }

  void reveal() {
    if (stage.value == QuestionGameStage.players &&
        currentPlayerId.value != null) {
      revealed.value = true;
    }
  }

  void conceal() => revealed.value = false;

  void leaveCard() {
    conceal();
    currentPlayerId.value = null;
  }

  void updateDraft(String text) {
    final id = currentPlayerId.value;
    if (stage.value == QuestionGameStage.players &&
        id != null &&
        revealed.value &&
        !answers.value.containsKey(id)) {
      _drafts[id] = text;
    }
  }

  bool submit() {
    final id = currentPlayerId.value;
    final text = draft.trim();
    if (stage.value != QuestionGameStage.players ||
        id == null ||
        !revealed.value ||
        text.isEmpty ||
        answers.value.containsKey(id)) {
      return false;
    }
    answers.value = Map.unmodifiable({...answers.value, id: text});
    _drafts.remove(id);
    leaveCard();
    if (answers.value.length == session.setup.players.length) {
      stage.value = QuestionGameStage.commonQuestion;
    }
    return true;
  }

  void startDiscussion() {
    if (stage.value == QuestionGameStage.commonQuestion &&
        answers.value.length == session.setup.players.length) {
      stage.value = QuestionGameStage.discussion;
    }
  }

  void revealResult() {
    if (stage.value == QuestionGameStage.discussion) {
      stage.value = QuestionGameStage.result;
    }
  }

  @override
  void dispose() {
    _drafts.clear();
    super.dispose();
    _disposers.cancelAll();
  }
}
