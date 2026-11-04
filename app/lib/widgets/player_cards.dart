import 'package:flutter/material.dart';
import 'package:untitled/constants/app_edge_insets.dart';
import 'package:untitled/constants/app_spacing.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/widgets/app_selection_card.dart';

/// Lazy rows keep long player names readable without fixed-height cells.
class PlayerCards extends StatelessWidget {
  const PlayerCards({
    super.key,
    required this.players,
    required this.completed,
    required this.completedLabel,
    required this.onSelected,
  });

  final List<SetupPlayer> players;
  final Set<String> completed;
  final String completedLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.crossAxisExtent -
                      AppEdgeInsets.pageFor(context).horizontal <
                  280 ||
              MediaQuery.textScalerOf(context).scale(16) > 24
          ? 1
          : 2;
      return SliverPadding(
        padding: AppEdgeInsets.pageFor(context).copyWith(top: 0),
        sliver: SliverList.builder(
          itemCount: (players.length / columns).ceil(),
          itemBuilder: (context, row) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: row * columns + column >= players.length
                          ? const SizedBox.shrink()
                          : _card(context, players[row * columns + column]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _card(BuildContext context, SetupPlayer player) {
    final done = completed.contains(player.id);
    return AppSelectionCard(
      key: ValueKey(player.id),
      selected: done,
      onTap: done ? null : () => onSelected(player.id),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(
              done ? Icons.check_circle_outline : Icons.person_outline,
              size: 32,
              color: done ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (done) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              completedLabel,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }
}
