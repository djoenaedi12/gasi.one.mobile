import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'app/startup_gate.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    StartupGate<AppDependencies>(
      initialize: AppDependencies.initialize,
      disposeValue: (dependencies) => dependencies.dispose(),
      builder: (dependencies) => GasioneApp(dependencies: dependencies),
    ),
  );
}
