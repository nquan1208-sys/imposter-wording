import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_colors.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final routerService = ref.watch(AppService.router);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppEdgeInsets.all24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      // ponytail: placeholder art until the illustration asset exists
                      Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Icon(
                          Icons.theater_comedy,
                          size: 96,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        l10n.appTitle,
                        style: textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.tagline,
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.appDescription,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Setup flow ships in phase 2; keep the entry visible but disabled.
              FilledButton(onPressed: null, child: Text(l10n.start)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.startUnavailable,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => routerService.push(RouteInput.howToPlay()),
                child: Text(l10n.howToPlay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
