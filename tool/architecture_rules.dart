/// Returns a violation for a forbidden package or layer dependency.
String? dependencyViolation({
  required String sourcePath,
  required String sourcePackage,
  required String targetPackage,
  required String targetPath,
}) {
  final isCore = sourcePackage.startsWith('gasione_core_');
  final isPlugin = sourcePackage.startsWith('gasione_plugin_');
  final targetIsPlugin = targetPackage.startsWith('gasione_plugin_');
  // TRANSITION[LEGACY-EPC]: these two guards retire with the epeoplecare package;
  // general core/plugin boundary rules below remain permanent.
  if ((isCore || isPlugin) && targetPackage == 'epeoplecare') {
    return 'Core and new plugins cannot depend on legacy implementations.';
  }
  if (sourcePackage == 'gasione' &&
      targetPackage == 'epeoplecare' &&
      targetPath != 'lib/legacy_epc.dart') {
    return 'The host must use the legacy public integration surface.';
  }
  if (isCore && (targetIsPlugin || targetPackage == 'gasione')) {
    return 'Core packages cannot depend on business plugins or the app.';
  }
  if (isPlugin &&
      (targetPackage == 'gasione' ||
          (targetIsPlugin && targetPackage != sourcePackage))) {
    return 'Plugins cannot depend on the app or another plugin.';
  }
  if (sourcePackage == 'gasione_core_api' &&
      {'gasione_core_starter', 'gasione_core_ui'}.contains(targetPackage)) {
    return 'core-api cannot depend on implementation packages.';
  }
  if (sourcePackage == 'gasione_core_starter' &&
          targetPackage == 'gasione_core_ui' ||
      sourcePackage == 'gasione_core_ui' &&
          targetPackage == 'gasione_core_starter') {
    return 'core-starter and core-ui must remain independent.';
  }
  if (sourcePath.contains('/domain/')) {
    if (targetPackage != sourcePackage &&
        targetPackage != 'gasione_core_api' &&
        targetPackage != 'dart') {
      return 'Domain code can only import domain contracts and pure Dart libraries.';
    }
    if (targetPackage == sourcePackage && !targetPath.contains('/domain/')) {
      return 'Domain code cannot depend on data or presentation.';
    }
    if (targetPackage == 'dart' &&
        {'io', 'ui', 'html', 'js_interop'}.contains(targetPath)) {
      return 'Domain code cannot depend on platform libraries.';
    }
  }
  if (sourcePath.contains('/presentation/') &&
      targetPackage == sourcePackage &&
      targetPath.contains('/data/')) {
    return 'Presentation must depend on repository contracts, not data implementations.';
  }
  return null;
}
