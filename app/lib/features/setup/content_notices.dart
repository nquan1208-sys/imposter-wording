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
            Text(l.loadingContent),
          ],
          if (content.cached.value) Text(l.cachedContent),
          if (content.loadFailed.value) ...[
            Text(l.contentError),
            TextButton(
              onPressed: content.loading.value ? null : content.load,
              child: Text(l.retry),
            ),
          ],
          if (content.cacheWarning.value) Text(l.cacheWarning),
        ],
      );
    },
  );
}
