import 'dart:convert';
import 'package:untitled/models/custom_question_category.dart';
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
  final String gameType;
  const CustomWordScreen({
    super.key,
    required this.family,
    this.gameType = 'word',
  });

  @override
  ConsumerState<CustomWordScreen> createState() => _CustomWordScreenState();
}

class _CustomWordScreenState extends ConsumerState<CustomWordScreen> {
  final name = TextEditingController();
  final words = <String>[];
  final pairs = <CustomQuestionEntry>[];
  bool get question => widget.gameType == 'question';
  bool get needsFamily => !question && widget.family;
  bool get hasEntries => question ? pairs.isNotEmpty : words.isNotEmpty;
  bool suitable = false,
      busy = false,
      failed = false,
      exiting = false,
      asking = false;
  bool get dirty => name.text.isNotEmpty || hasEntries || suitable;

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
    if (question) {
      final entries = await showDialog<List<CustomQuestionEntry>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _QuestionEntryDialog(batch: batch, existing: pairs),
      );
      if (mounted && entries != null) setState(() => pairs.addAll(entries));
      return;
    }
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
        !hasEntries ||
        !store.validCustomCategoryName(name.text, gameType: widget.gameType) ||
        (needsFamily && !suitable)) {
      setState(() {});
      return;
    }
    setState(() {
      busy = true;
      failed = false;
    });
    final id = question
        ? await store.createCustomQuestionCategory(name.text, pairs)
        : await store.createCustomWordCategory(
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
        .validCustomCategoryName(name.text, gameType: widget.gameType);
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
                        hasEntries &&
                        (!needsFamily || suitable)
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
                  question ? l.customQuestionList : l.customWordList,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  question
                      ? l.questionCount(pairs.length)
                      : l.wordCount(words.length),
                ),
                if (!hasEntries)
                  Text(question ? l.customQuestionsEmpty : l.customWordsEmpty),
                if (question)
                  for (var i = 0; i < pairs.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${l.customCivilianQuestion}: ${pairs[i].civilianQuestion}',
                      ),
                      subtitle: Text(
                        '${l.customImposterQuestion}: ${pairs[i].imposterQuestion}',
                      ),
                      trailing: IconButton(
                        tooltip: l.removeCustomQuestion(i + 1),
                        onPressed: () => setState(() => pairs.removeAt(i)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                if (!question)
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
                      child: Text(
                        question ? l.addCustomQuestion : l.addCustomWord,
                      ),
                    ),
                    TextButton(
                      onPressed: () => addWords(true),
                      child: Text(
                        question
                            ? l.importCustomQuestions
                            : l.importCustomWords,
                      ),
                    ),
                  ],
                ),
                if (needsFamily)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.customFamilyConfirmation),
                    value: suitable,
                    onChanged: (value) =>
                        setState(() => suitable = value == true),
                  ),
                if (failed)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      question ? l.customQuestionSaveError : l.customSaveError,
                    ),
                  ),
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

class _QuestionEntryDialog extends StatefulWidget {
  final bool batch;
  final List<CustomQuestionEntry> existing;
  const _QuestionEntryDialog({required this.batch, required this.existing});
  @override
  State<_QuestionEntryDialog> createState() => _QuestionEntryDialogState();
}

class _QuestionEntryDialogState extends State<_QuestionEntryDialog> {
  final civilian = TextEditingController(), imposter = TextEditingController();
  QuestionImportException? error;
  bool exiting = false, asking = false;
  @override
  void dispose() {
    civilian.dispose();
    imposter.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (asking || exiting) return;
    asking = true;
    final discard =
        (civilian.text.isEmpty && imposter.text.isEmpty) ||
        await _discard(context);
    asking = false;
    if (mounted && discard) close();
  }

  void close([List<CustomQuestionEntry>? entries]) {
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
        scrollable: true,
        title: Text(
          widget.batch ? l.importCustomQuestions : l.addCustomQuestion,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.batch) Text(l.customQuestionLineHelp),
            for (final field in [
              (civilian, l.customCivilianQuestion),
              (imposter, l.customImposterQuestion),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: field.$1,
                  autofocus: field.$1 == civilian,
                  minLines: widget.batch ? 3 : 1,
                  maxLines: widget.batch ? 6 : 3,
                  decoration: InputDecoration(labelText: field.$2),
                  onChanged: (_) => setState(() => error = null),
                ),
              ),
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!.unequalCounts
                      ? l.customQuestionCountError(error!.rows.join(', '))
                      : l.customQuestionRowsError(error!.rows.join(', ')),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: leave, child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              try {
                close(
                  parseQuestionPairs(
                    civilian.text,
                    imposter.text,
                    batch: widget.batch,
                    existing: widget.existing,
                  ),
                );
              } on QuestionImportException catch (e) {
                setState(() => error = e);
              }
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}
