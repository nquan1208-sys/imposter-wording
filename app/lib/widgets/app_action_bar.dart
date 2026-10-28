import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/theme/app_effects.dart';
import 'package:untitled/constants/app_radii.dart';

/// Scaffold footer: owns the keyboard inset and bottom safe area.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        boxShadow: AppEffects.footerShadow,
      ),
      child: Material(
        color: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppContent(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: MediaQuery.viewInsetsOf(context).bottom > 0 ? 12 : 24,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
