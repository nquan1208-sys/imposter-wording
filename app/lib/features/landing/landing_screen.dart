import 'package:untitled/widgets/app_hero_card.dart';
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
          padding: AppEdgeInsets.pageFor(context),
          children: [
            AppHeroCard(
              title: l10n.appTitle,
              subtitle: l10n.tagline,
              icon: Icons.theater_comedy_outlined,
              prominent: true,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.appDescription,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: Column(
                children: [
                  for (final (index, (icon, label)) in [
                    (Icons.visibility_outlined, l10n.stepRevealTitle),
                    (Icons.forum_outlined, l10n.stepHintTitle),
                    (Icons.person_search_outlined, l10n.stepFindTitle),
                  ].indexed)
                    ListTile(
                      leading: ExcludeSemantics(
                        child: CircleAvatar(
                          backgroundColor: AppColors.selection,
                          foregroundColor: AppColors.accentText,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      title: Text(label),
                      trailing: ExcludeSemantics(child: Icon(icon)),
                    ),
                ],
              ),
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
