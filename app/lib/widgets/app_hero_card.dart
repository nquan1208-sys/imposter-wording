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
          child: Stack(
            children: [
              Positioned(
                right: -64,
                top: -64,
                child: ExcludeSemantics(
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: prominent ? AppColors.glass : AppColors.cream,
                        width: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(prominent ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: prominent
                                ? AppColors.glass
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(
                              AppRadii.control,
                            ),
                            border: Border.all(color: AppColors.glass),
                          ),
                          child: Icon(
                            icon,
                            size: prominent ? 56 : 32,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      style: prominent ? text.headlineLarge : text.titleLarge,
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
            ],
          ),
        ),
      ),
    );
  }
}
