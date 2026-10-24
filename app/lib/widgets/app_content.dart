import 'package:flutter/material.dart';

/// Shared readable width and system insets for pages, action bars and sheets.
class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: top,
    bottom: bottom,
    child: Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}
