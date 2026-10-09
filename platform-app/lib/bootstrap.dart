import 'package:flutter/widgets.dart';
import 'package:gasione/app/app.dart';
import 'package:gasione/app/app_dependencies.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.create();
  runApp(GasiOneApp(dependencies: dependencies));
}
