import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/local_image_store.dart';
import 'package:untitled/features/word_game/local_prompt_image.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class ImageAttachment extends ConsumerStatefulWidget {
  final String? imageId;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool> onBusy;
  const ImageAttachment({
    super.key,
    required this.imageId,
    required this.onChanged,
    required this.onBusy,
  });
  @override
  ConsumerState<ImageAttachment> createState() => _ImageAttachmentState();
}

class _ImageAttachmentState extends ConsumerState<ImageAttachment> {
  late final LocalImageStore images;
  final owner = Object();
  bool busy = false;
  String? errorMessage;
  @override
  void didUpdateWidget(covariant ImageAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    images.retain(owner, {?widget.imageId});
  }

  @override
  void initState() {
    super.initState();
    images = ref.read(localImageStoreProvider);
  }

  @override
  void dispose() {
    images.release(owner);
    super.dispose();
  }

  Future<void> pick() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l.imageLibrary),
                leading: const Icon(Icons.photo_library_outlined),
                onTap: () => Navigator.pop(context, 'library'),
              ),
              ListTile(
                title: Text(l.imageCamera),
                leading: const Icon(Icons.camera_alt_outlined),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (widget.imageId != null)
                ListTile(
                  title: Text(
                    l.removeLocalImage,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              ListTile(
                title: Text(l.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'remove') {
      setState(() => errorMessage = null);
      widget.onChanged(null);
      images.retain(owner, {});
      images.cleanup();
      return;
    }
    setState(() {
      busy = true;
      errorMessage = null;
    });
    widget.onBusy(true);
    try {
      final picked = await ref
          .read(imagePickerProvider)
          .pickImage(
            source: choice == 'camera'
                ? ImageSource.camera
                : ImageSource.gallery,
            requestFullMetadata: false,
          );
      if (!mounted || picked == null) return;
      final id = await images.import(File(picked.path), owner);
      if (!mounted) {
        images.release(owner);
        return;
      }
      widget.onChanged(id);
      images.retain(owner, {id});
      images.cleanup();
    } catch (error) {
      if (!mounted) return;
      final message = error is LocalImageException
          ? (error.oversized ? l.localImageOversized : l.localImageInvalid)
          : error is PlatformException
          ? (error.code.toLowerCase().contains('access') ||
                    error.code.toLowerCase().contains('permission')
                ? l.localImagePermission
                : error.code.contains('camera')
                ? l.localImageCameraUnavailable
                : l.localImageInvalid)
          : error is FileSystemException
          ? l.localImageDiskError
          : l.localImageInvalid;
      setState(() => errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        widget.onBusy(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        if (errorMessage != null)
          AppNotice(message: errorMessage!, error: true),
        if (widget.imageId != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: LocalPromptImage(
              widget.imageId!,
              label: l.localImagePreview,
            ),
          ),
        if (busy) const LinearProgressIndicator(),
        TextButton.icon(
          onPressed: busy ? null : pick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            widget.imageId == null ? l.addLocalImage : l.replaceLocalImage,
          ),
        ),
      ],
    );
  }
}
