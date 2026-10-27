import 'package:flutter/material.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/features/setup/content_notices.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_colors.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({
    super.key,
    required this.store,
    required this.selected,
    required this.onChanged,
    required this.selectionRemoved,
    required this.saveFailed,
    this.family = false,
    this.header,
  });

  final SetupStore store;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool selectionRemoved, saveFailed, family;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final counts = store.content.categoryCounts(
      family: family,
      gameType: store.setup.value.gameType,
    );
    final valid = selected.intersection(counts.keys.map((c) => c.id).toSet());
    return ListView(
      key: PageStorageKey(family),
      padding: AppEdgeInsets.all24,
      children: [
        ?header,
        ContentNotices(store.content),
        if (saveFailed) Text(l.settingsWriteError),
        if (selectionRemoved || selected.length != valid.length)
          Text(l.selectionRemoved),
        if (counts.isEmpty)
          Text(family ? l.emptyFamilyCategories : l.emptyContent),
        FilterChip(
          label: Text(l.allCategories),
          selected: valid.isEmpty,
          onSelected: store.editable ? (_) => onChanged({}) : null,
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
                          MediaQuery.textScalerOf(context).scale(16) > 24
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.md) / 2,
                  child: Semantics(
                    selected: valid.contains(entry.key.id),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: valid.contains(entry.key.id)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : AppColors.white,
                        side: BorderSide(
                          color: valid.contains(entry.key.id)
                              ? AppColors.charcoal
                              : AppColors.border,
                          width: valid.contains(entry.key.id) ? 2 : 1,
                        ),
                      ),
                      onPressed: store.editable
                          ? () {
                              final next = Set.of(valid);
                              if (!next.add(entry.key.id)) {
                                next.remove(entry.key.id);
                              }
                              onChanged(next);
                            }
                          : null,
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
                            Text(entry.key.name, textAlign: TextAlign.center),
                            Text(
                              store.setup.value.gameType == 'question'
                                  ? l.questionCount(entry.value)
                                  : l.wordCount(entry.value),
                              style: Theme.of(context).textTheme.bodySmall
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
    );
  }
}
