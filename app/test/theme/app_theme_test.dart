import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_theme.dart';
import 'package:untitled/theme/app_effects.dart';

void main() {
  test(
    'light theme keeps Bumble palette and bundled Vietnamese typography',
    () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFFFFDB5B));
      expect(AppTheme.light.colorScheme.onSurface, AppColors.charcoal);
      expect(AppTheme.light.textTheme.bodyMedium!.fontFamily, 'BeVietnamPro');
      expect(
        AppTheme.light.textTheme.headlineLarge!.fontWeight,
        FontWeight.w600,
      );
    },
  );

  test('functional text pairs meet AA contrast', () {
    double contrast(Color foreground, Color background) {
      final a = foreground.computeLuminance();
      final b = background.computeLuminance();
      return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
    }

    for (final (foreground, background) in [
      (AppColors.charcoal, AppColors.yellow),
      (AppColors.charcoal, AppColors.amber),
      (AppColors.gray, AppColors.white),
      (AppColors.gray, AppColors.background),
      (AppColors.gray, AppColors.lightGray),
      (AppColors.teal, AppColors.tealSurface),
      (AppColors.error, AppColors.white),
      (AppColors.error, AppColors.errorSurface),
      (AppColors.gray, AppColors.tealSurface),
      for (final color in AppEffects.heroGradient.colors) ...[
        (AppColors.charcoal, color),
      ],
      for (final color in AppEffects.accentGradient.colors) ...[
        (AppColors.charcoal, color),
        (AppColors.teal, color),
      ],
    ]) {
      expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
    }
  });

  test('dark theme mirrors light until a dark palette exists', () {
    expect(AppTheme.dark.colorScheme, AppTheme.light.colorScheme);
  });
}
