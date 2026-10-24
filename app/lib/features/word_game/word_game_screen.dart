import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class WordGameScreen extends StatefulWidget {
  final WordGameSession session;
  const WordGameScreen({super.key, required this.session});

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen>
    with WidgetsBindingObserver {
  late final store = WordGameStore(widget.session);
  bool _exiting = false, _dialogOpen = false, _voteOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) store.conceal();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_dialogOpen || _exiting) return;
    if (store.currentPlayerId.value != null) {
      store.leaveCard();
      return;
    }
    if (store.stage.value != WordGameStage.result) {
      _dialogOpen = true;
      final l = AppLocalizations.of(context);
      final exit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.endGame),
          content: Text(l.endGameConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.endGame),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (!mounted || exit != true) return;
    }
    setState(() => _exiting = true);
    // Allow PopScope to rebuild before removing the game route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _vote() async {
    if (_voteOpen || store.stage.value != WordGameStage.discussion) return;
    _voteOpen = true;
    final l = AppLocalizations.of(context);
    String? selected;
    final voted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AppContent(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: AppEdgeInsets.all16,
                        child: Text(
                          l.voteTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Padding(
                        padding: AppEdgeInsets.h16,
                        child: Text(l.voteHelp),
                      ),
                      for (final p in store.session.setup.players)
                        ListTile(
                          title: Text(p.name),
                          leading: Icon(
                            selected == p.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          selected: selected == p.id,
                          onTap: () => setState(() => selected = p.id),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: AppEdgeInsets.all16,
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: selected == null
                            ? null
                            : () => Navigator.pop(context, selected),
                        child: Text(l.confirm),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _voteOpen = false;
    if (mounted && voted != null) store.confirmVote(voted);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final stage = store.stage.value;
        final current = store.currentPlayerId.value;
        final session = store.session;
        final players = session.setup.players;
        String name(String id) => players.firstWhere((p) => p.id == id).name;
        final reveal = current != null;
        final title = switch (stage) {
          WordGameStage.players =>
            reveal ? l.wordFor(name(current)) : l.players,
          WordGameStage.discussion => l.discussionTitle,
          WordGameStage.result => l.gameResult,
        };
        return PopScope(
          canPop: _exiting,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              leading: BackButton(onPressed: _back),
            ),
            body: AppContent(
              child: stage == WordGameStage.players && !reveal
                  ? CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: AppEdgeInsets.all24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.passPhone,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  '${store.completed.value.length} / ${players.length}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                LinearProgressIndicator(
                                  value:
                                      store.completed.value.length /
                                      players.length,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: AppEdgeInsets.all16,
                          sliver: SliverGrid.builder(
                            itemCount: players.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 160,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                            itemBuilder: (context, i) {
                              final p = players[i];
                              final done = store.completed.value.contains(p.id);
                              return Card(
                                color: done
                                    ? AppColors.tealSurface
                                    : AppColors.white,
                                child: TextButton(
                                  key: ValueKey(p.id),
                                  onPressed: done
                                      ? null
                                      : () => store.selectPlayer(p.id),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          size: 32,
                                          color: done
                                              ? AppColors.teal
                                              : AppColors.charcoal,
                                          done
                                              ? Icons.check_circle
                                              : Icons.person_outline,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          p.name,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (done)
                                          Text(
                                            l.playerDone,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.teal,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: AppEdgeInsets.all24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: AppEdgeInsets.all24,
                              decoration: BoxDecoration(
                                color: stage == WordGameStage.result
                                    ? AppColors.tealSurface
                                    : AppColors.yellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                reveal
                                    ? Icons.lock_outline
                                    : stage == WordGameStage.discussion
                                    ? Icons.forum_outlined
                                    : Icons.emoji_events_outlined,
                                size: 48,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          if (reveal) ...[
                            if (!store.revealed.value)
                              OutlinedButton(
                                key: const Key('secretCard'),
                                onPressed: store.reveal,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xxl),
                                  child: Text(l.tapToReveal),
                                ),
                              )
                            else
                              Card(
                                color: AppColors.tealSurface,
                                child: Padding(
                                  padding: AppEdgeInsets.all24,
                                  child: Column(
                                    children: [
                                      Text(
                                        current == session.imposterId
                                            ? l.youAreImposter
                                            : session.prompt.text,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                      if (current != session.imposterId)
                                        Text(session.categoryName),
                                    ],
                                  ),
                                ),
                              ),
                          ] else if (stage == WordGameStage.discussion) ...[
                            Text(
                              l.startingPlayer(name(session.startingPlayerId)),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              l.discussionHelp,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.gray),
                            ),
                          ] else ...[
                            Text(
                              store.groupWon ? l.groupWins : l.imposterWins,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(l.actualImposter(name(session.imposterId))),
                            Text(
                              l.votedPlayer(name(store.votedPlayerId.value!)),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const Divider(height: 32),
                            Text(
                              l.secretWord,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.gray),
                            ),
                            Text(
                              session.prompt.text,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar: reveal || stage != WordGameStage.players
                ? AppContent(
                    child: Padding(
                      padding: AppEdgeInsets.all24,
                      child: FilledButton(
                        onPressed: reveal
                            ? (store.revealed.value
                                  ? store.completePlayer
                                  : null)
                            : stage == WordGameStage.discussion
                            ? _vote
                            : _back,
                        child: Text(
                          reveal
                              ? l.understood
                              : stage == WordGameStage.discussion
                              ? l.announceResult
                              : l.playAgain,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
