import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:gasione_core_api/gasione_core_api.dart';

typedef _SessionIdentity = (String, String, String);

/// Queues interactions until both context and local verification are ready.
/// Payload parsing and permission checks belong to contributed feature resolvers.
final class NotificationNavigationCoordinator {
  NotificationNavigationCoordinator({
    required this.context,
    required this.interactions,
    required this.initialInteraction,
    required Iterable<NotificationDestinationResolver> resolvers,
    required this.isRegisteredRoute,
    required this.navigate,
    this.schedule = scheduleMicrotask,
    this.onError,
  }) : _resolvers = List.unmodifiable(resolvers);

  final BusinessContextProvider context;
  final Stream<NotificationInteraction> interactions;
  final NotificationInteraction? Function() initialInteraction;
  final List<NotificationDestinationResolver> _resolvers;
  final bool Function(String) isRegisteredRoute;
  final void Function(NotificationDestination) navigate;
  final void Function(void Function()) schedule;
  final void Function(String, Object, StackTrace)? onError;
  final _pending =
      Queue<
        ({NotificationInteraction interaction, _SessionIdentity? session})
      >();
  final _seen = <String>{};
  StreamSubscription<NotificationInteraction>? _interactions;
  StreamSubscription<ActiveBusinessContext?>? _contexts;
  _SessionIdentity? _readySession;
  _SessionIdentity? _session;
  bool _started = false;
  bool _scheduled = false;
  bool _disposed = false;

  _SessionIdentity? _identity(ActiveBusinessContext? value) => value == null
      ? null
      : (value.sessionId, value.company.code, value.company.baseUrl);

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _session = _identity(context.activeContext);
    _contexts = context.contextChanges.listen(_contextChanged);
    _interactions = interactions.listen(_accept);
    final initial = initialInteraction();
    if (initial != null) _accept(initial);
  }

  /// The host calls this only after authentication AND local verification.
  /// Context availability alone must never unlock navigation.
  void setReady(bool ready) {
    if (_disposed) return;
    _readySession = ready ? _identity(context.activeContext) : null;
    _schedule();
  }

  void _contextChanged(ActiveBusinessContext? value) {
    if (_disposed) return;
    final current = _identity(value);
    if (current != _session) {
      _session = current;
      if (_readySession != current) _readySession = null;
      // Never carry a signed-in user's queued action into another session.
      _pending.removeWhere(
        (event) => event.session != null && event.session != current,
      );
    }
    _schedule();
  }

  void _accept(NotificationInteraction interaction) {
    if (_disposed) return;
    try {
      final keys = interaction.data.keys.toList()..sort();
      final key =
          interaction.id ??
          jsonEncode([
            interaction.payload,
            {for (final key in keys) key: interaction.data[key]},
          ]);
      if (!_seen.add(key)) return;
      if (_seen.length > 128) _seen.remove(_seen.first);
      if (_pending.length == 16) _pending.removeFirst();
      _pending.add((
        interaction: interaction,
        session: _identity(context.activeContext),
      ));
      _schedule();
    } catch (error, stack) {
      onError?.call('notification_payload', error.runtimeType, stack);
    }
  }

  void _schedule() {
    if (!_started || _disposed || _scheduled || _pending.isEmpty) return;
    _scheduled = true;
    schedule(() {
      _scheduled = false;
      if (!_disposed) _drain();
    });
  }

  void _drain() {
    final active = context.activeContext;
    final identity = _identity(active);
    if (active == null || _readySession == null || _readySession != identity) {
      return;
    }
    while (_pending.isNotEmpty) {
      final event = _pending.removeFirst();
      if (event.session != null && event.session != identity) continue;
      try {
        NotificationDestination? destination;
        for (final resolver in _resolvers) {
          destination = resolver.resolveNotification(event.interaction, active);
          if (destination != null) break;
        }
        if (destination == null ||
            destination.companyCode != active.company.code ||
            !isRegisteredRoute(destination.route)) {
          continue;
        }
        // A resolver cannot navigate using a context it invalidated itself.
        if (_identity(context.activeContext) != identity ||
            _readySession != identity) {
          return;
        }
        navigate(destination);
        _schedule();
        return;
      } catch (error, stack) {
        onError?.call('notification_navigation', error.runtimeType, stack);
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pending.clear();
    _seen.clear();
    await _interactions?.cancel();
    await _contexts?.cancel();
  }
}
