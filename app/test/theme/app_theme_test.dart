import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_theme.dart';

void main() {
  test('light theme uses Bumble yellow as primary', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.yellow);
    expect(AppTheme.light.colorScheme.onSurface, AppColors.charcoal);
  });

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
    ]) {
      expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
    }
  });

  test('dark theme mirrors light until a dark palette exists', () {
    expect(AppTheme.dark.colorScheme, AppTheme.light.colorScheme);
  });
}
