import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class SettingsLanguageScreen extends ConsumerWidget {
  const SettingsLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(StoreProvider.app);
    return SignalBuilder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        final enabled =
            store.ready &&
            !store.loading.value &&
            !store.readFailed.value &&
            !store.writing.value;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.chooseInterfaceLanguage),
            centerTitle: true,
          ),
          body: AppContent(
            child: ListView(
              padding: AppEdgeInsets.all24,
              children: [
                if (store.loading.value) Text(l.appSettingsLoading),
                if (store.readFailed.value) ...[
                  Text(l.appSettingsReadError),
                  TextButton(
                    onPressed: store.loading.value
                        ? null
                        : () async {
                            await store.retryRead();
                            if (!store.readFailed.value) {
                              await store.ensureInstallationId();
                            }
                          },
                    child: Text(l.retry),
                  ),
                ],
                if (store.writeFailed.value) ...[
                  Text(l.appSettingsWriteError),
                  TextButton(
                    onPressed: store.writing.value ? null : store.retryWrite,
                    child: Text(l.retry),
                  ),
                ],
                for (final locale in AppLocalizations.supportedLocales)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Semantics(
                      selected:
                          locale.languageCode ==
                          store.locale.value.languageCode,
                      button: true,
                      child: Card(
                        child: ListTile(
                          selected:
                              locale.languageCode ==
                              store.locale.value.languageCode,
                          leading: Icon(
                            locale.languageCode ==
                                    store.locale.value.languageCode
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(
                            locale.languageCode == 'vi'
                                ? l.languageVietnamese
                                : l.languageEnglish,
                          ),
                          trailing:
                              locale.languageCode ==
                                  store.locale.value.languageCode
                              ? const Icon(Icons.check)
                              : null,
                          onTap: enabled
                              ? () => unawaited(store.setLocale(locale))
                              : null,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.contentLanguageVietnamese),
              ],
            ),
          ),
        );
      },
    );
  }
}
