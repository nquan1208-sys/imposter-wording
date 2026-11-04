import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_theme.dart';
import 'package:untitled/theme/app_effects.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
}

void main() {
  test('dark party palette uses bundled Vietnamese typography', () {
    final theme = AppTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0C0D14));
    expect(theme.colorScheme.primary, const Color(0xFFC7FF5B));
    expect(theme.colorScheme.onSurface, AppColors.white);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'BeVietnamPro');
    expect(theme.textTheme.headlineLarge!.fontWeight, FontWeight.w600);
  });

  test('functional text pairs meet AA on dark and composed surfaces', () {
    for (final (foreground, background) in [
      (AppColors.onPrimary, AppColors.primary),
      (AppColors.onPrimary, AppColors.primaryPressed),
      (AppColors.onError, AppColors.error),
      (AppColors.error, AppColors.errorSurface),
      (AppColors.warning, AppColors.warningSurface),
      (AppColors.success, AppColors.successSurface),
      (AppColors.disabledText, AppColors.disabledSurface),
      for (final surface in [
        AppColors.canvas,
        AppColors.surface,
        AppColors.surfaceRaised,
        AppColors.selection,
        AppColors.errorSurface,
        Color.alphaBlend(AppColors.secondaryAction, AppColors.surface),
        Color.alphaBlend(AppColors.secondaryAction, AppColors.canvas),
        for (final gradient in [
          AppEffects.heroGradient,
          AppEffects.accentGradient,
        ])
          for (var step = 0; step <= 10; step++)
            Color.lerp(gradient.colors.first, gradient.colors.last, step / 10)!,
      ]) ...[
        (AppColors.textPrimary, surface),
        (AppColors.textBody, surface),
        (AppColors.textMuted, surface),
      ],
      (AppColors.accentText, AppColors.surface),
      (AppColors.accentText, AppColors.selection),
    ]) {
      expect(
        contrast(foreground, background),
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on $background',
      );
    }
  });

  test('control boundaries and focus are visible', () {
    for (final surface in [
      AppColors.canvas,
      AppColors.surface,
      AppColors.surfaceRaised,
      AppColors.selection,
    ]) {
      expect(contrast(AppColors.focus, surface), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.border, surface), greaterThanOrEqualTo(3));
    }
    final style = AppTheme.dark.filledButtonTheme.style!;
    expect(style.backgroundBuilder, isNull);
    expect(style.backgroundColor!.resolve({}), AppColors.primary);
    expect(
      style.backgroundColor!.resolve({WidgetState.pressed}),
      AppColors.primaryPressed,
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.disabled}),
      AppColors.disabledSurface,
    );
    expect(
      style.foregroundColor!.resolve({WidgetState.disabled}),
      AppColors.disabledText,
    );
    expect(style.side!.resolve({WidgetState.focused})!.width, 2);
    expect(
      contrast(
        style.side!.resolve({WidgetState.focused})!.color,
        AppColors.primary,
      ),
      greaterThanOrEqualTo(3),
    );
    final outlined = AppTheme.dark.outlinedButtonTheme.style!;
    expect(outlined.side!.resolve({})!.width, 1);
    expect(outlined.side!.resolve({WidgetState.focused})!.width, 2);
    expect(
      AppTheme.dark.switchTheme.trackColor!.resolve({
        WidgetState.selected,
        WidgetState.disabled,
      }),
      AppColors.disabledSurface,
    );
    expect(style.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(50));
    expect(
      AppTheme.dark.iconButtonTheme.style!.minimumSize!.resolve({}),
      const Size(48, 48),
    );
  });
}
