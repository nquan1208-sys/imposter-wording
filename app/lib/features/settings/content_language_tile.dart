import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class ContentLanguageTile extends ConsumerWidget {
  const ContentLanguageTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(setupStoreProvider);
    return SignalBuilder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        final code = store.setup.value.contentLocale;
        final languages = store.languages;
        return ListTile(
          leading: const Icon(Icons.translate),
          title: Text(l.contentLanguage),
          subtitle: Text(
            [
              '${languages?.name(code) ?? code} ($code)',
              if (languages?.languages.value != null && !store.localeAvailable)
                l.contentLanguageUnavailable,
            ].join('\n'),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: store.editable && !store.sessionActive.value
              ? () => ref
                    .read(AppService.router)
                    .push(RouteInput.contentLanguage())
              : null,
        );
      },
    );
  }
}
