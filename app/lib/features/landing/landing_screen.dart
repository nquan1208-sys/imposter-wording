import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/widgets/app_action_bar.dart';
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
      body: AppContent(
        bottom: false,
        child: ListView(
          padding: AppEdgeInsets.all24,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(AppRadii.hero),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Icon(Icons.theater_comedy_outlined, size: 80),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(l10n.appTitle, style: textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.tagline, style: textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.appDescription,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => routerService.push(RouteInput.setup()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(l10n.start)),
                  const SizedBox(width: AppSpacing.md),
                  const ExcludeSemantics(
                    child: Icon(Icons.arrow_forward, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => routerService.push(RouteInput.howToPlay()),
              child: Text(l10n.howToPlay),
            ),
          ],
        ),
      ),
    );
  }
}
