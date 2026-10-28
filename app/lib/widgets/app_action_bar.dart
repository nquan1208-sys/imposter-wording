import 'package:flutter/material.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/widgets/app_content.dart';

/// Scaffold footer: owns the keyboard inset and bottom safe area.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Material(
      color: AppColors.white,
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
  );
}
