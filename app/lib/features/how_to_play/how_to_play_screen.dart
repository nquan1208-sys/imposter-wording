import 'package:untitled/widgets/app_content.dart';
import 'package:flutter/material.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_colors.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (Icons.settings_outlined, l10n.stepSetupTitle, l10n.stepSetupBody),
      (Icons.visibility_outlined, l10n.stepRevealTitle, l10n.stepRevealBody),
      (Icons.chat_bubble_outline, l10n.stepHintTitle, l10n.stepHintBody),
      (Icons.search, l10n.stepFindTitle, l10n.stepFindBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.howToPlay)),
      body: AppContent(
        top: false,
        child: ListView(
          padding: AppEdgeInsets.all24,
          children: [
            for (final (index, (icon, title, body)) in steps.indexed) ...[
              Card(
                child: _StepContent(
                  icon: icon,
                  title: title,
                  body: body,
                  number: index + 1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: AppEdgeInsets.all24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.questionGame,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.questionInstructions),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              key: const Key('proTipCard'),
              color: AppColors.tealSurface,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.tealBorder),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: _StepContent(
                icon: Icons.lightbulb_outline,
                title: l10n.proTipTitle,
                body: l10n.proTipBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.icon,
    required this.title,
    required this.body,
    this.number,
  });

  final int? number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: AppEdgeInsets.all24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppEdgeInsets.all8,
            decoration: const BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, color: AppColors.charcoal),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (number != null) ...[
                  Text(
                    number.toString().padLeft(2, '0'),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(title, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
