import 'package:untitled/constants/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/theme/app_effects.dart';

class AppSelectionCard extends StatefulWidget {
  const AppSelectionCard({
    super.key,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AppSelectionCard> createState() => _AppSelectionCardState();
}

class _AppSelectionCardState extends State<AppSelectionCard> {
  bool focused = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      selected: widget.selected,
      button: true,
      enabled: widget.onTap != null,
      child: AnimatedScale(
        scale: pressed ? .98 : 1,
        duration: AppEffects.duration(context, true),
        curve: Curves.easeOutCubic,
        child: Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(
              color: focused
                  ? AppColors.focus
                  : widget.selected
                  ? AppColors.accentText
                  : AppColors.border,
              width: widget.selected || focused ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => focused = value),
            onHighlightChanged: (value) => setState(() => pressed = value),
            child: Ink(
              decoration: BoxDecoration(
                color: widget.selected ? AppColors.selection : null,
              ),
              child: Padding(padding: AppEdgeInsets.all24, child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}
