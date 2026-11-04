import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _minimumTimer;
  bool _minimumElapsed = false, _loaded = false, _failed = false;
  bool _loading = true, _leaving = false;

  @override
  void initState() {
    super.initState();
    _minimumTimer = Timer(const Duration(milliseconds: 300), () {
      _minimumElapsed = true;
      _finish();
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loaded = false;
      _failed = false;
    });
    try {
      final app = ref.read(StoreProvider.app);
      final setup = ref.read(setupStoreProvider);
      await Future.wait([app.restore(), setup.restore()]);
      if (!mounted) return;
      final content = setup.content;
      final languages = setup.languages;
      await Future.wait([
        if (content.snapshot.value == null || content.loading.value)
          content.load(),
        if (languages != null &&
            (languages.languages.value == null || languages.loading.value))
          languages.load(),
      ]);
      if (!mounted) return;
      _failed =
          app.readFailed.value ||
          setup.readFailed.value ||
          content.snapshot.value == null ||
          (languages != null && languages.languages.value == null);
    } catch (_) {
      if (!mounted) return;
      _failed = true;
    }
    _loaded = true;
    _finish();
  }

  void _finish() {
    if (!mounted || !_loaded || !_minimumElapsed || _leaving) return;
    if (_failed) {
      setState(() => _loading = false);
    } else {
      _openHome();
    }
  }

  void _openHome() {
    _leaving = true;
    unawaited(
      ref.read(AppService.router).pushReplacement(RouteInput.landing()),
    );
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/oddcue-icon.png',
                  width: 160,
                  height: 160,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_loading)
                  CircularProgressIndicator(semanticsLabel: l.loadingContent)
                else ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(l.startupError, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(onPressed: _load, child: Text(l.retry)),
                  TextButton(onPressed: _openHome, child: Text(l.backToHome)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
