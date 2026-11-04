import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class LocalPromptImage extends ConsumerStatefulWidget {
  final String imageId, label;
  const LocalPromptImage(this.imageId, {super.key, required this.label});
  @override
  ConsumerState<LocalPromptImage> createState() => _LocalPromptImageState();
}

class _LocalPromptImageState extends ConsumerState<LocalPromptImage> {
  late Future<File> file;
  @override
  void initState() {
    super.initState();
    resolve();
  }

  void resolve() {
    file = ref.read(localImageStoreProvider).file(widget.imageId);
  }

  @override
  void didUpdateWidget(covariant LocalPromptImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) resolve();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget placeholder() => Semantics(
      label: l.localImageUnavailable,
      child: const ExcludeSemantics(
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        clipBehavior: Clip.antiAlias,
        height: 180,
        width: double.infinity,
        child: FutureBuilder<File>(
          future: file,
          builder: (context, snapshot) => snapshot.hasData
              ? Image.file(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  cacheWidth: 512,
                  semanticLabel: widget.label,
                  frameBuilder: (_, child, frame, _) =>
                      frame == null ? placeholder() : child,
                  errorBuilder: (_, _, _) => placeholder(),
                )
              : placeholder(),
        ),
      ),
    );
  }
}
