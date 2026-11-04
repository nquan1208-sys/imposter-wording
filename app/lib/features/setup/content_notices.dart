import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class ContentNotices extends StatelessWidget {
  final ContentRepository content;
  const ContentNotices(this.content, {super.key});
  @override
  Widget build(BuildContext context) => SignalBuilder(
    builder: (context) {
      final l = AppLocalizations.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (content.loading.value) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            AppNotice(message: l.loadingContent),
          ],
          if (content.cached.value) AppNotice(message: l.cachedContent),
          if (content.loadFailed.value)
            AppNotice(
              message: l.contentError,
              error: true,
              onRetry: content.loading.value ? null : content.load,
            ),
          if (content.cacheWarning.value) AppNotice(message: l.cacheWarning),
        ],
      );
    },
  );
}
