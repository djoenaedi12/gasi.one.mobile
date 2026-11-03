import 'package:flutter/widgets.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

/// Makes the host's launcher available without a dependency on platform-app.
final class PickerScope extends InheritedWidget {
  const PickerScope({super.key, required this.launcher, required super.child});

  final PickerLauncher launcher;

  static PickerLauncher of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PickerScope>();
    if (scope == null) throw StateError('No PickerScope in this context.');
    return scope.launcher;
  }

  @override
  bool updateShouldNotify(PickerScope oldWidget) =>
      launcher != oldWidget.launcher;
}
