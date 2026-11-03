import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// After device access is accepted, restores the session and opens its first page.
/// The AuthRestorer owns session details; buildDestination owns the status/page map.
/// This gate stays when the legacy implementation moves to an auth plugin.
class AppEntryPage extends StatefulWidget {
  const AppEntryPage({
    super.key,
    required this.auth,
    required this.buildDestination,
    this.onError,
    this.appVersion,
  });

  final AuthRestorer auth;
  final String? appVersion;
  final Widget Function(BuildContext context, AuthStatus status)
  buildDestination;
  final void Function(String operation, Object error, StackTrace stack)?
  onError;

  @override
  State<AppEntryPage> createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> {
  late Future<AuthStatus> _restoration;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _restoration = _restoreSession();
  }

  Future<AuthStatus> _restoreSession() async {
    _restoring = true;
    try {
      return await widget.auth.restore();
    } catch (error, stack) {
      if (mounted) widget.onError?.call('session_restore', error, stack);
      rethrow;
    } finally {
      _restoring = false;
    }
  }

  void _retry() {
    if (_restoring) return;
    final attempt = _restoreSession();
    setState(() {
      _restoration = attempt;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthStatus>(
    future: _restoration,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return AppSplashPage.loading(version: widget.appVersion);
      }
      if (snapshot.hasError) {
        return AppSplashPage.failure(
          version: widget.appVersion,
          onRetry: _retry,
        );
      }
      // A successful restore returns the next required step, not necessarily Home.
      return widget.buildDestination(context, snapshot.requireData);
    },
  );
}
