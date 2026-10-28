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
              padding: AppEdgeInsets.all24,
              children: [
                Text(l.contentLanguageHelp),
                if (store.reading.value) const LinearProgressIndicator(),
                if (store.readFailed.value) ...[
                  Text(l.settingsReadError),
                  TextButton(
                    onPressed: store.reading.value ? null : store.restore,
                    child: Text(l.retry),
                  ),
                ],
                if (store.writing.value || languages?.loading.value == true)
                  const LinearProgressIndicator(),
                if (languages?.cached.value == true) Text(l.cachedLanguages),
                if (languages?.cacheWarning.value == true) Text(l.cacheWarning),
                if (languages?.loadFailed.value == true)
                  Text(l.languageListError),
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
                  Text(l.settingsWriteError),
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
                  Semantics(
                    selected: language.code == locale,
                    button: true,
                    child: Card(
                      child: ListTile(
                        selected: language.code == locale,
                        leading: Icon(
                          language.code == locale
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(language.displayName),
                        subtitle: Text(language.code),
                        trailing: language.code == locale
                            ? const Icon(Icons.check)
                            : null,
                        onTap: enabled
                            ? () => store.setContentLocale(language.code)
                            : null,
                      ),
                    ),
                  ),
                ContentNotices(content),
                if (content.snapshot.value != null &&
                    content.snapshot.value!.words.isEmpty &&
                    content.snapshot.value!.questions.isEmpty)
                  Text(l.emptyContent),
                if (store.selectionRemoved.value) Text(l.selectionRemoved),
              ],
            ),
          ),
        );
      },
    );
  }
}
