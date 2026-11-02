import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/widgets/app_selection_card.dart';
import 'package:untitled/widgets/app_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/content_notices.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class ContentLanguageScreen extends ConsumerWidget {
  const ContentLanguageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(setupStoreProvider);
    final languages = store.languages;
    return SignalBuilder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        final locale = store.setup.value.contentLocale;
        final content = store.content;
        final enabled = store.editable && !store.sessionActive.value;
        return Scaffold(
          appBar: AppBar(title: Text(l.contentLanguage)),
          body: AppContent(
            child: ListView(
              padding: AppEdgeInsets.pageFor(context),
              children: [
                AppNotice(message: l.contentLanguageHelp),
                const SizedBox(height: AppSpacing.lg),
                if (store.reading.value) const LinearProgressIndicator(),
                if (store.readFailed.value) ...[
                  AppNotice(message: l.settingsReadError, error: true),
                  TextButton(
                    onPressed: store.reading.value ? null : store.restore,
                    child: Text(l.retry),
                  ),
                ],
                if (store.writing.value || languages?.loading.value == true)
                  const LinearProgressIndicator(),
                if (languages?.cached.value == true)
                  AppNotice(message: l.cachedLanguages),
                if (languages?.cacheWarning.value == true)
                  AppNotice(message: l.cacheWarning),
                if (languages?.loadFailed.value == true)
                  AppNotice(message: l.languageListError, error: true),
                TextButton(
                  onPressed: languages?.loading.value == true
                      ? null
                      : languages?.load,
                  child: Text(
                    languages?.loadFailed.value == true
                        ? l.retry
                        : l.refreshContent,
                  ),
                ),
                if (store.writeFailed.value) ...[
                  AppNotice(message: l.settingsWriteError, error: true),
                  TextButton(
                    onPressed: enabled ? store.save : null,
                    child: Text(l.retry),
                  ),
                ],
                if (languages?.languages.value != null &&
                    !store.localeAvailable)
                  Text('${l.contentLanguageUnavailable} ($locale)'),
                for (final language in (languages?.languages.value ?? []).where(
                  (language) => store.supportsLocale(language.code),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppSelectionCard(
                      selected: language.code == locale,
                      onTap: enabled
                          ? () => store.setContentLocale(language.code)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              language.code == locale
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language.displayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  language.code,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ContentNotices(content),
                if (content.snapshot.value != null &&
                    content.snapshot.value!.words.isEmpty &&
                    content.snapshot.value!.questions.isEmpty)
                  AppNotice(message: l.emptyContent),
                if (store.selectionRemoved.value)
                  AppNotice(message: l.selectionRemoved),
              ],
            ),
          ),
        );
      },
    );
  }
}
