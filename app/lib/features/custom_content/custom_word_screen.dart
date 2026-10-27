import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/models/custom_word_category.dart';
import 'package:untitled/widgets/app_content.dart';

Future<bool> _discard(BuildContext context) async {
  final l = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.discardCustomDraft),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.discard),
            ),
          ],
        ),
      ) ==
      true;
}

class CustomWordScreen extends ConsumerStatefulWidget {
  final bool family;
  const CustomWordScreen({super.key, required this.family});

  @override
  ConsumerState<CustomWordScreen> createState() => _CustomWordScreenState();
}

class _CustomWordScreenState extends ConsumerState<CustomWordScreen> {
  final name = TextEditingController();
  final words = <String>[];
  bool suitable = false,
      busy = false,
      failed = false,
      exiting = false,
      asking = false;
  bool get dirty => name.text.isNotEmpty || words.isNotEmpty || suitable;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (busy || asking || exiting) return;
    asking = true;
    final discard = !dirty || await _discard(context);
    asking = false;
    if (mounted && discard) close();
  }

  void close([String? id]) {
    setState(() => exiting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, id);
    });
  }

  Future<void> addWords(bool batch) async {
    final entries = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WordEntryDialog(batch: batch, existing: words),
    );
    if (mounted && entries != null) setState(() => words.addAll(entries));
  }

  Future<void> save() async {
    final store = ref.read(setupStoreProvider);
    if (busy ||
        !store.editable ||
        words.isEmpty ||
        !store.validCustomCategoryName(name.text) ||
        (widget.family && !suitable)) {
      setState(() {});
      return;
    }
    setState(() {
      busy = true;
      failed = false;
    });
    final id = await store.createCustomWordCategory(
      name.text,
      words,
      family: widget.family && suitable,
    );
    if (!mounted) return;
    if (id != null) {
      close(id);
    } else {
      setState(() {
        busy = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final validName = ref
        .read(setupStoreProvider)
        .validCustomCategoryName(name.text);
    return PopScope(
      canPop: exiting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.createCustomCategory),
          leading: BackButton(onPressed: leave),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AppContent(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed:
                    !busy &&
                        validName &&
                        words.isNotEmpty &&
                        (!widget.family || suitable)
                    ? save
                    : null,
                child: Text(busy ? l.customSaving : l.saveCustomCategory),
              ),
            ),
          ),
        ),
        body: AppContent(
          child: AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.customCategoryName,
                    hintText: l.customCategoryNameHint,
                    errorText: name.text.trim().isNotEmpty && !validName
                        ? l.customCategoryNameExists
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text(
                  l.customWordList,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(l.wordCount(words.length)),
                if (words.isEmpty) Text(l.customWordsEmpty),
                for (var i = 0; i < words.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(words[i]),
                    trailing: IconButton(
                      tooltip: l.removeCustomWord(words[i]),
                      onPressed: () => setState(() => words.removeAt(i)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => addWords(false),
                      child: Text(l.addCustomWord),
                    ),
                    TextButton(
                      onPressed: () => addWords(true),
                      child: Text(l.importCustomWords),
                    ),
                  ],
                ),
                if (widget.family)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.customFamilyConfirmation),
                    value: suitable,
                    onChanged: (value) =>
                        setState(() => suitable = value == true),
                  ),
                if (failed)
                  Semantics(liveRegion: true, child: Text(l.customSaveError)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordEntryDialog extends StatefulWidget {
  final bool batch;
  final List<String> existing;
  const _WordEntryDialog({required this.batch, required this.existing});

  @override
  State<_WordEntryDialog> createState() => _WordEntryDialogState();
}

class _WordEntryDialogState extends State<_WordEntryDialog> {
  final text = TextEditingController();
  bool invalid = false, exiting = false, asking = false;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (asking || exiting) return;
    asking = true;
    final discard = text.text.isEmpty || await _discard(context);
    asking = false;
    if (mounted && discard) close();
  }

  void close([List<String>? entries]) {
    setState(() => exiting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, entries);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: exiting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: AlertDialog(
        title: Text(widget.batch ? l.importCustomWords : l.addCustomWord),
        scrollable: true,
        content: TextField(
          controller: text,
          autofocus: true,
          minLines: widget.batch ? 4 : 1,
          maxLines: widget.batch ? 8 : 1,
          decoration: InputDecoration(
            labelText: widget.batch ? l.customOneWordPerLine : l.customWord,
            errorText: invalid ? l.customWordInvalid : null,
          ),
          onChanged: (_) {
            if (invalid) setState(() => invalid = false);
          },
        ),
        actions: [
          TextButton(onPressed: leave, child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              final existing = widget.existing
                  .map((w) => w.toLowerCase())
                  .toSet();
              final entries = uniqueWords(
                widget.batch
                    ? const LineSplitter().convert(text.text)
                    : [text.text],
              ).where((w) => !existing.contains(w.toLowerCase())).toList();
              if (entries.isEmpty) {
                setState(() => invalid = true);
                return;
              }
              close(entries);
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}
