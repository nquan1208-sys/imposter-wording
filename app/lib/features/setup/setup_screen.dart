import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/widgets/app_card_grid.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/features/settings/content_language_tile.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/content_notices.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _openingGame = false;
  Future<void> _start(SetupStore store) async {
    if (_openingGame || !store.contentReady) return;
    setState(() => _openingGame = true);
    await store.pendingWrites;
    await store.revalidate();
    if (!mounted) return;
    RouteInput? input;
    VoidCallback? releaseImage;
    if (store.setup.value.gameType == 'question') {
      final session = QuestionGameSession.create(store);
      if (session != null) input = RouteInput.questionGame(session);
    } else {
      final session = WordGameSession.create(store);
      if (session != null) {
        input = RouteInput.wordGame(session);
        if (session.showWordImages) {
          releaseImage = store.content.images?.pin(session.prompt.imagePath);
        }
      }
    }
    if (input == null || store.writeFailed.value) {
      releaseImage?.call();
      setState(() => _openingGame = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).gameStartError)),
      );
      return;
    }
    setState(() => _openingGame = true);
    store.sessionActive.value = true;
    try {
      await ref.read(AppService.router).push(input);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).gameStartError)),
        );
      }
    } finally {
      store.sessionActive.value = false;
      releaseImage?.call();
      if (mounted) setState(() => _openingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(setupStoreProvider);
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final setup = store.setup.value;
        final content = store.content;
        final count = setup.gameType == 'question'
            ? store.eligibleQuestions(categoryIds: setup.categoryIds).length
            : store
                  .eligibleWords(
                    family: setup.family,
                    categoryIds: setup.categoryIds,
                  )
                  .length;
        final textTheme = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.setupTitle),
            actions: [
              IconButton(
                tooltip: l.settingsTitle,
                onPressed: () =>
                    ref.read(AppService.router).push(RouteInput.settings()),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          bottomNavigationBar: AppActionBar(
            child: FilledButton(
              onPressed:
                  store.editable &&
                      store.contentReady &&
                      count > 0 &&
                      !_openingGame
                  ? () => _start(store)
                  : null,
              child: _openingGame
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: l.startGame,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(Icons.play_arrow_rounded),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: Text(l.startGame)),
                      ],
                    ),
            ),
          ),
          body: AppContent(
            child: RefreshIndicator(
              onRefresh: content.load,
              semanticsLabel: l.refreshContent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppEdgeInsets.all24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (store.reading.value) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(l.settingsLoading),
                    ],
                    if (store.readFailed.value) ...[
                      AppNotice(message: l.settingsReadError, error: true),
                      TextButton(
                        onPressed: store.reading.value ? null : store.restore,
                        child: Text(l.retry),
                      ),
                    ],
                    if (store.writeFailed.value) ...[
                      AppNotice(message: l.settingsWriteError, error: true),
                      TextButton(
                        onPressed: store.editable ? store.save : null,
                        child: Text(l.retry),
                      ),
                    ],
                    AppCardGrid(
                      children: [
                        _statCard(
                          context,
                          label: l.players,
                          icon: Icons.group_outlined,
                          value: '${setup.players.length}',
                          semantics: l.playerCount(setup.players.length),
                          onTap: store.editable
                              ? () => ref
                                    .read(AppService.router)
                                    .push(RouteInput.playerNames())
                              : null,
                        ),
                        _statCard(
                          context,
                          label: l.imposters,
                          icon: Icons.person_search_outlined,
                          value: setup.randomImposters
                              ? l.randomCount
                              : '${setup.imposters}',
                          semantics:
                              '${l.imposters}: ${setup.randomImposters ? l.randomCount : setup.imposters}',
                          onTap: store.editable
                              ? () => _imposters(context, store)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(l.gameMode, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    AppCardGrid(
                      children: [
                        for (final type in ['word', 'question'])
                          AppSelectionCard(
                            key: ValueKey('game-type-$type'),
                            selected: setup.gameType == type,
                            onTap: store.editable
                                ? () => store.setGameType(type)
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ExcludeSemantics(
                                      child: Icon(
                                        type == 'word'
                                            ? Icons.style_outlined
                                            : Icons.forum_outlined,
                                        color: AppColors.teal,
                                        size: 32,
                                      ),
                                    ),
                                    const Spacer(),
                                    ExcludeSemantics(
                                      child: AnimatedSwitcher(
                                        duration: AppEffects.duration(context),
                                        child: Icon(
                                          setup.gameType == type
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          key: ValueKey(setup.gameType == type),
                                          color: AppColors.teal,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  type == 'word' ? l.wordGame : l.questionGame,
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  type == 'word'
                                      ? l.wordGameSummary
                                      : l.questionGameSummary,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Card(
                      child: Column(
                        children: [
                          if (setup.gameType == 'word') ...[
                            SwitchListTile(
                              secondary: const ExcludeSemantics(
                                child: Icon(Icons.visibility_outlined),
                              ),
                              title: Text(l.showCategory),
                              value: setup.showCategory,
                              onChanged: store.editable
                                  ? (v) => store.setRules(showCategory: v)
                                  : null,
                            ),
                            const Divider(height: 1),
                          ],
                          SwitchListTile(
                            secondary: const ExcludeSemantics(
                              child: Icon(Icons.group_outlined),
                            ),
                            title: Text(l.knowEachOther),
                            value: setup.knowEachOther,
                            onChanged: store.editable
                                ? (v) => store.setRules(knowEachOther: v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(l.categories, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: const Key('categoryPicker'),
                        contentPadding: AppEdgeInsets.all24,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.tealSurface,
                          child: Icon(
                            Icons.category_outlined,
                            color: AppColors.teal,
                          ),
                        ),
                        title: Text(
                          setup.categoryIds.isEmpty
                              ? l.allCategories
                              : l.selectedCategoryCount(
                                  setup.categoryIds.length,
                                ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: store.editable
                            ? () => ref
                                  .read(AppService.router)
                                  .push(RouteInput.categories())
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (store.selectionRemoved.value)
                      AppNotice(message: l.selectionRemoved),
                    ContentNotices(content),
                    const Card(child: ContentLanguageTile()),
                    const SizedBox(height: AppSpacing.lg),
                    if (content.snapshot.value != null ||
                        setup.hasCustomContent) ...[
                      Text(
                        setup.gameType == 'question'
                            ? l.questionCount(count)
                            : l.wordCount(count),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (count == 0) AppNotice(message: l.emptyContent),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required String semantics,
    VoidCallback? onTap,
  }) => Semantics(
    label: semantics,
    button: onTap != null,
    onTap: onTap,
    excludeSemantics: true,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppEffects.accentGradient),
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            padding: AppEdgeInsets.all24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    backgroundColor: AppColors.tealSurface,
                    foregroundColor: AppColors.teal,
                    child: Icon(icon),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedSwitcher(
                  duration: AppEffects.duration(context),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Icon(Icons.tune_rounded, size: 20, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _imposters(BuildContext context, SetupStore store) {
    final l = AppLocalizations.of(context);
    final setup = store.setup.value;
    var count = setup.imposters;
    var random = setup.randomImposters;
    var notFirst = setup.imposterNotFirst;
    var busy = false, failed = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !busy,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ExcludeSemantics(child: Icon(Icons.tune, size: 32)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l.chooseImposters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final value in [false, true])
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppSelectionCard(
                        selected: random == value,
                        onTap: busy ? null : () => update(() => random = value),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                random == value
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value ? l.randomCount : l.fixedCount,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    value
                                        ? l.randomCountHelp
                                        : l.fixedCountHelp,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!random)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: l.fewerImposters,
                          onPressed: !busy && count > 1
                              ? () => update(() => count--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        IconButton(
                          tooltip: l.moreImposters,
                          onPressed: !busy && count < setup.maxImposters
                              ? () => update(() => count++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  if (!random && count == 1)
                    Text(l.recommendedImposter, textAlign: TextAlign.center),
                  Text(
                    l.imposterRange(setup.maxImposters),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (setup.maxImposters == 1)
                    Card(
                      key: const Key('imposterLimitWarning'),
                      color: AppColors.yellow,
                      child: Padding(
                        padding: AppEdgeInsets.all16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l.moreImpostersNeedPlayers,
                                style: const TextStyle(
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SwitchListTile(
                    title: Text(l.imposterNotFirst),
                    value: notFirst,
                    onChanged: busy ? null : (v) => update(() => notFirst = v),
                  ),
                  if (failed)
                    AppNotice(message: l.settingsWriteError, error: true),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                update(() {
                                  busy = true;
                                  failed = false;
                                });
                                final success = await store.setRules(
                                  imposters: count,
                                  randomImposters: random,
                                  imposterNotFirst: notFirst,
                                );
                                if (!context.mounted) return;
                                if (success) {
                                  Navigator.pop(context);
                                } else {
                                  update(() {
                                    busy = false;
                                    failed = true;
                                  });
                                }
                              },
                        child: Text(l.confirm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
