import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/models/game_setup.dart';

class SetupStore extends StoreBase {
  final ContentRepository content;
  final ScopedJsonFile file;
  final _disposers = AutoDisposeManager();
  late final setup = signal(GameSetup.defaults()).manageBy(_disposers);
  late final reading = signal(true).manageBy(_disposers);
  late final readFailed = signal(false).manageBy(_disposers);
  late final writeFailed = signal(false).manageBy(_disposers);
  late final selectionRemoved = signal(false).manageBy(_disposers);
  Future<void> _writes = Future.value();
  Future<void>? _read;
  bool get editable => !reading.value && !readFailed.value;

  SetupStore({required this.content, required this.file}) {
    effect(() {
      final snapshot = content.snapshot.value;
      final ready = editable;
      if (snapshot != null && ready) untracked(revalidate);
    }).manageBy(_disposers);
  }

  Future<void> restore() =>
      _read ??= _restore().whenComplete(() => _read = null);
  Future<void> _restore() async {
    reading.value = true;
    try {
      final data = await file.read();
      if (isDispose) return;
      if (data != null) setup.value = GameSetup.fromJson(data);
      readFailed.value = false;
    } catch (_) {
      if (!isDispose) readFailed.value = true;
    } finally {
      if (!isDispose) reading.value = false;
    }
  }

  void reset() {
    if (reading.value) return;
    setup.value = GameSetup.defaults();
    readFailed.value = false;
    save();
  }

  Future<void> save() {
    if (!editable) return Future.value();
    final value = setup.value;
    _writes = _writes.then((_) async {
      try {
        await file.write(value.toJson());
        if (!isDispose && identical(value, setup.value)) {
          writeFailed.value = false;
        }
      } catch (_) {
        if (!isDispose) writeFailed.value = true;
      }
    });
    return _writes;
  }

  void setPlayerCount(int count) {
    if (!editable || count < 3 || count > 100) return;
    final current = setup.value;
    var next = current.nextPlayerId;
    final players = current.players.take(count).toList();
    while (players.length < count) {
      var number = 1;
      while (players.any((p) => p.name == 'Player $number')) {
        number++;
      }
      players.add(SetupPlayer('player-$next', 'Player $number'));
      next++;
    }
    setup.value = current.copyWith(
      players: players,
      nextPlayerId: next,
      imposters: current.imposters.clamp(1, (players.length - 1) ~/ 2),
    );
    save();
  }

  bool setRoster(List<SetupPlayer> players, int nextPlayerId) {
    final current = setup.value;
    if (!editable ||
        players.length < 3 ||
        players.length > 100 ||
        nextPlayerId < current.nextPlayerId ||
        players.map((p) => p.id).toSet().length != players.length ||
        players.any(
          (p) =>
              p.name.trim().isEmpty ||
              !RegExp(r'^player-[1-9][0-9]*$').hasMatch(p.id) ||
              int.parse(p.id.substring(7)) >= nextPlayerId,
        )) {
      return false;
    }
    setup.value = current.copyWith(
      players: players.map((p) => SetupPlayer(p.id, p.name.trim())).toList(),
      nextPlayerId: nextPlayerId,
      imposters: current.imposters.clamp(1, (players.length - 1) ~/ 2),
    );
    save();
    return true;
  }

  void setRules({
    int? imposters,
    bool? randomImposters,
    bool? imposterNotFirst,
    bool? showCategory,
    bool? knowEachOther,
  }) {
    if (!editable) return;
    final value = setup.value.copyWith(
      imposters: imposters,
      randomImposters: randomImposters,
      imposterNotFirst: imposterNotFirst,
      showCategory: showCategory,
      knowEachOther: knowEachOther,
    );
    if (!value.validRules) return;
    setup.value = value;
    save();
  }

  void setFamily(bool family) {
    if (!editable) return;
    setup.value = setup.value.copyWith(family: family);
    revalidate();
    save();
  }

  void setCategories(Set<String> ids) {
    if (!editable || content.snapshot.value == null) return;
    setup.value = setup.value.copyWith(categoryIds: Set.of(ids));
    revalidate();
    save();
  }

  void revalidate() {
    if (!editable || content.snapshot.value == null) return;
    final current = setup.value;
    final available = content
        .categoryCounts(family: current.family)
        .keys
        .map((c) => c.id)
        .toSet();
    final retained = current.categoryIds.intersection(available);
    if (retained.length != current.categoryIds.length) {
      setup.value = current.copyWith(categoryIds: retained);
      selectionRemoved.value = true;
      save();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
