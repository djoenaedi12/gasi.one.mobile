import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/plugin_registry.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

void main() {
  testWidgets('deactivating a plugin closes its already-open picker', (
    tester,
  ) async {
    final registry = PluginRegistry([_PickerPlugin()]);
    addTearDown(registry.dispose);
    String? selection;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selection = await registry.open(
                  context,
                  const PickerKey<String>('orders.pick'),
                );
                completed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Order picker'), findsOneWidget);
    registry.activate([]);
    await tester.pumpAndSettle();
    expect(find.text('Order picker'), findsNothing);
    expect(completed, isTrue);
    expect(selection, isNull);
  });
  test('activation notifies subscribers and validates plugin codes', () {
    final registry = PluginRegistry([_Plugin('orders', '/orders')]);
    addTearDown(registry.dispose);
    var updates = 0;
    registry.addListener(() => updates++);
    registry.activate([]);
    registry.activate([]);
    expect(updates, 1);
    expect(registry.activeMenus, isEmpty);
    expect(() => registry.activate(['missing']), throwsArgumentError);
    registry.activate(['orders']);
    expect(registry.activeMenus, hasLength(1));
    expect(updates, 2);
  });
  test(
    'duplicate plugin codes, route shapes and reserved routes fail early',
    () {
      expect(
        () => PluginRegistry([_Plugin('a', '/a'), _Plugin('a', '/b')]),
        throwsArgumentError,
      );
      expect(
        () => PluginRegistry([
          _Plugin('a', '/orders/:id'),
          _Plugin('b', '/orders/:orderId'),
        ]),
        throwsArgumentError,
      );
      expect(
        () => PluginRegistry([_Plugin('a', '/HOME')], reservedPaths: ['/home']),
        throwsArgumentError,
      );
    },
  );
  test(
    'parameterized locations are protected when the owning plugin is disabled',
    () {
      final registry = PluginRegistry([_Plugin('orders', '/orders/:id')]);
      addTearDown(registry.dispose);
      registry.activate([]);
      expect(registry.isLocationEnabled('/orders/123?tab=items'), isFalse);
      expect(registry.isLocationEnabled('/orders/1234'), isFalse);
      expect(registry.isLocationEnabled('/unknown'), isTrue);
    },
  );
}

class _PickerPlugin extends _Plugin implements PickerContributor {
  _PickerPlugin() : super('orders', '/orders');
  @override
  List<PickerDefinitionBase> get pickers => [
    PickerDefinition<String>(
      key: const PickerKey('orders.pick'),
      pageBuilder: (_, _) => const Scaffold(body: Text('Order picker')),
    ),
  ];
}

class _Plugin implements AppPlugin {
  _Plugin(this.code, this.path);
  @override
  final String code;
  final String path;
  @override
  List<PluginRoute> get routes => [
    PluginRoute(path: path, builder: (_, _) => const SizedBox()),
  ];
  @override
  List<PluginMenuItem> get menus => [
    PluginMenuItem(route: path, icon: Icons.list, titleBuilder: (_) => code),
  ];
  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [];
  @override
  List<Locale> get supportedLocales => [];
}
