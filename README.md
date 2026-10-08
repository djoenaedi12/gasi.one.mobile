# GASI One Mobile

Flutter workspace for the GASI One mobile application. The repository follows
the same top-level vocabulary as the API and Web repositories: shared cores,
platform applications, and business plugins.

## Workspace structure

```text
gasi.one.mobile/
├── core-api/                 # Stable contracts and cross-package value types
├── core-starter/             # Runtime infrastructure and reusable orchestration
├── core-ui/                  # Design system, shared widgets, and localization
├── platform-app/             # Flutter composition root and native projects
└── plugins/
    ├── auth/                 # Authentication capability
    └── catalog/              # Product and category capability
```

The terms are deliberately aligned across platforms:

| Concept | Flutter package |
| --- | --- |
| Stable contracts | `gasione_core_api` |
| Runtime implementation | `gasione_core_starter` |
| Shared presentation | `gasione_core_ui` |
| Deployable application | `gasione` |
| Business capability | `gasione_plugin_*` |

Flutter plugins in this repository are compile-time Dart packages. Unlike the
PF4J API plugins, they are not loaded dynamically at runtime. Each business
plugin implements `AppPlugin` and contributes its routes and menus to
`PluginRegistry`.

## Dependency direction

```text
platform-app
    ├── plugins/*
    ├── core-starter
    └── core-ui

plugins/*
    ├── core-api
    ├── core-starter
    └── core-ui

core-starter ──> core-api
core-ui      ──> core-api
core-api     ──> no implementation package
```

Core packages never import a business plugin. Plugins do not import the mobile
application shell or another plugin directly. Cross-plugin collaboration must
use a contract placed in `core-api` (or a dedicated contract package when the
contract is not platform-wide).

## Running the application

Install the Pub workspace dependencies from the repository root, then run the
mobile platform app:

```bash
flutter pub get
cd platform-app
flutter run
```

The application currently includes authentication, product and category CRUD,
route protection, light/dark themes, Indonesian and English localization,
secure session storage, retries, and token refresh.

## Documentation

- [Development guide](docs/development.md)
- [Plugin development guide](docs/feature-development.md)
