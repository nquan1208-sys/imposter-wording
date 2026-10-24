import 'dart:math';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';

enum WordGameStage { players, discussion, result }

class WordGameSession {
  final GameSetup setup;
  final WordPrompt prompt;
  final String categoryName, imposterId, startingPlayerId;
  String get contentLocale => prompt.contentLocale;

  WordGameSession._(
    this.setup,
    this.prompt,
    this.categoryName,
    this.imposterId,
    this.startingPlayerId,
  );

  static WordGameSession? create(SetupStore store, {Random? random}) {
    if (!store.editable) return null;
    store.revalidate();
    final setup = store.setup.value;
    final players = setup.players;
    if (players.length < 3 ||
        players.length > 100 ||
        players.map((p) => p.id).toSet().length != players.length ||
        players.any((p) => p.id.isEmpty || p.name.trim().isEmpty)) {
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
    return WordGameSession._(
      setup.copyWith(
        players: List.unmodifiable(players),
        categoryIds: Set.unmodifiable(setup.categoryIds),
      ),
      prompt,
      category.name,
      players[rng.nextInt(players.length)].id,
      players[rng.nextInt(players.length)].id,
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
  late final votedPlayerId = signal<String?>(null).manageBy(_disposers);

  WordGameStore(this.session);

  bool get groupWon =>
      stage.value == WordGameStage.result &&
      votedPlayerId.value == session.imposterId;

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

  void confirmVote(String id) {
    if (stage.value != WordGameStage.discussion ||
        !session.setup.players.any((p) => p.id == id)) {
      return;
    }
    votedPlayerId.value = id;
    stage.value = WordGameStage.result;
  }

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
