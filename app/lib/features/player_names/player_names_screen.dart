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
  bool dirty = false, exiting = false, asking = false;

  Future<void> leave() async {
    if (asking || exiting) return;
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
        body: AppContent(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l.playerCount(players.length)),
              Text(l.playerLimits),
              for (final (i, p) in players.indexed)
                Column(
                  key: ValueKey(p.id),
                  children: [
                    TextFormField(
                      key: ValueKey('name-${p.id}'),
                      initialValue: p.name,
                      decoration: InputDecoration(
                        labelText: l.playerName(i + 1),
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (name) => name == null || name.trim().isEmpty
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
                          onPressed: i > 0 ? () => move(i, -1) : null,
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
                          SetupPlayer('player-${next++}', 'Player $number'),
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
        bottomNavigationBar: AppContent(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: players.any((p) => p.name.trim().isEmpty)
                  ? null
                  : () {
                      if (ref
                          .read(setupStoreProvider)
                          .setRoster(players, next)) {
                        close();
                      }
                    },
              child: Text(l.confirm),
            ),
          ),
        ),
      ),
    );
  }
}
