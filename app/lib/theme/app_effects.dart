import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';

class AppEffects {
  AppEffects._();

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.heroStart, AppColors.heroEnd],
  );
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sectionStart, AppColors.sectionEnd],
  );
  static const cardShadow = [
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const footerShadow = [
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, -4)),
  ];
  static const quick = Duration(milliseconds: 160);
  static const transition = Duration(milliseconds: 240);

  static Duration duration(BuildContext context, [bool quick = false]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : quick
      ? AppEffects.quick
      : transition;
}
