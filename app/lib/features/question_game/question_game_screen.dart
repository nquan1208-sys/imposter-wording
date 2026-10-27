import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class QuestionGameScreen extends StatefulWidget {
  final QuestionGameSession session;
  const QuestionGameScreen({super.key, required this.session});

  @override
  State<QuestionGameScreen> createState() => _QuestionGameScreenState();
}

class _QuestionGameScreenState extends State<QuestionGameScreen>
    with WidgetsBindingObserver {
  late final store = QuestionGameStore(widget.session);
  final answer = TextEditingController();
  bool _exiting = false, _dialogOpen = false;

  @override
  void initState() {
    super.initState();
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.questionPassPhone),
                                const SizedBox(height: AppSpacing.md),
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
                              final done = store.answers.value.containsKey(
                                p.id,
                              );
                              return Card(
                                child: TextButton(
                                  key: ValueKey(p.id),
                                  onPressed: done
                                      ? null
                                      : () {
                                          store.selectPlayer(p.id);
                                          answer.text = store.draft;
                                        },
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ExcludeSemantics(
                                          child: CircleAvatar(
                                            child: Text(
                                              p.name.characters.first,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          p.name,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (done) Text(l.answerSent),
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
                          if (current != null) ...[
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
                              Text(session.categoryName),
                              _questionCard(store.question),
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
                                  border: const OutlineInputBorder(),
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
                          ] else ...[
                            _questionCard(session.prompt.civilianQuestion),
                            if (stage == QuestionGameStage.commonQuestion)
                              Text(l.commonQuestionHelp)
                            else ...[
                              Text(
                                l.startingPlayer(
                                  players
                                      .firstWhere(
                                        (p) => p.id == session.startingPlayerId,
                                      )
                                      .name,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              for (final (i, p) in players.indexed)
                                Card(
                                  child: Padding(
                                    padding: AppEdgeInsets.all16,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${i + 1}. ${p.name}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(store.answers.value[p.id]!),
                                        if (stage == QuestionGameStage.result &&
                                            session.imposterIds.contains(
                                              p.id,
                                            )) ...[
                                          Text(
                                            l.imposters,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(session.prompt.imposterQuestion),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar:
                current != null || stage != QuestionGameStage.players
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: AppContent(
                      top: false,
                      child: Padding(
                        padding: AppEdgeInsets.all16,
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
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _questionCard(String question) => Card(
    child: Padding(
      padding: AppEdgeInsets.all24,
      child: Text(question, style: Theme.of(context).textTheme.headlineSmall),
    ),
  );
}
