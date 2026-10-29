# gasi.one.mobile

Modular Flutter foundation for GASI One. The project follows the same platform
shape as `gasi.one.api` and `gasi.one.web`: a small contract package, reusable
runtime infrastructure, shared UI, a deployable platform application, and
business capabilities organized as plugins.

The repository is currently in a legacy-parity transition. `platform-app`
owns startup, shared services, the application shell, and the Android/iOS
application. `plugins/legacy_epc` temporarily owns existing EPC feature pages. New features
will move into the modular architecture incrementally.

## Architecture Diagram

```text
       ┌─────────────────┐
       │ Android / iOS   │
       │ native projects │
       └────────▲────────┘
                │ packaged by
       ┌────────┴────────┐   launches   ┌─────────────────┐
       │ platform-app    │ ───────────▶ │ legacy_epc      │
       │ Flutter host    │              │ legacy pages    │
       └────────┬────────┘              └─────────────────┘
                │ plugin composition
       ┌────────┴────────┐              ┌─────────────────┐
       │ plugins/*       │ ───────────▶ │ core-api        │
       │ business slices │   contracts  │ platform SPI    │
       └───────┬─────────┘              └────────▲────────┘
               │ uses                            │ implements/uses
       ┌───────▼─────────┐              ┌────────┴────────┐
       │ core-ui         │              │ core-starter    │
       │ design system   │              │ runtime/impl    │
       └─────────────────┘              └─────────────────┘
```

The mobile plugin model is compile-time composition. Business plugins are Dart
packages included in the application build; unlike the API PF4J plugins and Web
UMD plugins, they are not downloaded or replaced dynamically at runtime.

## Modules

```text
gasi.one.mobile
├── core-api
├── core-starter
├── core-ui
├── platform-app
└── plugins
    ├── auth
    ├── business_context
    ├── attendance
    └── legacy_epc
```

- `core-api`: stable contracts, plugin extension points, route/menu value
  types, results, failures, pagination, and shared domain-neutral APIs.
- `core-starter`: reusable runtime implementation for HTTP, sessions, secure
  storage, Firebase, permissions, location, and Cubit orchestration.
- `core-ui`: design system, localization, reusable widgets, and shared
  presentation utilities.
- `platform-app`: deployable Flutter application, Android/iOS projects, Store
  version, signing, native capabilities, assets, and composition root.
- `plugins/auth`: registration skeleton and shared auth contracts; the Pre-Home
  CR supplies migrated authentication pages and implementation.
- `plugins/business_context`: user/license/menu/device bootstrap, typed active
  employee/context, and best-effort backend push registration.
- `plugins/attendance`: generic request workspace, workflow transport, picker,
  form/detail, and selection/bulk foundation.
- `plugins/legacy_epc`: existing Company/Login/verification, Home, and business
  pages behind the public composition boundary.
- future `plugins/*`: independently organized business capabilities compiled
  into `platform-app` and exposed through stable integration contracts.

Business features such as auth, leave, payroll, attendance, approval, or upload
should ultimately live in their owning plugin rather than in `platform-app`.
During parity, those flows remain inside `legacy_epc` until their complete
vertical slices are migrated.

## Current Runtime

The executable starts platform-owned bootstrap:

```dart
import 'bootstrap.dart';

void main() => bootstrap();
```

`StartupGate` owns initialization/retry and disposal. `GasioneApp` composes one
MaterialApp, theme/localization, shared HTTP/session services, plugin routes,
and the legacy fallback. The generic `AppEntryPage` restores installed state;
authentication pages and all attendance feature routes still belong to legacy.
The five-second splash, migrated auth UI, and the three attendance vertical
slices belong to the combined CR branch.

See [Foundation and CR boundaries](docs/mobile-cr-foundation.md) for prerequisite
coverage and the local branch/worktree handoff. See [Platform foundation](docs/platform-foundation.md)
for runtime ownership. Run `bash tool/verify.sh` to check modular formatting,
architecture, analysis, and tests. Legacy lint debt is tracked separately.

## Dependency Direction

Target dependency direction:

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

Practical rules:

- Put stable public contracts in `core-api`.
- Put reusable network, storage, device, and runtime behavior in
  `core-starter`.
- Put reusable visual components and design tokens in `core-ui`.
- Put bootstrap, native ownership, and feature composition in `platform-app`.
- Put business pages, state, repositories, data sources, routes, and menus in
  the owning plugin.
- Core packages must not import business plugins.
- A plugin must not import `platform-app` or another plugin implementation.
- Cross-plugin behavior uses a stable contract rather than implementation
  imports.
- New feature code must not import `package:epeoplecare/...`; only explicit
  compatibility adapters at the composition boundary may access legacy code.

The repository checks these import boundaries with
`dart run tool/check_architecture.dart`.

## Tech Stack

- Flutter 3.47.6
- Dart 3.13.5
- Dart Pub workspaces
- Flutter Bloc/Cubit for the target modular presentation layer
- Dio for target shared HTTP infrastructure
- `go_router` contracts for target route composition
- Firebase Core and Firebase Messaging
- Flutter Local Notifications
- Shared Preferences and Flutter Secure Storage
- Geolocator and Geocoding
- `core-ui` localization and design-system packages
- Easy Localization and Adaptive Theme in the current legacy runtime
- Android Gradle Plugin 9, Kotlin, and Java 17
- Swift/iOS 15 deployment target

## Prerequisites

- Flutter 3.47.6 with Dart `>=3.13.5 <4.0.0`.
- Android Studio or Android SDK with JDK 17 for Android development.
- Xcode and CocoaPods on macOS for iOS builds.
- Access to the required signing and Firebase configuration for release work.

Check the local environment:

```bash
flutter doctor
flutter devices
```

## Install

Resolve the Pub workspace from the repository root:

```bash
flutter pub get
```

Workspace members use `resolution: workspace` and share the root lockfile.

## Run Platform

Run the deployable application from `platform-app`:

```bash
cd platform-app
flutter run
```

Select a device explicitly when needed:

```bash
flutter run -d <device-id>
```

The platform owns startup, Firebase, notifications, the app shell, and generic
session restoration. Tenant selection, login, OTP, local verification, location,
and business pages continue through legacy integration on main.

## Build

Build commands run from the deployable platform application.

Android debug APK:

```bash
cd platform-app
flutter build apk --debug
```

Android release artifacts:

```bash
flutter build apk --release
flutter build appbundle --release
```

iOS archive on macOS with signing configured:

```bash
flutter build ipa --release
```

Build output is written under `platform-app/build/`.

Use the normal Flutter build command instead of `--no-pub` for the platform
application. This allows Flutter to resolve Pub workspace metadata and build
hooks correctly.

### Current build status

- Android debug APK: verified successfully.
- Android release AAB: still requires production signing verification.
- iOS archive: requires macOS/Xcode signing and capability validation.
- Full physical-device parity testing: pending.

See the integration runbook for the exact release blockers.

## Format, Analyze, And Test

Run the repository verification entry point from the workspace root:

```bash
bash tool/verify.sh
```

The script checks formatting for the modular core/platform source,
architecture boundaries, strict modular analysis plus the legacy integration
surface, and available core/platform/plugin test suites.

Useful focused commands:

```bash
dart run tool/check_architecture.dart
flutter analyze
(cd core-api && flutter test)
(cd core-starter && flutter test)
(cd core-ui && flutter test)
```

The imported legacy package still has known analyzer debt. Compatibility and
compile errors must be fixed immediately; existing lint cleanup should be done
incrementally and separately from business migrations.

## Platform And Package Versions

The modular foundation packages currently use the `0.1.0` development line:

```text
gasione_core_api       0.1.0
gasione_core_starter   0.1.0
gasione_core_ui        0.1.0
```

The deployable Store version is owned by `platform-app/pubspec.yaml`. The
current parity line is:

```text
platform-app       4.15.0+135
legacy_epc         4.15.0+134
```

The executable build number must be higher than every build already uploaded
to Google Play or App Store Connect.

Mobile business plugins are compile-time dependencies. Updating a core package
or plugin requires rebuilding and redistributing `platform-app`; mobile plugins
do not have independent runtime deployment like API or Web plugins.

## Plugin Direction

New business plugins should follow this shape:

```text
plugins/<plugin_name>/
├── pubspec.yaml
├── lib/
│   ├── gasione_plugin_<name>.dart
│   └── src/
│       ├── <name>_plugin.dart
│       └── features/
│           └── <feature>/
│               ├── data/
│               ├── domain/
│               └── presentation/
└── test/
```

The target feature flow is:

```text
Page / Widget
    ↓
Cubit
    ↓
Repository contract
    ↓
Repository implementation
    ↓
Remote or local data source
    ↓
core-starter infrastructure
```

Each plugin exposes only its integration surface. When the new platform shell
is introduced, plugin routes and menus will be composed through `AppPlugin`
rather than copied into the host.

Authentication is a special bootstrap capability because session restoration
and route protection depend on it. The production auth migration must cover
tenant selection, login, OTP/MFA, session restore, user/access data, logout,
401 handling, and compatibility with remaining legacy pages.

## Legacy Migration

Migration uses a strangler approach:

```text
parity release
  -> legacy seams and characterization tests
  -> production EPC auth
  -> platform shell and router ownership
  -> low-risk pilot module
  -> business modules by vertical slice
  -> shared capability extraction
  -> legacy runtime removal
```

One route and one runtime concern must have one authoritative owner. A migrated
flow keeps a single rollback decision until its stabilization window is
complete. Legacy source is not deleted in the first cutover release.

## Native Ownership

`platform-app` owns:

- application ID/bundle ID `com.gasi.ewf`;
- Android and iOS projects;
- Store version and signing configuration;
- app icons and native launch screens;
- native permissions and capabilities;
- Firebase platform files;
- release artifacts.

`platform-app` owns Firebase options and initialization; core-starter supplies
notification services. Legacy pages use injected runtime/push contracts. The
platform also owns theme/localization/navigation composition. Legacy keeps
feature UI, update policies, and the temporary Config mapping. See
[Platform foundation](docs/platform-foundation.md) before changing ownership.

Signing files, keystore passwords, APNs credentials, Firebase secrets, tokens,
and production payloads must never be committed or copied into documentation.

## More Details

- [Development Guide](docs/development.md)
- [Plugin Development Guide](docs/feature-development.md)
- [Legacy EPC Integration Runbook](docs/legacy-integration.md)
- [Legacy EPC Incremental Migration Roadmap](docs/legacy-migration-roadmap.md)

## Troubleshooting

### Platform build cannot find `package_config.json`

Run the build from `platform-app` without `--no-pub`:

```bash
cd platform-app
flutter build apk --debug
```

### CameraX fails with `CallbackToFutureAdapter not found`

Keep `camera: ^0.12.1` or a compatible newer version that resolves to the fixed
CameraX implementation. Do not patch the Pub cache manually.

### `flutter_html` fails while compiling the `html` package

The legacy package intentionally pins:

```yaml
html: 0.15.6
```

Do not remove the pin until `flutter_html` is upgraded or replaced.

### Legacy assets are missing

Legacy code uses application-level paths such as `assets/img/...` and
`assets/i18n/...`. Keep those assets declared by `platform-app`; moving them
only into a dependency package changes how Flutter resolves their keys.

### Push notifications work on one platform only

Check the native application identifier, Firebase application configuration,
notification permission, Android manifest, iOS Runner target membership,
Push Notifications capability, Background Modes, entitlements, provisioning
profile, and APNs configuration. The presence of a Firebase file alone does not
prove the native target is configured.
