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
        return Scaffold(
          appBar: AppBar(title: Text(l.setupTitle)),
          body: SafeArea(
            child: ListView(
              padding: AppEdgeInsets.all24,
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.players),
                  subtitle: Text(l.playerCount(setup.players.length)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: store.editable ? () => _players(context, store) : null,
                ),
                Text(
                  l.imposters,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.wordGame,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.categories),
                  subtitle: Text(
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
                if (store.selectionRemoved.value) Text(l.selectionRemoved),
                ContentNotices(content),
                if (content.snapshot.value != null) ...[
                  Text(
                    l.wordCount(count),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (count == 0) Text(l.emptyContent),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: null, child: Text(l.startGame)),
                const SizedBox(height: AppSpacing.sm),
                Text(l.gameComingSoon),
              ],
            ),
          ),
        );
      },
    );
  }

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
