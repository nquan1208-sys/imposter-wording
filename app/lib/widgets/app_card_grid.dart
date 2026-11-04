import 'package:flutter/material.dart';
import 'package:untitled/constants/app_spacing.dart';

/// Large text gets one column; callers can give every row a uniform height.
class AppCardGrid extends StatelessWidget {
  const AppCardGrid({super.key, required this.children, this.itemHeight});

  final List<Widget> children;
  final double? itemHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(16) > 24
          ? 1
          : 2;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: SizedBox(
                height: itemHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: start + column < children.length
                            ? children[start + column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
