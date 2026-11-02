import 'package:flutter/material.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/theme/app_effects.dart';

/// Scaffold footer: owns the keyboard inset and bottom safe area.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: AppEffects.footerShadow,
      ),
      child: Material(
        color: AppColors.surface,
        shape: const Border(
          top: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppContent(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppEdgeInsets.pageFor(context).left,
              vertical: MediaQuery.viewInsetsOf(context).bottom > 0 ? 12 : 24,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
