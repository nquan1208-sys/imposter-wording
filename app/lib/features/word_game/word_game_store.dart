import 'dart:math';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/models/game_assignment.dart';

enum WordGameStage { players, discussion, result }

class WordGameSession {
  final GameSetup setup;
  final WordPrompt prompt;
  final String categoryName, startingPlayerId;
  final Set<String> imposterIds;
  String get contentLocale => prompt.contentLocale;

  WordGameSession._(
    this.setup,
    this.prompt,
    this.categoryName,
    this.imposterIds,
    this.startingPlayerId,
  );

  static WordGameSession? create(SetupStore store, {Random? random}) {
    if (!store.editable) return null;
    final setup = store.setup.value;
    if (setup.gameType != 'word' || !GameAssignment.validSetup(setup)) {
      return null;
    }
    final words = store.content.eligibleWords(
      family: setup.family,
      categoryIds: setup.categoryIds,
    );
    if (words.isEmpty) return null;
    final rng = random ?? Random();
    final prompt = words[rng.nextInt(words.length)];
    final category = store.content.snapshot.value!.categories.firstWhere(
      (c) => c.id == prompt.categoryId,
    );
    final assignment = GameAssignment.create(setup, rng);
    return WordGameSession._(
      assignment.setup,
      prompt,
      category.name,
      assignment.imposterIds,
      assignment.startingPlayerId,
    );
  }
}

class WordGameStore extends StoreBase {
  final WordGameSession session;
  final _disposers = AutoDisposeManager();
  late final stage = signal(WordGameStage.players).manageBy(_disposers);
  late final completed = signal<Set<String>>(const {}).manageBy(_disposers);
  late final currentPlayerId = signal<String?>(null).manageBy(_disposers);
  late final revealed = signal(false).manageBy(_disposers);
  late final votedPlayerIds = signal<Set<String>>(
    const {},
  ).manageBy(_disposers);

  WordGameStore(this.session);

  bool get groupWon =>
      stage.value == WordGameStage.result &&
      votedPlayerIds.value.length == session.imposterIds.length &&
      votedPlayerIds.value.containsAll(session.imposterIds);

  void selectPlayer(String id) {
    if (stage.value != WordGameStage.players ||
        currentPlayerId.value != null ||
        completed.value.contains(id) ||
        !session.setup.players.any((p) => p.id == id)) {
      return;
    }
    revealed.value = false;
    currentPlayerId.value = id;
  }

  void reveal() {
    if (stage.value == WordGameStage.players && currentPlayerId.value != null) {
      revealed.value = true;
    }
  }

  void conceal() => revealed.value = false;

  void leaveCard() {
    conceal();
    currentPlayerId.value = null;
  }

  void completePlayer() {
    final id = currentPlayerId.value;
    if (stage.value != WordGameStage.players || id == null || !revealed.value) {
      return;
    }
    completed.value = Set.unmodifiable({...completed.value, id});
    leaveCard();
    if (completed.value.length == session.setup.players.length) {
      stage.value = WordGameStage.discussion;
    }
  }

  void confirmVote(Set<String> ids) {
    if (stage.value != WordGameStage.discussion ||
        ids.length != session.imposterIds.length ||
        !ids.every((id) => session.setup.players.any((p) => p.id == id))) {
      return;
    }
    votedPlayerIds.value = Set.unmodifiable(ids);
    stage.value = WordGameStage.result;
  }

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
