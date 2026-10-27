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

  Future<void> _start(SetupStore store) async {
    if (_openingGame) return;
    RouteInput? input;
    if (store.setup.value.gameType == 'question') {
      final session = QuestionGameSession.create(store);
      if (session != null) input = RouteInput.questionGame(session);
    } else {
      final session = WordGameSession.create(store);
      if (session != null) input = RouteInput.wordGame(session);
    }
    if (input == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).gameStartError)),
      );
      return;
    }
    setState(() => _openingGame = true);
    try {
      await ref.read(AppService.router).push(input);
    } finally {
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
            ? content
                  .eligibleQuestions(
                    family: setup.family,
                    categoryIds: setup.categoryIds,
                  )
                  .length
            : content
                  .eligibleWords(
                    family: setup.family,
                    categoryIds: setup.categoryIds,
                  )
                  .length;
        final textTheme = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(title: Text(l.setupTitle)),
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
                      onPressed: store.editable && count > 0 && !_openingGame
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
            child: SingleChildScrollView(
              padding: AppEdgeInsets.all24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (store.reading.value) Text(l.settingsLoading),
                  if (store.readFailed.value) ...[
                    Text(l.settingsReadError),
                    TextButton(
                      onPressed: store.reading.value ? null : store.restore,
                      child: Text(l.retry),
                    ),
                    TextButton(
                      onPressed: store.reading.value
                          ? null
                          : () async {
                              final reset = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l.resetSetup),
                                  content: Text(l.resetSetupConfirm),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(l.resetSetup),
                                    ),
                                  ],
                                ),
                              );
                              if (reset == true) store.reset();
                            },
                      child: Text(l.resetSetup),
                    ),
                  ],
                  if (store.writeFailed.value) ...[
                    Text(l.settingsWriteError),
                    TextButton(onPressed: store.save, child: Text(l.retry)),
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
                            semantics: l.playerCount(setup.players.length),
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
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(l.classicMode),
                        selected: !setup.family,
                        onSelected: store.editable
                            ? (_) => store.setFamily(false)
                            : null,
                      ),
                      ChoiceChip(
                        label: Text(l.familyMode),
                        selected: setup.family,
                        onSelected: store.editable
                            ? (_) => store.setFamily(true)
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
                            : l.selectedCategoryCount(setup.categoryIds.length),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: store.editable && content.snapshot.value != null
                          ? () => ref
                                .read(AppService.router)
                                .push(RouteInput.categories())
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (store.selectionRemoved.value) Text(l.selectionRemoved),
                  ContentNotices(content),
                  if (content.snapshot.value != null) ...[
                    Text(
                      setup.gameType == 'question'
                          ? l.questionCount(count)
                          : l.wordCount(count),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (count == 0) Text(l.emptyContent),
                  ],
                  SwitchListTile(
                    title: Text(l.imposterNotFirst),
                    value: setup.imposterNotFirst,
                    onChanged: store.editable
                        ? (v) => store.setRules(imposterNotFirst: v)
                        : null,
                  ),
                  if (setup.gameType == 'word') ...[
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
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AppContent(
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: AppEdgeInsets.all24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.imposters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SwitchListTile(
                  title: Text(l.randomCount),
                  subtitle: Text(l.imposterRange(setup.maxImposters)),
                  value: random,
                  onChanged: (v) => setState(() => random = v),
                ),
                if (!random)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l.fewerImposters,
                        onPressed: count > 1
                            ? () => setState(() => count--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$count'),
                      IconButton(
                        tooltip: l.moreImposters,
                        onPressed: count < setup.maxImposters
                            ? () => setState(() => count++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                FilledButton(
                  onPressed: () {
                    store.setRules(imposters: count, randomImposters: random);
                    Navigator.pop(context);
                  },
                  child: Text(l.confirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
