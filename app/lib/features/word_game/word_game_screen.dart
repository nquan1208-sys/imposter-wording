import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/widgets/player_cards.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/widgets/app_hero_card.dart';
import 'package:untitled/theme/app_effects.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/features/word_game/word_image.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class WordGameScreen extends ConsumerStatefulWidget {
  final WordGameSession session;
  const WordGameScreen({super.key, required this.session});

  @override
  ConsumerState<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends ConsumerState<WordGameScreen>
    with WidgetsBindingObserver {
  late final store = WordGameStore(widget.session);
  final imageOwner = Object();
  late final localImages = ref.read(localImageStoreProvider);
  bool _exiting = false, _dialogOpen = false, _voteOpen = false;

  @override
  void initState() {
    super.initState();
    final id = widget.session.prompt.localImageId;
    if (id != null) localImages.retain(imageOwner, {id});
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) store.conceal();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.session.prompt.localImageId != null) {
      localImages.release(imageOwner);
    }
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
    final selected = <String>{};
    final voted = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AppContent(
        top: false,
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
                        child: Text(
                          l.voteHelp(store.session.imposterIds.length),
                        ),
                      ),
                      Padding(
                        padding: AppEdgeInsets.all24,
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            '${selected.length} / ${store.session.imposterIds.length}',
                            semanticsLabel:
                                '${l.voteTitle}: ${selected.length} / ${store.session.imposterIds.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      for (final p in store.session.setup.players)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: AppSelectionCard(
                            selected: selected.contains(p.id),
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    selected.contains(p.id)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: Text(p.name)),
                              ],
                            ),
                            onTap: () => setState(() {
                              if (!selected.remove(p.id)) {
                                if (store.session.imposterIds.length == 1) {
                                  selected.clear();
                                }
                                if (selected.length <
                                    store.session.imposterIds.length) {
                                  selected.add(p.id);
                                }
                              }
                            }),
                          ),
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
                        onPressed:
                            selected.length != store.session.imposterIds.length
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
                            child: AppHeroCard(
                              title: l.passPhone,
                              icon: Icons.phonelink_lock_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${store.completed.value.length} / ${players.length}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  LinearProgressIndicator(
                                    value:
                                        store.completed.value.length /
                                        players.length,
                                    semanticsLabel: l.players,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PlayerCards(
                          players: players,
                          completed: store.completed.value,
                          completedLabel: l.playerDone,
                          onSelected: store.selectPlayer,
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
                                gradient: stage == WordGameStage.result
                                    ? AppEffects.selectedGradient
                                    : AppEffects.accentGradient,
                                boxShadow: AppEffects.cardShadow,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.hero,
                                ),
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
                                clipBehavior: Clip.antiAlias,
                                child: Ink(
                                  decoration: const BoxDecoration(
                                    gradient: AppEffects.selectedGradient,
                                  ),
                                  child: Padding(
                                    padding: AppEdgeInsets.all24,
                                    child: Column(
                                      children: [
                                        Text(
                                          session.imposterIds.contains(current)
                                              ? l.youAreImposter
                                              : session.prompt.text,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                        if (session.showWordImages &&
                                            !session.imposterIds.contains(
                                              current,
                                            ))
                                          WordImage(session.prompt),
                                        if (!session.imposterIds.contains(
                                              current,
                                            ) ||
                                            session.setup.showCategory)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: AppSpacing.lg,
                                            ),
                                            child: Text(
                                              session.categoryName,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        if (session.imposterIds.contains(
                                              current,
                                            ) &&
                                            session.setup.knowEachOther &&
                                            session.imposterIds.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: AppSpacing.xl,
                                            ),
                                            child: AppNotice(
                                              message: l.fellowImposters(
                                                session.setup.players
                                                    .where(
                                                      (p) =>
                                                          p.id != current &&
                                                          session.imposterIds
                                                              .contains(p.id),
                                                    )
                                                    .map((p) => p.name)
                                                    .join(', '),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
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
                            Card(
                              child: ListTile(
                                leading: const ExcludeSemantics(
                                  child: Icon(Icons.person_search_outlined),
                                ),
                                title: Text(
                                  l.actualImposter(
                                    players
                                        .where(
                                          (p) => session.imposterIds.contains(
                                            p.id,
                                          ),
                                        )
                                        .map((p) => p.name)
                                        .join(', '),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Card(
                              child: ListTile(
                                leading: const ExcludeSemantics(
                                  child: Icon(Icons.how_to_vote_outlined),
                                ),
                                title: Text(
                                  l.votedPlayer(
                                    players
                                        .where(
                                          (p) => store.votedPlayerIds.value
                                              .contains(p.id),
                                        )
                                        .map((p) => p.name)
                                        .join(', '),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Card(
                              child: Padding(
                                padding: AppEdgeInsets.all24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.secretWord,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.gray),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      session.prompt.text,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                    if (session.showWordImages)
                                      WordImage(session.prompt),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar: reveal || stage != WordGameStage.players
                ? AppActionBar(
                    child: FilledButton(
                      onPressed: reveal
                          ? (store.revealed.value ? store.completePlayer : null)
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
                  )
                : null,
          ),
        );
      },
    );
  }
}
