import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/all_categories_screen.dart';
import 'package:untitled/features/setup/family_categories_screen.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

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
  bool selectionRemoved = false, saveFailed = false;
  @override
  void initState() {
    super.initState();
    final setup = ref.read(setupStoreProvider).setup.value;
    selected = Set.of(setup.categoryIds);
    family = setup.gameType == 'word' && setup.family;
    showWordImages = setup.showWordImages;
    tabs = TabController(length: 2, initialIndex: family ? 1 : 0, vsync: this)
      ..addListener(changeTab);
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
    final id = await ref
        .read(AppService.router)
        .push<String>(RouteInput.customWords(family: family));
    if (mounted && id != null) setState(() => selected = {...selected, id});
  }

  @override
  void dispose() {
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
          onCreateCustom: store.setup.value.gameType == 'word'
              ? createCustom
              : null,
        );
        return Scaffold(
          appBar: AppBar(title: Text(l.categories)),
          bottomNavigationBar: AppContent(
            top: false,
            child: Padding(
              padding: AppEdgeInsets.all24,
              child: FilledButton(
                onPressed: store.editable
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
            ),
          ),
          body: AppContent(
            child: store.setup.value.gameType == 'word'
                ? Column(
                    children: [
                      IgnorePointer(
                        ignoring: !store.editable,
                        child: TabBar(
                          controller: tabs,
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          tabs: [
                            Tab(text: l.allCategories),
                            Tab(text: l.familyCategories),
                          ],
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
