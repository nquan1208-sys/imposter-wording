import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/features/player_presets/player_presets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class PlayerNamesScreen extends ConsumerStatefulWidget {
  const PlayerNamesScreen({super.key});
  @override
  ConsumerState<PlayerNamesScreen> createState() => _PlayerNamesScreenState();
}

class _PlayerNamesScreenState extends ConsumerState<PlayerNamesScreen> {
  late final original = ref.read(setupStoreProvider).setup.value;
  late final players = original.players.toList();
  late int next = original.nextPlayerId;
  late GameSetup rules = original;
  late String? presetId = original.activePresetId;
  int revision = 0;
  bool busy = false, failed = false;
  bool dirty = false, exiting = false, asking = false;
  GameSetup get draft => rules.copyWith(
    players: List.of(players),
    nextPlayerId: next,
    imposters: rules.imposters.clamp(1, (players.length - 1) ~/ 2),
  );

  Future<void> choosePreset() async {
    final store = ref.read(setupStoreProvider);
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: AppEdgeInsets.pageFor(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.savedLists, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xl),
              AppSelectionCard(
                selected: presetId == null,
                onTap: () => Navigator.pop(context, 'unsaved'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ExcludeSemantics(
                          child: Icon(Icons.folder_outlined),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l.unsavedGame,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (presetId == null)
                          const ExcludeSemantics(child: Icon(Icons.check)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l.unsavedGameHelp),
                  ],
                ),
              ),
              for (final p in store.setup.value.presets)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: AppSelectionCard(
                    selected: presetId == p.id,
                    onTap: () => Navigator.pop(context, p.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(Icons.folder_outlined),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (presetId == p.id)
                              const ExcludeSemantics(child: Icon(Icons.check)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l.playerCount(p.setup.players.length)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.pop(context, 'create'),
                child: Text(l.saveList),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'manage'),
                child: Text(l.manageLists),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'manage') {
      await ref.read(AppService.router).push(RouteInput.playerPresets());
    } else if (choice == 'create') {
      if (!draft.validRoster) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.nameRequired)));
        return;
      }
      final id = await presetNameDialog(context, store, draft: draft);
      if (mounted && id != null) {
        setState(() {
          presetId = id;
          dirty = true;
        });
      }
    } else {
      setState(() {
        presetId = choice == 'unsaved' ? null : choice;
        if (presetId != null) {
          final p = store.setup.value.presets.firstWhere(
            (p) => p.id == presetId,
          );
          players
            ..clear()
            ..addAll(p.setup.players);
          next = p.setup.nextPlayerId;
          rules = p.setup;
          revision++;
        }
        dirty = true;
      });
    }
  }

  Future<void> leave() async {
    if (asking || exiting || busy) return;
    final l = AppLocalizations.of(context);
    if (dirty) {
      asking = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.discardRoster),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.discard),
            ),
          ],
        ),
      );
      asking = false;
      if (!mounted || discard != true) return;
    }
    close();
  }

  void close() {
    setState(() => exiting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void move(int index, int offset) => setState(() {
    final player = players.removeAt(index);
    players.insert(index + offset, player);
    dirty = true;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(setupStoreProvider);
    return SignalBuilder(
      builder: (context) {
        final selected = store.setup.value.presets
            .where((p) => p.id == presetId)
            .firstOrNull;
        if (selected == null) presetId = null;
        return PopScope(
          canPop: exiting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) leave();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l.editPlayers),
              leading: BackButton(onPressed: leave),
            ),
            body: AbsorbPointer(
              absorbing: busy || !store.editable,
              child: AppContent(
                child: ListView(
                  padding: AppEdgeInsets.pageFor(context),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(selected?.name ?? l.unsavedGame),
                        trailing: const Icon(Icons.expand_more),
                        onTap: choosePreset,
                      ),
                    ),
                    if (failed)
                      AppNotice(message: l.settingsWriteError, error: true),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      l.playerCount(players.length),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.playerLimits,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final (i, p) in players.indexed)
                      Padding(
                        key: ValueKey(p.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExcludeSemantics(
                                  child: CircleAvatar(
                                    backgroundColor: AppColors.selection,
                                    foregroundColor: AppColors.accentText,
                                    child: Text('${i + 1}'),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  key: ValueKey('name-$revision-${p.id}'),
                                  initialValue: p.name,
                                  decoration: InputDecoration(
                                    labelText: l.playerName(i + 1),
                                  ),
                                  autovalidateMode: AutovalidateMode.always,
                                  validator: (name) =>
                                      name == null || name.trim().isEmpty
                                      ? l.nameRequired
                                      : null,
                                  onChanged: (name) => setState(() {
                                    players[i] = SetupPlayer(p.id, name);
                                    dirty = true;
                                  }),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: l.moveUp,
                                      onPressed: i > 0
                                          ? () => move(i, -1)
                                          : null,
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      tooltip: l.moveDown,
                                      onPressed: i < players.length - 1
                                          ? () => move(i, 1)
                                          : null,
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                    IconButton(
                                      tooltip: l.removePlayer,
                                      style: IconButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                      ),
                                      onPressed: players.length > 3
                                          ? () => setState(() {
                                              players.removeAt(i);
                                              dirty = true;
                                            })
                                          : null,
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: players.length < 100
                          ? () => setState(() {
                              var number = 1;
                              while (players.any(
                                (p) => p.name.trim() == 'Player $number',
                              )) {
                                number++;
                              }
                              players.add(
                                SetupPlayer(
                                  'player-${next++}',
                                  'Player $number',
                                ),
                              );
                              dirty = true;
                            })
                          : null,
                      icon: const Icon(Icons.add),
                      label: Text(l.addPlayer),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: AppActionBar(
              child: FilledButton(
                onPressed: busy || !store.editable || !draft.validRoster
                    ? null
                    : () async {
                        setState(() {
                          busy = true;
                          failed = false;
                        });
                        final success = await store.confirmDraft(
                          draft,
                          presetId,
                        );
                        if (!mounted) return;
                        setState(() {
                          busy = false;
                          failed = !success;
                        });
                        if (success) close();
                      },
                child: Text(l.confirm),
              ),
            ),
          ),
        );
      },
    );
  }
}
