import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/models/content.dart';

class WordImage extends ConsumerWidget {
  final WordPrompt prompt;
  const WordImage(this.prompt, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = prompt.imagePath;
    if (path == null) return const SizedBox.shrink();
    final cache = ref.watch(contentRepositoryProvider).images;
    final l = AppLocalizations.of(context);
    Widget placeholder() => Semantics(
      label: l.wordImageUnavailable,
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined),
              Text(l.wordImageUnavailable, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
    Widget image() {
      final file = cache?.file(path);
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: file == null
              ? placeholder()
              : Image.file(
                  file,
                  fit: BoxFit.contain,
                  cacheWidth: 512,
                  semanticLabel: l.wordImage(prompt.text),
                  frameBuilder: (_, child, frame, _) =>
                      frame == null ? placeholder() : child,
                  errorBuilder: (_, _, _) => placeholder(),
                ),
        ),
      );
    }

    return cache == null
        ? image()
        : ListenableBuilder(listenable: cache, builder: (_, _) => image());
  }
}
