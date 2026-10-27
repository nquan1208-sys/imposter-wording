import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/widgets/app_content.dart';

Future<String?> presetNameDialog(
  BuildContext context,
  SetupStore store, {
  PlayerPreset? preset,
  GameSetup? draft,
}) async {
  var name = preset?.name ?? '';
  bool busy = false;
  String? error;
  final l = AppLocalizations.of(context);
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          scrollable: true,
          title: Text(preset == null ? l.newList : l.rename),
          content: SingleChildScrollView(
            child: TextFormField(
              initialValue: name,
              onChanged: (value) => name = value,
              autofocus: true,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: l.listName,
                hintText: l.listNameHint,
                errorText: error,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!store.validPresetName(name, exceptId: preset?.id)) {
                        update(() => error = l.invalidListName);
                        return;
                      }
                      update(() {
                        busy = true;
                        error = null;
                      });
                      final id = preset == null
                          ? await store.createPreset(name, draft!)
                          : await store.renamePreset(preset.id, name)
                          ? preset.id
                          : null;
                      if (!context.mounted) return;
                      if (id != null) {
                        Navigator.pop(context, id);
                      } else {
                        update(() {
                          busy = false;
                          error = l.settingsWriteError;
                        });
                      }
                    },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    ),
  );
  return result;
}

class PlayerPresetsScreen extends ConsumerWidget {
  const PlayerPresetsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(setupStoreProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.manageLists)),
      body: AppContent(
        child: SignalBuilder(
          builder: (context) => ListView(
            padding: AppEdgeInsets.all24,
            children: [
              if (store.reading.value) Text(l.settingsLoading),
              if (store.readFailed.value) ...[
                Text(l.settingsReadError),
                TextButton(onPressed: store.restore, child: Text(l.retry)),
              ],
              if (store.setup.value.presets.isEmpty && store.editable)
                Text(l.emptyLists),
              for (final p in store.setup.value.presets)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(p.name),
                    subtitle: Text(
                      '${l.playerCount(p.setup.players.length)}${store.setup.value.activePresetId == p.id ? ' · ${l.usingList}' : ''}',
                    ),
                    onTap: store.editable ? () => _details(context, p) : null,
                    trailing: PopupMenuButton<String>(
                      tooltip: l.listActions,
                      enabled: store.editable,
                      onSelected: (action) async {
                        if (action == 'details') {
                          _details(context, p);
                        }
                        if (action == 'rename') {
                          await presetNameDialog(context, store, preset: p);
                        }
                        if (action == 'delete' && context.mounted) {
                          await _delete(context, store, p);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'details', child: Text(l.details)),
                        PopupMenuItem(value: 'rename', child: Text(l.rename)),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            l.delete,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, SetupStore store, PlayerPreset p) {
    final l = AppLocalizations.of(context);
    var busy = false, failed = false;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !busy,
          child: AlertDialog(
            scrollable: true,
            title: Text(p.name),
            content: Text(failed ? l.settingsWriteError : l.deleteListConfirm),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        update(() => busy = true);
                        final success = await store.deletePreset(p.id);
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pop(context);
                        } else {
                          update(() {
                            busy = false;
                            failed = true;
                          });
                        }
                      },
                child: Text(l.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _details(BuildContext context, PlayerPreset p) {
    final l = AppLocalizations.of(context);
    final s = p.setup;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: AppEdgeInsets.all24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.details, style: Theme.of(context).textTheme.titleLarge),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name),
                  subtitle: Text(l.playerCount(s.players.length)),
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final player in s.players)
                    Chip(label: Text(player.name)),
                ],
              ),
              Text(l.savedRules, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${l.imposters}: ${s.randomImposters ? l.randomCount : '${l.fixedCount} · ${s.imposters}'}',
              ),
              for (final rule in [
                (l.imposterNotFirst, s.imposterNotFirst),
                (l.showCategory, s.showCategory),
                (l.knowEachOther, s.knowEachOther),
              ])
                Text('${rule.$1}: ${rule.$2 ? l.enabled : l.disabled}'),
              Text(l.listAutosave),
            ],
          ),
        ),
      ),
    );
  }
}
