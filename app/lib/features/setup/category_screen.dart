import 'package:untitled/widgets/app_content.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/content_notices.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late Set<String> selected;
  @override
  void initState() {
    super.initState();
    selected = Set.of(ref.read(setupStoreProvider).setup.value.categoryIds);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(setupStoreProvider);
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final counts = store.content.categoryCounts(
          family: store.setup.value.family,
          gameType: store.setup.value.gameType,
        );
        final available = counts.keys.map((c) => c.id).toSet();
        final valid = selected.intersection(available);
        return Scaffold(
          appBar: AppBar(title: Text(l.categories)),
          bottomNavigationBar: AppContent(
            top: false,
            child: Padding(
              padding: AppEdgeInsets.all24,
              child: FilledButton(
                onPressed:
                    store.editable && store.content.snapshot.value != null
                    ? () async {
                        final saved = await store.setCategories(selected);
                        if (context.mounted && saved) Navigator.pop(context);
                      }
                    : null,
                child: Text(l.confirm),
              ),
            ),
          ),
          body: AppContent(
            child: ListView(
              padding: AppEdgeInsets.all24,
              children: [
                Text(
                  '${store.setup.value.gameType == 'question' ? l.questionGame : l.wordGame} · ${store.setup.value.family ? l.familyMode : l.classicMode}',
                ),
                ContentNotices(store.content),
                if (store.writeFailed.value) Text(l.settingsWriteError),
                if (selected.length != valid.length) Text(l.selectionRemoved),
                if (counts.isEmpty) Text(l.emptyContent),
                FilterChip(
                  label: Text(l.allCategories),
                  selected: valid.isEmpty,
                  onSelected: (_) => setState(() => selected.clear()),
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final entry in counts.entries)
                        SizedBox(
                          width:
                              constraints.maxWidth < 360 ||
                                  MediaQuery.textScalerOf(context).scale(16) >
                                      24
                              ? constraints.maxWidth
                              : (constraints.maxWidth - AppSpacing.md) / 2,
                          child: Semantics(
                            selected: valid.contains(entry.key.id),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: valid.contains(entry.key.id)
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : AppColors.white,
                                side: BorderSide(
                                  color: valid.contains(entry.key.id)
                                      ? AppColors.charcoal
                                      : AppColors.border,
                                  width: valid.contains(entry.key.id) ? 2 : 1,
                                ),
                              ),
                              onPressed: () => setState(() {
                                selected = Set.of(valid);
                                if (!selected.add(entry.key.id)) {
                                  selected.remove(entry.key.id);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      valid.contains(entry.key.id)
                                          ? Icons.check_circle_outline
                                          : Icons.category_outlined,
                                      color: AppColors.charcoal,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      entry.key.name,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      store.setup.value.gameType == 'question'
                                          ? l.questionCount(entry.value)
                                          : l.wordCount(entry.value),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.gray),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}
