import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/all_categories_screen.dart';
import 'package:untitled/features/setup/family_categories_screen.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late Set<String> selected;
  late bool family, showWordImages;
  late String contentLocale;
  late final void Function() stopLocaleEffect;
  bool selectionRemoved = false, saveFailed = false;
  @override
  void initState() {
    super.initState();
    final setup = ref.read(setupStoreProvider).setup.value;
    contentLocale = setup.contentLocale;
    selected = Set.of(setup.categoryIds);
    family = setup.gameType == 'word' && setup.family;
    showWordImages = setup.showWordImages;
    tabs = TabController(
      length: 2,
      initialIndex: family ? 1 : 0,
      animationDuration: AppEffects.transition,
      vsync: this,
    )..addListener(changeTab);
    final store = ref.read(setupStoreProvider);
    stopLocaleEffect = effect(() {
      final locale = store.setup.value.contentLocale;
      if (locale == contentLocale) return;
      untracked(() {
        setState(() {
          contentLocale = locale;
          final setup = store.setup.value;
          selected = Set.of(setup.categoryIds);
          family = setup.family;
          showWordImages = setup.showWordImages;
          selectionRemoved = false;
          saveFailed = false;
          tabs.index = family ? 1 : 0;
        });
      });
    });
  }

  void changeTab() {
    final nextFamily = tabs.index == 1;
    if (nextFamily == family) return;
    setState(() {
      family = nextFamily;
      final available = ref
          .read(setupStoreProvider)
          .categoryCounts(family: family)
          .keys
          .map((c) => c.id)
          .toSet();
      final retained = selected.intersection(available);
      selectionRemoved = selected.length != retained.length;
      selected = retained;
    });
  }

  void updateSelection(Set<String> value) => setState(() => selected = value);

  Future<void> createCustom() async {
    final locale = contentLocale;
    final id = await ref
        .read(AppService.router)
        .push<String>(
          RouteInput.customWords(
            family: family,
            gameType: ref.read(setupStoreProvider).setup.value.gameType,
          ),
        );
    if (mounted &&
        id != null &&
        locale == ref.read(setupStoreProvider).setup.value.contentLocale) {
      setState(() => selected = {...selected, id});
    }
  }

  @override
  void dispose() {
    stopLocaleEffect();
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(setupStoreProvider);
    final l = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final counts = store.categoryCounts(
          family: family,
          gameType: store.setup.value.gameType,
        );
        final available = counts.keys.map((c) => c.id).toSet();
        final valid = selected.intersection(available);
        final allCategories = AllCategoriesScreen(
          store: store,
          selected: selected,
          onChanged: updateSelection,
          selectionRemoved: selectionRemoved,
          saveFailed: saveFailed,
          onCreateCustom: createCustom,
        );
        return Scaffold(
          appBar: AppBar(title: Text(l.categories)),
          bottomNavigationBar: AppActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    valid.isEmpty
                        ? l.allCategories
                        : l.selectedCategoryCount(valid.length),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: store.editable && store.contentReady
                      ? () async {
                          final saved = await store.setCategories(
                            valid,
                            family: family,
                            showWordImages: showWordImages,
                          );
                          if (mounted && !saved) {
                            setState(() => saveFailed = true);
                          }
                          if (context.mounted && saved) Navigator.pop(context);
                        }
                      : null,
                  child: Text(l.confirm),
                ),
              ],
            ),
          ),
          body: AppContent(
            child: store.setup.value.gameType == 'word'
                ? Column(
                    children: [
                      IgnorePointer(
                        ignoring: !store.editable,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(
                              AppRadii.control,
                            ),
                          ),
                          child: TabBar(
                            controller: tabs,
                            onTap: (index) {
                              if (MediaQuery.disableAnimationsOf(context)) {
                                tabs.index = index;
                              }
                            },
                            tabAlignment: TabAlignment.fill,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            tabs: [
                              for (final label in [
                                l.allCategories,
                                l.familyCategories,
                              ])
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 24,
                                  ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabs,
                          physics: store.editable
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          children: [
                            allCategories,
                            FamilyCategoriesScreen(
                              store: store,
                              selected: selected,
                              onChanged: updateSelection,
                              selectionRemoved: selectionRemoved,
                              saveFailed: saveFailed,
                              showWordImages: showWordImages,
                              onImagesChanged: (value) =>
                                  setState(() => showWordImages = value),
                              onCreateCustom: createCustom,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : allCategories,
          ),
        );
      },
    );
  }
}
