import 'package:flutter/material.dart';
import 'package:untitled/features/setup/all_categories_screen.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class FamilyCategoriesScreen extends StatelessWidget {
  const FamilyCategoriesScreen({
    super.key,
    required this.store,
    required this.selected,
    required this.onChanged,
    required this.selectionRemoved,
    required this.saveFailed,
    required this.showWordImages,
    required this.onImagesChanged,
  });

  final SetupStore store;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool selectionRemoved, saveFailed, showWordImages;
  final ValueChanged<bool> onImagesChanged;

  @override
  Widget build(BuildContext context) => AllCategoriesScreen(
    store: store,
    selected: selected,
    onChanged: onChanged,
    selectionRemoved: selectionRemoved,
    saveFailed: saveFailed,
    family: true,
    header: SwitchListTile(
      title: Text(AppLocalizations.of(context).showWordImages),
      value: showWordImages,
      onChanged: store.editable ? onImagesChanged : null,
    ),
  );
}
