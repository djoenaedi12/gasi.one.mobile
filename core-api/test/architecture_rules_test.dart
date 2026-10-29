import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';

void main() {
  test(
    'workspace check rejects a relative import crossing a package boundary',
    () async {
      final fixture = Directory.systemTemp.createTempSync('gasi-architecture-');
      addTearDown(() => fixture.deleteSync(recursive: true));
      for (final package in ['api', 'starter']) {
        Directory('${fixture.path}/$package/lib/src/domain')
            .createSync(recursive: true);
        File('${fixture.path}/$package/pubspec.yaml').writeAsStringSync(
          'name: gasione_core_${package == 'api' ? 'api' : 'starter'}\n',
        );
      }
      File(
        '${fixture.path}/api/lib/src/domain/bad.dart',
      ).writeAsStringSync("import '../../../../starter/lib/runtime.dart';\n");
      File('${fixture.path}/starter/lib/runtime.dart')
          .writeAsStringSync('class Runtime {}\n');
      final script =
          (File('tool/check_architecture.dart').existsSync()
                  ? File('tool/check_architecture.dart')
                  : File('../tool/check_architecture.dart'))
              .absolute
              .path;
      final result = await Process.run('dart', [
        'run',
        script,
        '${fixture.path}/.',
      ]);
      expect(result.exitCode, 1);
      expect(
        result.stderr.toString(),
        contains('core-api cannot depend on implementation packages'),
      );
    },
  );
  String? check(
    String source,
    String target, {
    String path = 'lib/public.dart',
    String layer = 'domain',
  }) => dependencyViolation(
    sourcePath: 'lib/src/$layer/example.dart',
    sourcePackage: source,
    targetPackage: target,
    targetPath: path,
  );

  test('domain accepts contracts and rejects infrastructure and widgets', () {
    expect(check('gasione_plugin_catalog', 'gasione_core_api'), isNull);
    expect(check('gasione_plugin_catalog', 'gasione_core_starter'), isNotNull);
    expect(check('gasione_plugin_catalog', 'flutter'), isNotNull);
    expect(
      check(
        'gasione_plugin_catalog',
        'gasione_plugin_catalog',
        path: 'lib/src/data/model.dart',
      ),
      isNotNull,
    );
  });
  test('core and plugins cannot depend on app or other business plugins', () {
    expect(
      check('gasione_core_ui', 'gasione_plugin_auth', layer: 'widgets'),
      isNotNull,
    );
    expect(
      check('gasione_plugin_catalog', 'gasione_plugin_auth', layer: 'data'),
      isNotNull,
    );
    expect(
      check('gasione_plugin_catalog', 'gasione', layer: 'data'),
      isNotNull,
    );
    expect(
      check('gasione_plugin_catalog', 'gasione_core_starter', layer: 'data'),
      isNull,
    );
  });
  test('presentation cannot bypass domain repository contracts', () {
    expect(
      check(
        'gasione_plugin_catalog',
        'gasione_plugin_catalog',
        layer: 'presentation',
        path: 'lib/src/data/repository.dart',
      ),
      isNotNull,
    );
    expect(
      check(
        'gasione_plugin_catalog',
        'gasione_plugin_catalog',
        layer: 'presentation',
        path: 'lib/src/domain/repository.dart',
      ),
      isNull,
    );
  });
  // TRANSITION[LEGACY-EPC]: retire these EPC-specific assertions with the package;
  // keep all general core/plugin dependency tests above.
  test('legacy implementation stays behind its public integration surface', () {
    expect(
      check('gasione_core_starter', 'epeoplecare', layer: 'services'),
      isNotNull,
    );
    expect(
      check('gasione_plugin_auth', 'epeoplecare', layer: 'data'),
      isNotNull,
    );
    expect(
      check('gasione', 'epeoplecare', path: 'lib/config.dart', layer: 'app'),
      isNotNull,
    );
    expect(
      check(
        'gasione',
        'epeoplecare',
        path: 'lib/legacy_epc.dart',
        layer: 'app',
      ),
      isNull,
    );
  });
}
