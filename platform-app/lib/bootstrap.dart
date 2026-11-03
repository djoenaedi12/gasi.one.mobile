import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'app/startup_gate.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  // First: prepare shared services, showing loading/retry while they start.
  // Then: GasioneApp checks device access before restoring the session.
  // See docs/startup-flow.md for the complete path to the first page.
  runApp(
    StartupGate<AppDependencies>(
      initialize: AppDependencies.initialize,
      disposeValue: (dependencies) => dependencies.dispose(),
      versionOf: (dependencies) => dependencies.runtime.info.version,
      builder: (dependencies) => GasioneApp(dependencies: dependencies),
    ),
  );
}
