import 'dart:io';

import 'architecture_rules.dart';

void main(List<String> arguments) {
  final root = Directory(
    Directory(arguments.isEmpty ? '.' : arguments.single)
        .resolveSymbolicLinksSync(),
  );
  final packages = <String, Directory>{};
  for (final entry in root.listSync(recursive: true, followLinks: false)) {
    if (entry is! File ||
        !entry.path.endsWith('/pubspec.yaml') ||
        entry.path.contains('/build/') ||
        entry.path.contains('/.dart_tool/')) {
      continue;
    }
    final match = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(entry.readAsStringSync());
    if (match != null && Directory('${entry.parent.path}/lib').existsSync()) {
      packages[match.group(1)!] = entry.parent;
    }
  }
  final directives = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
  var violations = 0;
  for (final source in packages.entries) {
    for (final file in Directory(
      '${source.value.path}/lib',
    ).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final directive in directives.allMatches(file.readAsStringSync())) {
        final uri = Uri.parse(directive.group(1)!);
        String targetPackage;
        String targetPath;
        if (uri.scheme == 'package') {
          targetPackage = uri.pathSegments.first;
          targetPath = 'lib/${uri.pathSegments.skip(1).join('/')}';
        } else if (uri.scheme == 'dart') {
          targetPackage = 'dart';
          targetPath = uri.path;
        } else if (uri.scheme.isEmpty) {
          final resolved = file.uri.resolveUri(uri).toFilePath();
          final owner = packages.entries
              .where((p) => resolved.startsWith('${p.value.path}/'))
              .firstOrNull;
          if (owner == null) continue;
          targetPackage = owner.key;
          targetPath = resolved.substring(owner.value.path.length + 1);
        } else {
          continue;
        }
        final violation = dependencyViolation(
          sourcePath: file.path,
          sourcePackage: source.key,
          targetPackage: targetPackage,
          targetPath: targetPath,
        );
        if (violation != null) {
          ++violations;
          stderr.writeln('${file.path}: ${uri.toString()}: $violation');
        }
      }
    }
  }
  if (packages.isEmpty) {
    stderr.writeln(
      'No workspace packages found. Run this check from the repository root.',
    );
    exitCode = 1;
  } else if (violations > 0) {
    exitCode = 1;
  } else {
    stdout.writeln(
      'Architecture boundaries passed (${packages.length} packages).',
    );
  }
}
