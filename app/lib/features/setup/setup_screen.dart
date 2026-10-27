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

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _openingGame = false;
  bool _leaving = false, _exiting = false;

  Future<void> _leave(SetupStore store) async {
    if (_leaving || _exiting || store.reading.value || store.writing.value) {
      return;
    }
    final l = AppLocalizations.of(context);
    setState(() => _leaving = true);
    if (store.setup.value.hasCustomContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.clearCustomContentTitle),
          content: Text(l.clearCustomContentHelp),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.clearCustomContentAction),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _leaving = false);
        return;
      }
      final saved = await store.clearCustomCategories();
      if (!mounted) return;
      if (!saved) {
        setState(() => _leaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.settingsWriteError)));
        return;
      }
    }
    setState(() => _exiting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _start(SetupStore store) async {
    if (_openingGame) return;
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
    try {
      await ref.read(AppService.router).push(input);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).gameStartError)),
        );
      }
    } finally {
      releaseImage?.call();
      if (mounted) setState(() => _openingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(setupStoreProvider);
    final content = store.content;
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final setup = store.setup.value;
        final count = setup.gameType == 'question'
            ? store.eligibleQuestions(categoryIds: setup.categoryIds).length
            : store
                  .eligibleWords(
                    family: setup.family,
                    categoryIds: setup.categoryIds,
                  )
                  .length;
        final textTheme = Theme.of(context).textTheme;
        return PopScope(
          canPop:
              _exiting ||
              (!_leaving &&
                  !store.reading.value &&
                  !store.writing.value &&
                  !setup.hasCustomContent),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(store);
          },
          child: AbsorbPointer(
            absorbing: _leaving,
            child: Scaffold(
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
              bottomNavigationBar: AppContent(
                top: false,
                child: Padding(
                  padding: AppEdgeInsets.all24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              store.editable && count > 0 && !_openingGame
                              ? () => _start(store)
                              : null,
                          child: Text(l.startGame),
                        ),
                      ),
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
                        if (store.reading.value) Text(l.settingsLoading),
                        if (store.readFailed.value) ...[
                          Text(l.settingsReadError),
                          TextButton(
                            onPressed: store.reading.value
                                ? null
                                : store.restore,
                            child: Text(l.retry),
                          ),
                        ],
                        if (store.writeFailed.value) ...[
                          Text(l.settingsWriteError),
                          TextButton(
                            onPressed: store.editable ? store.save : null,
                            child: Text(l.retry),
                          ),
                        ],
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _statCard(
                                  context,
                                  label: l.players,
                                  value: '${setup.players.length}',
                                  semantics: l.playerCount(
                                    setup.players.length,
                                  ),
                                  onTap: store.editable
                                      ? () => ref
                                            .read(AppService.router)
                                            .push(RouteInput.playerNames())
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: _statCard(
                                  context,
                                  label: l.imposters,
                                  value: setup.randomImposters
                                      ? l.randomCount
                                      : '${setup.imposters}',
                                  semantics:
                                      '${l.imposters}: ${setup.randomImposters ? l.randomCount : setup.imposters}',
                                  onTap: store.editable
                                      ? () => _imposters(context, store)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(l.gameMode, style: textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final type in ['word', 'question'])
                              ChoiceChip(
                                label: Text(
                                  type == 'word' ? l.wordGame : l.questionGame,
                                ),
                                selected: setup.gameType == type,
                                onSelected: store.editable
                                    ? (_) => store.setGameType(type)
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(l.categories, style: textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                          Text(l.selectionRemoved),
                        ContentNotices(content),
                        Text(l.contentLanguageVietnamese),
                        if (content.snapshot.value != null ||
                            setup.hasCustomContent) ...[
                          Text(
                            setup.gameType == 'question'
                                ? l.questionCount(count)
                                : l.wordCount(count),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (count == 0) Text(l.emptyContent),
                        ],
                        SwitchListTile(
                          title: Text(l.showCategory),
                          value: setup.showCategory,
                          onChanged: store.editable
                              ? (v) => store.setRules(showCategory: v)
                              : null,
                        ),
                        SwitchListTile(
                          title: Text(l.knowEachOther),
                          value: setup.knowEachOther,
                          onChanged: store.editable
                              ? (v) => store.setRules(knowEachOther: v)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: AppEdgeInsets.all16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: Theme.of(context).textTheme.headlineLarge),
              Icon(onTap != null ? Icons.tune : Icons.person_outline, size: 20),
            ],
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
                  const Icon(Icons.tune),
                  Text(
                    l.chooseImposters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final value in [false, true])
                    Card(
                      child: ListTile(
                        selected: random == value,
                        leading: Icon(
                          random == value
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(value ? l.randomCount : l.fixedCount),
                        subtitle: Text(
                          value ? l.randomCountHelp : l.fixedCountHelp,
                        ),
                        onTap: busy ? null : () => update(() => random = value),
                      ),
                    ),
                  if (!random)
                    Wrap(
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
                  if (!random) Text(l.recommendedImposter),
                  Text(l.imposterRange(setup.maxImposters)),
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
                  if (failed) Text(l.settingsWriteError),
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
