import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/widgets/app_hero_card.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class UnknownScreen extends ConsumerWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final router = ref.watch(AppService.router);
    return Scaffold(
      appBar: AppBar(),
      body: AppContent(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppEdgeInsets.pageFor(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppHeroCard(
                  title: l.notFound,
                  icon: Icons.explore_off_outlined,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => router.pushAndRemoveUntil(
                    RouteInput.landing(),
                    (_) => false,
                  ),
                  child: Text(l.backToHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
