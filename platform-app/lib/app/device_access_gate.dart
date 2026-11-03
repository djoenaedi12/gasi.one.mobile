import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Checks device access before the feature shell or session restore can start.
/// Native inspection and policy evaluation have already completed at startup.
class DeviceAccessGate extends StatelessWidget {
  const DeviceAccessGate({
    super.key,
    required this.security,
    required this.child,
    this.locale,
  });

  final DeviceSecurity security;
  final Widget child;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    // An invalid application signature takes precedence over device settings.
    if (security.signatureValid && !security.unsafeDevice) return child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppDeviceAccessDeniedPage(
        security: security,
        onExit: () => exit(0),
      ),
    );
  }
}
