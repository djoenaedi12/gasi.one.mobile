import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Runs preparation alongside a minimum two-second splash for each attempt.
/// Continues only when both finish; errors and retry stay on the splash.
class StartupGate<T> extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.initialize,
    required this.builder,
    this.disposeValue,
    this.versionOf,
  });

  /// Called once per attempt (initial mount or explicit retry).
  /// bootstrap.dart supplies AppDependencies.initialize here.
  final Future<T> Function() initialize;

  /// Opens the application only after initialization succeeds.
  final Widget Function(T) builder;
  final Future<void> Function(T)? disposeValue;

  /// Optional version metadata for the splash once preparation has returned.
  final String Function(T)? versionOf;

  @override
  State<StartupGate<T>> createState() => _StartupGateState<T>();
}

class _StartupGateState<T> extends State<StartupGate<T>> {
  late Future<T> _initialization;
  bool _handedOff = false;
  bool _initializing = false;
  bool _minimumSplashElapsed = false;
  Timer? _splashTimer;

  Future<T> _start() {
    _initializing = true;
    _minimumSplashElapsed = false;
    _splashTimer?.cancel();
    // Count visible time from the first splash frame, including retry attempts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _splashTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _minimumSplashElapsed = true);
      });
    });
    return Future<T>.sync(widget.initialize).whenComplete(() {
      _initializing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialization = _start();
  }

  void _retry() {
    if (_initializing || !_minimumSplashElapsed) return;
    final attempt = _start();
    setState(() {
      _initialization = attempt;
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    final disposeValue = widget.disposeValue;
    if (!_handedOff && disposeValue != null) {
      _initialization.then<void>(
        disposeValue,
        onError: (Object _, StackTrace _) {},
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _initialization,
    builder: (context, snapshot) {
      final prepared = snapshot.connectionState == ConnectionState.done;
      if (_minimumSplashElapsed && prepared && !snapshot.hasError) {
        _handedOff = true;
        return widget.builder(snapshot.data as T);
      }
      final failed = _minimumSplashElapsed && prepared && snapshot.hasError;
      final version = snapshot.hasData
          ? widget.versionOf?.call(snapshot.data as T)
          : null;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: failed
            ? AppSplashPage.failure(version: version, onRetry: _retry)
            : AppSplashPage.loading(version: version),
      );
    },
  );
}
