import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/models/game_setup.dart';

class SetupStore extends StoreBase {
  final ContentRepository content;
  final LocalJsonStore file;
  final _disposers = AutoDisposeManager();
  late final setup = signal(GameSetup.defaults()).manageBy(_disposers);
  late final reading = signal(true).manageBy(_disposers);
  late final readFailed = signal(false).manageBy(_disposers);
  late final writeFailed = signal(false).manageBy(_disposers);
  late final selectionRemoved = signal(false).manageBy(_disposers);
  Future<void> _writes = Future.value();
  Future<void>? _read;
  Future<void> get pendingWrites => _writes;
  bool get editable => !reading.value && !readFailed.value && !writing.value;

  final _availableCategories = <(String, bool), Set<String>>{};

  SetupStore({required this.content, required this.file}) {
    effect(() {
      final snapshot = content.snapshot.value;
      if (snapshot != null) {
        for (final gameType in ['word', 'question']) {
          for (final family in [false, true]) {
            _availableCategories[(gameType, family)] = content
                .categoryCounts(family: family, gameType: gameType)
                .keys
                .map((c) => c.id)
                .toSet();
          }
        }
      }
      final ready = !reading.value && !readFailed.value;
      if (snapshot != null && ready) untracked(revalidate);
    }).manageBy(_disposers);
  }

  Future<void> restore() =>
      _read ??= _restore().whenComplete(() => _read = null);
  Future<void> _restore() async {
    reading.value = true;
    await _writes;
    if (isDispose) return;
    try {
      final data = await file.read();
      if (isDispose) return;
      _committed = data == null
          ? GameSetup.defaults()
          : GameSetup.fromJson(data);
      setup.value = _committed;
      readFailed.value = false;
    } catch (_) {
      if (!isDispose) readFailed.value = true;
    } finally {
      if (!isDispose) reading.value = false;
    }
    await _writes;
  }

  GameSetup _committed = GameSetup.defaults();
  int _queued = 0;
  late final writing = signal(false).manageBy(_disposers);
  GameSetup Function(GameSetup)? _retry;

  Future<bool> _mutate(
    GameSetup Function(GameSetup) change, {
    bool retryable = false,
    bool skipUnchanged = false,
  }) {
    if (isDispose || reading.value || readFailed.value) {
      return Future.value(false);
    }
    _queued++;
    writing.value = true;
    final result = _writes.then((_) async {
      var validated = false;
      try {
        final value = _validatedCategories(change(_committed));
        if (skipUnchanged && identical(value, _committed)) return true;
        GameSetup.fromJson(value.toJson());
        validated = true;
        await file.write(value.toJson());
        _committed = value;
        if (!isDispose) {
          setup.value = value;
          writeFailed.value = false;
          _retry = null;
        }
        return true;
      } catch (_) {
        if (!isDispose) {
          if (retryable && validated) {
            writeFailed.value = true;
            _retry = change;
          }
        }
        return false;
      } finally {
        _queued--;
        if (!isDispose) writing.value = _queued != 0;
      }
    });
    _writes = result.then((_) {});
    return result;
  }

  Future<bool> save() async {
    await pendingWrites;
    if (isDispose || reading.value || readFailed.value) return false;
    final retry = _retry;
    return retry == null ? !writeFailed.value : _mutate(retry, retryable: true);
  }

  Future<bool> setPlayerCount(int count) => _mutate((current) {
    if (count < 3 || count > 100) throw const FormatException('Invalid count');
    var next = current.nextPlayerId;
    final players = current.players.take(count).toList();
    while (players.length < count) {
      var number = 1;
      while (players.any((p) => p.name == 'Player $number')) {
        number++;
      }
      players.add(SetupPlayer('player-${next++}', 'Player $number'));
    }
    return _updateActive(
      current.copyWith(
        players: players,
        nextPlayerId: next,
        imposters: current.imposters.clamp(1, (players.length - 1) ~/ 2),
      ),
    );
  }, retryable: true);

  Future<bool> setRoster(List<SetupPlayer> players, int nextPlayerId) {
    final roster = List<SetupPlayer>.of(players);
    if (roster.length < 3 || roster.length > 100) return Future.value(false);
    return _mutate((current) {
      final draft = current.copyWith(
        players: roster,
        nextPlayerId: nextPlayerId,
        imposters: current.imposters.clamp(1, (roster.length - 1) ~/ 2),
      );
      if (!draft.validRoster) throw const FormatException('Invalid roster');
      return _updateActive(current.withRoster(draft));
    });
  }

  Future<bool> confirmDraft(GameSetup draft, String? presetId) =>
      _mutate((current) {
        if (!draft.validRoster) throw const FormatException('Invalid roster');
        final exists = current.presets.any((p) => p.id == presetId);
        return _updateActive(
          current
              .withRoster(draft)
              .copyWith(
                activePresetId: exists ? presetId : null,
                clearActivePreset: !exists,
              ),
        );
      });

  GameSetup _updateActive(GameSetup current) => current.copyWith(
    presets: current.presets
        .map(
          (p) => p.id == current.activePresetId
              ? PlayerPreset(
                  p.id,
                  p.name,
                  GameSetup.defaults().withRoster(current),
                )
              : p,
        )
        .toList(),
  );

  Future<bool> setRules({
    int? imposters,
    bool? randomImposters,
    bool? imposterNotFirst,
    bool? showCategory,
    bool? knowEachOther,
  }) => _mutate(
    (current) => _updateActive(
      current.copyWith(
        imposters: imposters,
        randomImposters: randomImposters,
        imposterNotFirst: imposterNotFirst,
        showCategory: showCategory,
        knowEachOther: knowEachOther,
      ),
    ),
    retryable: true,
  );

  Future<bool> setFamily(bool family) =>
      _mutate((s) => s.copyWith(family: family), retryable: true);
  Future<bool> setGameType(String type) =>
      _mutate((s) => s.copyWith(gameType: type), retryable: true);
  Future<bool> setCategories(Set<String> ids) {
    final selected = Set<String>.of(ids);
    return _mutate((s) => s.copyWith(categoryIds: selected), retryable: true);
  }

  bool validPresetName(String name, {String? exceptId}) =>
      name.trim().isNotEmpty &&
      !setup.value.presets.any(
        (p) =>
            p.id != exceptId &&
            p.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );

  Future<String?> createPreset(String name, GameSetup draft) async {
    String? id;
    final success = await _mutate((current) {
      if (!draft.validRoster ||
          name.trim().isEmpty ||
          current.presets.any(
            (p) => p.name.toLowerCase() == name.trim().toLowerCase(),
          )) {
        throw const FormatException('Invalid preset');
      }
      id = 'preset-${current.nextPresetId}';
      return current.copyWith(
        nextPresetId: current.nextPresetId + 1,
        presets: [
          ...current.presets,
          PlayerPreset(
            id!,
            name.trim(),
            GameSetup.defaults().withRoster(draft),
          ),
        ],
      );
    });
    return success ? id : null;
  }

  Future<bool> renamePreset(String id, String name) => _mutate((current) {
    if (name.trim().isEmpty ||
        !current.presets.any((p) => p.id == id) ||
        current.presets.any(
          (p) =>
              p.id != id && p.name.toLowerCase() == name.trim().toLowerCase(),
        )) {
      throw const FormatException('Invalid preset name');
    }
    return current.copyWith(
      presets: current.presets
          .map((p) => p.id == id ? PlayerPreset(id, name.trim(), p.setup) : p)
          .toList(),
    );
  });

  Future<bool> deletePreset(String id) => _mutate(
    (current) => current.copyWith(
      presets: current.presets.where((p) => p.id != id).toList(),
      clearActivePreset: current.activePresetId == id,
    ),
  );

  GameSetup _validatedCategories(GameSetup current) {
    final available = _availableCategories[(current.gameType, current.family)];
    if (available == null) return current;
    final retained = current.categoryIds.intersection(available);
    if (retained.length == current.categoryIds.length) return current;
    if (!isDispose) selectionRemoved.value = true;
    return current.copyWith(categoryIds: retained);
  }

  Future<bool> revalidate() =>
      _mutate((current) => current, skipUnchanged: true, retryable: true);

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
