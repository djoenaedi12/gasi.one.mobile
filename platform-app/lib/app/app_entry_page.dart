import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Generic entry gate with retry, independent of feature splash presentation.
/// This gate stays when the auth implementation and its pages move to a plugin.
class AppEntryPage extends StatefulWidget {
  const AppEntryPage({
    super.key,
    required this.auth,
    required this.buildDestination,
    this.onError,
  });

  final AuthRestorer auth;
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
    _restoration = _restore();
  }

  Future<AuthStatus> _restore() async {
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
    final attempt = _restore();
    setState(() {
      _restoration = attempt;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthStatus>(
    future: _restoration,
    builder: (context, snapshot) {
      final strings = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(strings.preparingApp),
                ],
              ),
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: AppErrorView(
              message: strings.appPreparationFailed,
              actionLabel: strings.retry,
              onAction: _retry,
            ),
          ),
        );
      }
      return widget.buildDestination(context, snapshot.requireData);
    },
  );
}
