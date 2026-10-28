import 'package:untitled/widgets/app_action_bar.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/data/local_image_store.dart';
import 'package:untitled/features/custom_content/image_attachment.dart';
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
          scrollable: true,
          insetPadding: const EdgeInsets.all(16),
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
  final scroll = ScrollController();
  final words = <String>[];
  final imageIds = <String, String>{};
  final imageOwner = Object();
  late final LocalImageStore images;
  late final String contentLocale;
  void retainImages() => images.retain(imageOwner, {
    ...imageIds.values,
    for (final p in pairs)
      if (p.imageId != null) p.imageId!,
  });
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
  void initState() {
    super.initState();
    images = ref.read(localImageStoreProvider);
    contentLocale = ref.read(setupStoreProvider).setup.value.contentLocale;
  }

  @override
  void dispose() {
    images.release(imageOwner);
    name.dispose();
    scroll.dispose();
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
        builder: (_) => _QuestionEntryDialog(
          batch: batch,
          existing: pairs,
          onImage: (id) {
            images.retain(imageOwner, {
              ...imageIds.values,
              for (final p in pairs)
                if (p.imageId != null) p.imageId!,
              ?id,
            });
          },
        ),
      );
      if (mounted && entries != null) setState(() => pairs.addAll(entries));
      return;
    }
    final entries = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WordEntryDialog(
        batch: batch,
        existing: words,
        onImage: (word, id) {
          if (id != null) imageIds[word] = id;
          retainImages();
        },
      ),
    );
    if (mounted && entries != null) setState(() => words.addAll(entries));
  }

  Future<void> save() async {
    final store = ref.read(setupStoreProvider);
    if (busy ||
        !store.editable ||
        !hasEntries ||
        !store.validCustomCategoryName(
          name.text,
          gameType: widget.gameType,
          contentLocale: contentLocale,
        ) ||
        (needsFamily && !suitable)) {
      setState(() {});
      return;
    }
    setState(() {
      busy = true;
      failed = false;
    });
    final id = question
        ? await store.createCustomQuestionCategory(
            name.text,
            pairs,
            contentLocale: contentLocale,
          )
        : await store.createCustomWordCategory(
            name.text,
            words,
            family: widget.family && suitable,
            imageIds: imageIds,
            contentLocale: contentLocale,
          );
    if (!mounted) return;
    if (id != null) {
      close(id);
    } else {
      setState(() {
        busy = false;
        failed = true;
      });
      scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final validName = ref
        .read(setupStoreProvider)
        .validCustomCategoryName(
          name.text,
          gameType: widget.gameType,
          contentLocale: contentLocale,
        );
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
        bottomNavigationBar: AppActionBar(
          child: FilledButton(
            onPressed:
                !busy && validName && hasEntries && (!needsFamily || suitable)
                ? save
                : null,
            child: Text(busy ? l.customSaving : l.saveCustomCategory),
          ),
        ),
        body: AppContent(
          child: AbsorbPointer(
            absorbing: busy,
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(24),
              children: [
                if (busy) const LinearProgressIndicator(),
                if (failed)
                  AppNotice(
                    message: question
                        ? l.customQuestionSaveError
                        : l.customSaveError,
                    error: true,
                  ),
                TextField(
                  enabled: !busy,
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
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  question ? l.customQuestionList : l.customWordList,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  question
                      ? l.questionCount(pairs.length)
                      : l.wordCount(words.length),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!hasEntries)
                  AppNotice(
                    message: question
                        ? l.customQuestionsEmpty
                        : l.customWordsEmpty,
                  ),
                if (question)
                  for (var i = 0; i < pairs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.lg),
                          title: Text(
                            '${l.customCivilianQuestion}: ${pairs[i].civilianQuestion}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '${l.customImposterQuestion}: ${pairs[i].imposterQuestion}',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ImageAttachment(
                                key: ValueKey(i),
                                imageId: pairs[i].imageId,
                                onBusy: (value) => setState(() => busy = value),
                                onChanged: (id) => setState(() {
                                  final p = pairs[i];
                                  pairs[i] = CustomQuestionEntry(
                                    p.civilianQuestion,
                                    p.imposterQuestion,
                                    imageId: id,
                                  );
                                  retainImages();
                                  images.cleanup();
                                }),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: l.removeCustomQuestion(i + 1),
                            onPressed: () => setState(() {
                              pairs.removeAt(i);
                              retainImages();
                              images.cleanup();
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                if (!question)
                  for (var i = 0; i < words.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.lg),
                          title: Text(words[i]),
                          subtitle: ImageAttachment(
                            key: ValueKey(words[i]),
                            imageId: imageIds[words[i]],
                            onBusy: (value) => setState(() => busy = value),
                            onChanged: (id) => setState(() {
                              if (id == null) {
                                imageIds.remove(words[i]);
                              } else {
                                imageIds[words[i]] = id;
                              }
                              retainImages();
                              images.cleanup();
                            }),
                          ),
                          trailing: IconButton(
                            tooltip: l.removeCustomWord(words[i]),
                            onPressed: () => setState(() {
                              imageIds.remove(words.removeAt(i));
                              retainImages();
                              images.cleanup();
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
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
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: Card(
                      child: CheckboxListTile(
                        title: Text(l.customFamilyConfirmation),
                        value: suitable,
                        onChanged: (value) =>
                            setState(() => suitable = value == true),
                      ),
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
  final void Function(String, String?) onImage;
  const _WordEntryDialog({
    required this.batch,
    required this.existing,
    required this.onImage,
  });

  @override
  State<_WordEntryDialog> createState() => _WordEntryDialogState();
}

class _WordEntryDialogState extends State<_WordEntryDialog> {
  final text = TextEditingController();
  String? imageId;
  bool busy = false;
  bool invalid = false, exiting = false, asking = false;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (busy || asking || exiting) return;
    asking = true;
    final discard =
        (text.text.isEmpty && imageId == null) || await _discard(context);
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
        insetPadding: const EdgeInsets.all(16),
        title: Text(widget.batch ? l.importCustomWords : l.addCustomWord),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              enabled: !busy,
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
            if (!widget.batch)
              ImageAttachment(
                imageId: imageId,
                onChanged: (id) => setState(() => imageId = id),
                onBusy: (value) => setState(() => busy = value),
              ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: busy ? null : leave,
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          final existing = widget.existing
                              .map((w) => w.toLowerCase())
                              .toSet();
                          final entries =
                              uniqueWords(
                                    widget.batch
                                        ? const LineSplitter().convert(
                                            text.text,
                                          )
                                        : [text.text],
                                  )
                                  .where(
                                    (w) => !existing.contains(w.toLowerCase()),
                                  )
                                  .toList();
                          if (entries.isEmpty) {
                            setState(() => invalid = true);
                            return;
                          }
                          if (!widget.batch) {
                            widget.onImage(entries.single, imageId);
                          }
                          close(entries);
                        },
                  child: Text(l.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionEntryDialog extends StatefulWidget {
  final bool batch;
  final List<CustomQuestionEntry> existing;
  final ValueChanged<String?> onImage;
  const _QuestionEntryDialog({
    required this.batch,
    required this.existing,
    required this.onImage,
  });
  @override
  State<_QuestionEntryDialog> createState() => _QuestionEntryDialogState();
}

class _QuestionEntryDialogState extends State<_QuestionEntryDialog> {
  final civilian = TextEditingController(), imposter = TextEditingController();
  QuestionImportException? error;
  String? imageId;
  bool busy = false;
  bool exiting = false, asking = false;
  @override
  void dispose() {
    civilian.dispose();
    imposter.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (busy || asking || exiting) return;
    asking = true;
    final discard =
        (civilian.text.isEmpty && imposter.text.isEmpty && imageId == null) ||
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
        insetPadding: const EdgeInsets.all(16),
        scrollable: true,
        title: Text(
          widget.batch ? l.importCustomQuestions : l.addCustomQuestion,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.batch) AppNotice(message: l.customQuestionLineHelp),
            for (final field in [
              (civilian, l.customCivilianQuestion),
              (imposter, l.customImposterQuestion),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  enabled: !busy,
                  controller: field.$1,
                  autofocus: field.$1 == civilian,
                  minLines: widget.batch ? 3 : 1,
                  maxLines: widget.batch ? 6 : 3,
                  decoration: InputDecoration(labelText: field.$2),
                  onChanged: (_) => setState(() => error = null),
                ),
              ),
            if (!widget.batch)
              ImageAttachment(
                imageId: imageId,
                onChanged: (id) => setState(() => imageId = id),
                onBusy: (value) => setState(() => busy = value),
              ),
            if (error != null)
              AppNotice(
                error: true,
                message: error!.unequalCounts
                    ? l.customQuestionCountError(error!.rows.join(', '))
                    : l.customQuestionRowsError(error!.rows.join(', ')),
              ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: busy ? null : leave,
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          try {
                            final entries = parseQuestionPairs(
                              civilian.text,
                              imposter.text,
                              batch: widget.batch,
                              existing: widget.existing,
                            );
                            if (!widget.batch) {
                              widget.onImage(imageId);
                              final p = entries.single;
                              close([
                                CustomQuestionEntry(
                                  p.civilianQuestion,
                                  p.imposterQuestion,
                                  imageId: imageId,
                                ),
                              ]);
                            } else {
                              close(entries);
                            }
                          } on QuestionImportException catch (e) {
                            setState(() => error = e);
                          }
                        },
                  child: Text(l.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
