import 'package:untitled/constants/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_colors.dart';

class AppNotice extends StatelessWidget {
  const AppNotice({
    super.key,
    required this.message,
    this.error = false,
    this.onRetry,
  });

  final String message;
  final bool error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Semantics(
      liveRegion: error,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: error ? AppColors.errorSurface : AppColors.tealSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: error ? AppColors.error : AppColors.tealBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                error ? Icons.error_outline : Icons.info_outline,
                color: error ? AppColors.error : AppColors.teal,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
