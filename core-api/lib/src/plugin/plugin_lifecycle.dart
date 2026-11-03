import 'dart:async';

/// Optional lifecycle for services owned by a compiled plugin. The composition
/// root starts and disposes each contributor once, in registration/reverse order.
/// Disposal also covers constructors whose start hook has not run.
abstract interface class PluginLifecycle {
  FutureOr<void> start();
  FutureOr<void> dispose();
}
