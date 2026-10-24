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

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(setupStoreProvider);
    final content = store.content;
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final setup = store.setup.value;
        final count = content
            .eligibleWords(family: setup.family, categoryIds: setup.categoryIds)
            .length;
        const background = Color(0xFFFCF9F8);
        final textTheme = Theme.of(context).textTheme;
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: Text(l.setupTitle),
            backgroundColor: background,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: AppEdgeInsets.all24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      child: Text(l.startGame),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
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
                                ? () => _players(context, store)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _statCard(
                            context,
                            label: l.imposters,
                            value: '1',
                            semantics: '${l.imposters}: 1',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.gameMode, style: textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: AppEdgeInsets.all16,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.yellow, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.font_download_outlined,
                          color: AppColors.amber,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l.wordGame, style: textTheme.labelLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
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
                      contentPadding: AppEdgeInsets.all24,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.tealSurface,
                        child: Icon(
                          Icons.category_outlined,
                          color: Color(0xFF006F4D),
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
                      l.wordCount(count),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (count == 0) Text(l.emptyContent),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(l.gameComingSoon, style: textTheme.bodySmall),
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
            ],
          ),
        ),
      ),
    ),
  );

  void _players(BuildContext context, SetupStore store) {
    final l = AppLocalizations.of(context);
    var count = store.setup.value.players.length;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: AppEdgeInsets.all24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.players, style: Theme.of(context).textTheme.titleLarge),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l.decreasePlayers,
                      onPressed: count > 3
                          ? () => setState(() => count--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(l.playerCount(count)),
                    IconButton(
                      tooltip: l.increasePlayers,
                      onPressed: count < 100
                          ? () => setState(() => count++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () {
                    store.setPlayerCount(count);
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
