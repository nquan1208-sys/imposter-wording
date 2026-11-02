import 'package:flutter/material.dart';
import 'package:untitled/constants/app_radii.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';

/// A shared introduction for hand-off and onboarding screens.
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.child,
    this.prominent = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? child;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: AppEffects.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.hero),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: prominent
                ? AppEffects.heroGradient
                : AppEffects.accentGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ExcludeSemantics(
                    child: Icon(icon, size: 32, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: prominent ? text.headlineLarge : text.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle!, style: text.bodyLarge),
                ],
                if (child != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  child!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
