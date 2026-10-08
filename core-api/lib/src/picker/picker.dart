import 'package:flutter/widgets.dart';

/// A typed identifier for a picker contribution.
final class PickerKey<T> {
  const PickerKey(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PickerKey<T> && other.id == id;

  @override
  int get hashCode => Object.hash(T, id);

  @override
  String toString() => 'PickerKey<$T>($id)';
}

/// Common selection type for lookup-style pickers.
final class PickerValue {
  const PickerValue({
    required this.id,
    required this.label,
    this.metadata = const {},
  });

  final Object id;
  final String label;
  final Map<String, Object?> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PickerValue && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Values supplied by a consumer when opening a picker page.
final class PickerRequest<T> {
  const PickerRequest({
    this.title,
    this.initialValue,
    this.arguments = const {},
  });

  final String? title;
  final T? initialValue;
  final Map<String, Object?> arguments;
}

typedef PickerPageBuilder<T> = Widget Function(
  BuildContext context,
  PickerRequest<T> request,
);

/// Type-erased marker used to collect differently typed picker definitions.
abstract interface class PickerDefinitionBase {
  String get id;
}

/// A picker page contributed by a plugin.
final class PickerDefinition<T> implements PickerDefinitionBase {
  const PickerDefinition({required this.key, required this.pageBuilder});

  final PickerKey<T> key;
  final PickerPageBuilder<T> pageBuilder;

  @override
  String get id => key.id;
}

/// Optional capability implemented by plugins that provide picker pages.
abstract interface class PickerContributor {
  List<PickerDefinitionBase> get pickers;
}

/// Narrow contract used by consumers that need to open a registered picker.
abstract interface class PickerLauncher {
  Future<T?> open<T>(
    BuildContext context,
    PickerKey<T> key, {
    PickerRequest<T>? request,
  });
}

final class PickerUnavailableException implements Exception {
  const PickerUnavailableException(this.pickerId);

  final String pickerId;

  @override
  String toString() => 'Picker "$pickerId" is not available.';
}

final class PickerTypeMismatchException implements Exception {
  const PickerTypeMismatchException(this.pickerId, this.expectedType);

  final String pickerId;
  final Type expectedType;

  @override
  String toString() =>
      'Picker "$pickerId" is not registered for $expectedType.';
}
