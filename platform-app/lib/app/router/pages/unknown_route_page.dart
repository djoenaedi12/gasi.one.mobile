import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({required this.routeName, super.key});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.pageNotFound)),
      body: Center(
        child: Text(localizations.routeNotFound(routeName ?? '(unknown)')),
      ),
    );
  }
}
