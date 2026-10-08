# Plugin Development Guide

A business capability lives in `plugins/<plugin_name>`. The term **plugin** is
shared with the API and Web repositories, while its Flutter implementation is a
compile-time Dart package rather than a dynamically loaded PF4J plugin.

## Plugin layout

```text
plugins/sales/
├── pubspec.yaml
├── lib/
│   ├── gasione_plugin_sales.dart
│   └── src/
│       ├── sales_plugin.dart
│       └── features/
│           └── orders/
│               ├── data/
│               │   ├── datasources/
│               │   ├── models/
│               │   └── repositories/
│               ├── domain/
│               │   ├── entities/
│               │   └── repositories/
│               └── presentation/
│                   ├── cubits/
│                   ├── pages/
│                   └── widgets/
└── test/
```

Create only the layers and directories the feature needs.

## Package responsibilities

| Package | Responsibility |
| --- | --- |
| `core-api` | `AppPlugin`, routes, menus, result/failure, CRUD contracts, pagination value types |
| `core-starter` | API client, storage, failure mapping, device services, reusable Cubit orchestration |
| `core-ui` | Design system, shared presentation helpers, English and Indonesian localization |
| `plugins/*` | Business domain, data access, presentation, routes, menus, and dependency assembly |
| `platform-app` | Bootstrap, app-wide dependencies, router, theme preference, and plugin activation |

The dependency rules are:

- `core-api` does not depend on implementation packages.
- Core packages do not import plugins.
- A plugin does not import `gasione` or another plugin.
- Cross-plugin behavior uses a stable contract, normally in `core-api`.
- Domain code does not depend on widgets, Dio, JSON models, or storage implementations.
- Presentation depends on domain contracts, not concrete repositories or data sources.

## Feature data flow

```text
Page / Widget
    ↓
Cubit
    ↓
Repository contract (domain)
    ↓
Repository implementation (data)
    ↓
Remote or local data source
    ↓
core-starter infrastructure
```

Responses return as transport models, map to domain entities, become
`Result<T>`, and are converted into feature state by the Cubit.

## Implement a plugin

### 1. Define domain contracts

Keep entities independent of API payloads and declare repositories as abstract
interfaces. Return `Result<T>` for fallible operations:

```dart
abstract interface class OrderRepository {
  Future<Result<List<Order>>> getOrders();
}
```

### 2. Implement the data layer

Transport models own JSON serialization. Data sources own endpoint paths and
response parsing. Repository implementations map transport models to entities
and use `guardResult` to normalize failures.

Run model generation in the owning plugin:

```bash
cd plugins/sales
dart run build_runner build --delete-conflicting-outputs
```

### 3. Build presentation

Cubits depend on repository interfaces. Pages handle user interaction and
render state. Use `core-ui` for shared components and localized text; keep
feature-specific widgets inside the plugin.

### 4. Implement `AppPlugin`

The plugin entry point owns its internal dependency graph and exposes only its
integration surface:

```dart
final class SalesPlugin implements AppPlugin {
  SalesPlugin({required ApiClient apiClient})
      : _orderRepository = OrderRepositoryImpl(
          OrderRemoteDataSource(apiClient),
        );

  final OrderRepository _orderRepository;

  @override
  String get code => 'sales';

  @override
  List<PluginRoute> get routes => [
    PluginRoute(
      path: '/orders',
      builder: (context, state) => BlocProvider(
        create: (_) => OrdersCubit(_orderRepository)..load(),
        child: const OrderListPage(),
      ),
    ),
  ];

  @override
  List<PluginMenuItem> get menus => const [];
}
```

Plugin codes use lowercase stable identifiers such as `auth`, `catalog`, and
`sales`.

### 5. Register the plugin

Add the package to the root workspace and the mobile app dependencies. Create
the plugin in `platform-app/lib/app/app_dependencies.dart`, then add it
to `PluginRegistry`. The router and home menu consume the registry, so plugin
routes and menus do not need to be copied into the application shell.

Authentication is a special bootstrap plugin: the app composes its login route
before protected plugin routes because session redirect logic depends on it.

### 6. Test

Mirror `lib/src/features` beneath the plugin's `test` directory. At minimum,
cover model parsing, repository mapping, Cubit state transitions, important UI
states, and navigation actions.

```bash
(cd plugins/sales && flutter test)
flutter analyze
```

## Completion checklist

- The plugin represents one coherent business capability.
- Public integration occurs through `AppPlugin` and the package barrel.
- Domain contracts are separate from data implementations.
- Technical errors become typed `Failure` values.
- User-facing text is localized through `core-ui`.
- Routes and menus are contributed by the plugin.
- Tests and generated files are current.
- Formatting, analyzer, tests, and the mobile build pass.
