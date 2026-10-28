import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/widgets/player_cards.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';
import 'package:untitled/widgets/app_hero_card.dart';
import 'package:untitled/features/word_game/local_prompt_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class QuestionGameScreen extends ConsumerStatefulWidget {
  final QuestionGameSession session;
  const QuestionGameScreen({super.key, required this.session});

  @override
  ConsumerState<QuestionGameScreen> createState() => _QuestionGameScreenState();
}

class _QuestionGameScreenState extends ConsumerState<QuestionGameScreen>
    with WidgetsBindingObserver {
  late final store = QuestionGameStore(widget.session);
  final answer = TextEditingController();
  final imageOwner = Object();
  late final localImages = ref.read(localImageStoreProvider);
  bool _exiting = false, _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    final id = widget.session.prompt.localImageId;
    if (id != null) localImages.retain(imageOwner, {id});
    WidgetsBinding.instance.addObserver(this);
    answer.addListener(_saveDraft);
  }

  void _saveDraft() => store.updateDraft(answer.text);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      store.conceal();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    answer.dispose();
    if (widget.session.prompt.localImageId != null) {
      localImages.release(imageOwner);
    }
    store.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_exiting || _dialogOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (store.currentPlayerId.value != null) {
      store.leaveCard();
      answer.clear();
      return;
    }
    if (store.stage.value != QuestionGameStage.result) {
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
    // Rebuild PopScope before removing the game route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final stage = store.stage.value;
        final id = store.currentPlayerId.value;
        final session = store.session;
        final players = session.setup.players;
        final current = id == null
            ? null
            : players.firstWhere((p) => p.id == id);
        final title = current != null
            ? l.questionFor(current.name)
            : stage == QuestionGameStage.players
            ? l.players
            : stage == QuestionGameStage.commonQuestion
            ? l.everyonesAnswers
            : stage == QuestionGameStage.result
            ? l.gameResult
            : l.questionDiscussion;
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
              child: stage == QuestionGameStage.players && current == null
                  ? CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: AppEdgeInsets.all24,
                          sliver: SliverToBoxAdapter(
                            child: AppHeroCard(
                              title: l.questionPassPhone,
                              icon: Icons.chat_bubble_outline_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.answersSubmitted(
                                      store.answers.value.length,
                                      players.length,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  LinearProgressIndicator(
                                    value:
                                        store.answers.value.length /
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
                          completed: store.answers.value.keys.toSet(),
                          completedLabel: l.answerSent,
                          onSelected: (id) {
                            store.selectPlayer(id);
                            answer.text = store.draft;
                          },
                        ),
                      ],
                    )
                  : current == null
                  ? _publicAnswers(stage)
                  : SingleChildScrollView(
                      padding: AppEdgeInsets.all24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            current.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (!store.revealed.value)
                            OutlinedButton(
                              key: const Key('secretCard'),
                              onPressed: store.reveal,
                              child: Padding(
                                padding: AppEdgeInsets.all24,
                                child: Text(l.tapToReveal),
                              ),
                            )
                          else ...[
                            if (!session.imposterIds.contains(current.id))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
                                child: Text(
                                  session.categoryName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.gray),
                                ),
                              ),
                            _questionCard(store.question),
                            if (session.prompt.localImageId != null)
                              LocalPromptImage(
                                session.prompt.localImageId!,
                                label: l.questionImage,
                              ),
                            if (store.teammates.isNotEmpty)
                              Card(
                                key: const Key('questionTeammates'),
                                semanticContainer: false,
                                color: AppColors.tealSurface,
                                child: Padding(
                                  padding: AppEdgeInsets.all24,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.knowEachOther,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      for (final teammate in store.teammates)
                                        Text(teammate.name),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.xl),
                            TextField(
                              key: const Key('privateAnswer'),
                              controller: answer,
                              minLines: 3,
                              maxLines: 8,
                              enableSuggestions: false,
                              autocorrect: false,
                              enableIMEPersonalizedLearning: false,
                              decoration: InputDecoration(
                                labelText: l.yourAnswer,
                                hintText: l.answerHint,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l.answersSubmitted(
                              store.answers.value.length,
                              players.length,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar:
                current != null || stage != QuestionGameStage.players
                ? AppActionBar(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: answer,
                      builder: (context, value, child) => FilledButton(
                        onPressed: current != null
                            ? store.revealed.value &&
                                      value.text.trim().isNotEmpty
                                  ? () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (store.submit()) answer.clear();
                                    }
                                  : null
                            : stage == QuestionGameStage.commonQuestion
                            ? store.startDiscussion
                            : stage == QuestionGameStage.discussion
                            ? store.revealResult
                            : _back,
                        child: Text(
                          current != null
                              ? l.submitAnswer
                              : stage == QuestionGameStage.commonQuestion
                              ? l.startRound
                              : stage == QuestionGameStage.discussion
                              ? l.findImposters
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

  Widget _publicAnswers(QuestionGameStage stage) {
    final l = AppLocalizations.of(context);
    final session = store.session;
    final players = session.setup.players;
    return CustomScrollView(
      key: PageStorageKey(stage),
      slivers: [
        SliverPadding(
          padding: AppEdgeInsets.all24,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _questionCard(session.prompt.civilianQuestion),
                if (stage == QuestionGameStage.result &&
                    session.prompt.localImageId != null)
                  LocalPromptImage(
                    session.prompt.localImageId!,
                    label: l.questionImage,
                  ),
                const SizedBox(height: AppSpacing.xl),
                if (stage == QuestionGameStage.commonQuestion)
                  AppNotice(message: l.commonQuestionHelp)
                else
                  Text(
                    l.startingPlayer(
                      players
                          .firstWhere((p) => p.id == session.startingPlayerId)
                          .name,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
              ],
            ),
          ),
        ),
        if (stage != QuestionGameStage.commonQuestion)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverList.builder(
              itemCount: players.length,
              itemBuilder: (context, i) {
                final p = players[i];
                final revealedImposter =
                    stage == QuestionGameStage.result &&
                    session.imposterIds.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    child: Padding(
                      padding: AppEdgeInsets.all24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}. ${p.name}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(store.answers.value[p.id]!),
                          if (revealedImposter) ...[
                            const Divider(height: 32),
                            Text(
                              l.imposters,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(session.prompt.imposterQuestion),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _questionCard(String question) => Card(
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: const BoxDecoration(gradient: AppEffects.selectedGradient),
      child: Padding(
        padding: AppEdgeInsets.all24,
        child: Text(question, style: Theme.of(context).textTheme.headlineSmall),
      ),
    ),
  );
}
