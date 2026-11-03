import '../context/active_business_context.dart';

/// A user interaction, independent of Firebase and native notification APIs.
final class NotificationInteraction {
  NotificationInteraction({
    this.id,
    this.payload,
    Map<String, Object?> data = const {},
  }) : data = Map.unmodifiable(data);

  final String? id;
  final String? payload;
  final Map<String, Object?> data;
}

/// Resolvers must validate feature payload, permission and destination identity.
/// The host additionally checks company ownership and registered route paths.
final class NotificationDestination {
  const NotificationDestination({
    required this.route,
    required this.companyCode,
    this.arguments,
  });

  final String route;
  final String companyCode;
  final Object? arguments;
}

abstract interface class NotificationDestinationResolver {
  NotificationDestination? resolveNotification(
    NotificationInteraction interaction,
    ActiveBusinessContext context,
  );
}
