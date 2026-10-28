import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/widgets/app_card_grid.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/features/settings/content_language_tile.dart';
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
    this.onCreateCustom,
  });

  final SetupStore store;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool selectionRemoved, saveFailed, family;
  final Widget? header;
  final VoidCallback? onCreateCustom;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final counts = store.categoryCounts(
      family: family,
      gameType: store.setup.value.gameType,
    );
    final valid = selected.intersection(counts.keys.map((c) => c.id).toSet());
    return ListView(
      key: PageStorageKey(family),
      padding: AppEdgeInsets.all24,
      children: [
        if (saveFailed) AppNotice(message: l.settingsWriteError, error: true),
        ?header,
        const Card(child: ContentLanguageTile()),
        const SizedBox(height: AppSpacing.xl),
        if (counts.isEmpty)
          AppNotice(message: family ? l.emptyFamilyCategories : l.emptyContent),
        ContentNotices(store.content),
        if (selectionRemoved || selected.length != valid.length)
          AppNotice(message: l.selectionRemoved),
        AppSelectionCard(
          selected: valid.isEmpty,
          onTap: store.editable ? () => onChanged({}) : null,
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  valid.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.circle_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l.allCategories,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCardGrid(
          children: [
            for (final entry in counts.entries)
              AppSelectionCard(
                selected: valid.contains(entry.key.id),
                onTap: store.editable
                    ? () {
                        final next = Set.of(valid);
                        if (!next.add(entry.key.id)) next.remove(entry.key.id);
                        onChanged(next);
                      }
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        valid.contains(entry.key.id)
                            ? Icons.check_circle_outline
                            : Icons.category_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      entry.key.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (store.categoryHasImages(entry.key.id))
                      Text(
                        l.hasLocalImages,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      store.setup.value.gameType == 'question'
                          ? l.questionCount(entry.value)
                          : l.wordCount(entry.value),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            if (onCreateCustom != null)
              OutlinedButton(
                key: const Key('createCustomCategory'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.tealSurface,
                  side: const BorderSide(color: AppColors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  padding: AppEdgeInsets.all24,
                ),
                onPressed: store.editable ? onCreateCustom : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.add_circle_outline,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l.createCustomCategory),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
