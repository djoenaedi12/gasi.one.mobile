import 'package:flutter/material.dart';

typedef PluginMenuTitleBuilder = String Function(BuildContext context);

class PluginMenuItem {
  const PluginMenuItem({
    required this.route,
    required this.icon,
    required this.titleBuilder,
  });

  final String route;
  final IconData icon;
  final PluginMenuTitleBuilder titleBuilder;
}
