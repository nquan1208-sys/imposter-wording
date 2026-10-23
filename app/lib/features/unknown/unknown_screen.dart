import 'package:flutter/material.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = AppLocalizations.of(context).notFound;
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(message)),
    );
  }
}
