import 'package:flutter/material.dart';
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
        );
        final available = counts.keys.map((c) => c.id).toSet();
        final valid = selected.intersection(available);
        return Scaffold(
          appBar: AppBar(title: Text(l.categories)),
          body: SafeArea(
            child: ListView(
              padding: AppEdgeInsets.all24,
              children: [
                ContentNotices(store.content),
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
                          width: (constraints.maxWidth - AppSpacing.md) / 2,
                          child: Semantics(
                            selected: valid.contains(entry.key.id),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: valid.contains(entry.key.id)
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
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
                                    Text(
                                      entry.key.name,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      l.wordCount(entry.value),
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
                FilledButton(
                  onPressed:
                      store.editable && store.content.snapshot.value != null
                      ? () {
                          store.setCategories(selected);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(l.confirm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
