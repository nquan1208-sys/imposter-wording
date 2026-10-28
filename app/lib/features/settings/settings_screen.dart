import 'package:untitled/widgets/app_notice.dart';
import 'package:untitled/features/settings/content_language_tile.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/widgets/app_content.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  void initState() {
    super.initState();
    unawaited(_prepareSettings());
  }

  Future<void> _prepareSettings() async {
    final store = ref.read(StoreProvider.app);
    await store.restore();
    if (mounted && !store.readFailed.value) await store.ensureInstallationId();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(StoreProvider.app);
    final router = ref.watch(AppService.router);
    return SignalBuilder(
      builder: (context) {
        final l = AppLocalizations.of(context);
        final ready =
            store.ready &&
            !store.loading.value &&
            !store.readFailed.value &&
            !store.writing.value;
        final installationId = store.installationId.value;
        return Scaffold(
          appBar: AppBar(title: Text(l.settingsTitle), centerTitle: false),
          body: AppContent(
            child: ListView(
              padding: AppEdgeInsets.all24,
              children: [
                if (store.loading.value) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(l.appSettingsLoading),
                ],
                if (store.readFailed.value) ...[
                  AppNotice(message: l.appSettingsReadError, error: true),
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
                  AppNotice(message: l.appSettingsWriteError, error: true),
                  TextButton(
                    onPressed: store.writing.value ? null : store.retryWrite,
                    child: Text(l.retry),
                  ),
                ],
                Text(
                  l.generalOptions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Column(
                    children: [
                      const ContentLanguageTile(),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: Text(l.howToPlay),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => router.push(RouteInput.howToPlay()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l.rateAndFeedback,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Column(
                    children: [
                      _UnavailableAction(
                        icon: Icons.star_outline,
                        title: l.rateApp,
                        message: l.supportUnavailable,
                      ),
                      const Divider(height: 1),
                      _UnavailableAction(
                        icon: Icons.feedback_outlined,
                        title: l.sendFeedback,
                        message: l.supportUnavailable,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l.appInformation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Column(
                    children: [
                      FutureBuilder<PackageInfo>(
                        future: _packageInfo,
                        builder: (context, snapshot) => ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l.appVersion),
                          subtitle: Text(
                            snapshot.hasData
                                ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                                : snapshot.hasError
                                ? l.appInfoUnavailable
                                : l.appSettingsLoading,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.fingerprint),
                        title: Text(l.installationId),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              installationId == null
                                  ? l.appSettingsLoading
                                  : '${installationId.substring(0, 8)}…',
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(l.installationIdPrivacy),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: l.copyFullId,
                          onPressed:
                              ready &&
                                  !store.writeFailed.value &&
                                  installationId != null
                              ? () => _copyInstallationId(installationId)
                              : null,
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyInstallationId(String id) async {
    try {
      await Clipboard.setData(ClipboardData(text: id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).installationIdCopied),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).installationIdCopyFailed,
            ),
          ),
        );
      }
    }
  }
}

class _UnavailableAction extends StatelessWidget {
  const _UnavailableAction({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: false,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(message),
  );
}
