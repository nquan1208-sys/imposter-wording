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
    this.onEditCustom,
    this.onDeleteCustom,
  });

  final SetupStore store;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool selectionRemoved, saveFailed, family;
  final Widget? header;
  final VoidCallback? onCreateCustom;
  final ValueChanged<String>? onEditCustom, onDeleteCustom;

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
      padding: AppEdgeInsets.pageFor(context),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
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
          itemHeight: 184 * MediaQuery.textScalerOf(context).scale(16) / 16,
          children: [
            for (final entry in counts.entries)
              AppSelectionCard(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ExcludeSemantics(
                                child: Icon(
                                  valid.contains(entry.key.id)
                                      ? Icons.check_circle_outline
                                      : Icons.category_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (store.setup.value.customWordCategories.any(
                                (c) => c.id == entry.key.id,
                              ) ||
                              store.setup.value.customQuestionCategories.any(
                                (c) => c.id == entry.key.id,
                              ))
                            PopupMenuButton<String>(
                              tooltip: l.customCategoryActions,
                              icon: const Icon(
                                Icons.more_horiz,
                                color: AppColors.textMuted,
                              ),
                              enabled: store.editable,
                              onSelected: (action) {
                                if (action == 'edit') {
                                  onEditCustom?.call(entry.key.id);
                                } else {
                                  onDeleteCustom?.call(entry.key.id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l.editCustomCategory),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l.delete),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      entry.key.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.setup.value.gameType == 'question'
                                ? l.questionCount(entry.value)
                                : l.wordCount(entry.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        if (store.categoryHasImages(entry.key.id))
                          Tooltip(
                            message: l.hasLocalImages,
                            child: Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                              semanticLabel: l.hasLocalImages,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (onCreateCustom != null)
              Padding(
                padding: const EdgeInsets.all(4),
                child: OutlinedButton(
                  key: const Key('createCustomCategory'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.accentText),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                  onPressed: store.editable ? onCreateCustom : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.accentText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l.createCustomCategory,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.accentText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
