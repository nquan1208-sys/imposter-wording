import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_theme.dart';

void main() {
  test('light theme uses Bumble yellow as primary', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.yellow);
    expect(AppTheme.light.colorScheme.onSurface, AppColors.charcoal);
  });

  test('dark theme mirrors light until a dark palette exists', () {
    expect(AppTheme.dark.colorScheme, AppTheme.light.colorScheme);
  });
}
