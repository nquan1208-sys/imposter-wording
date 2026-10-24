import 'package:flutter/material.dart';
import 'package:untitled/widgets/app_content.dart';
import 'package:untitled/theme/app_colors.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = AppLocalizations.of(context).notFound;
    return Scaffold(
      appBar: AppBar(),
      body: AppContent(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_off_outlined,
                  size: 64,
                  color: AppColors.gray,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
