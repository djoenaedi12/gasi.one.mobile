# Development Guide

This repository is a Dart Pub workspace. Run workspace-wide commands from the
repository root and app-specific commands from `platform-app`.

## Prerequisites

- Flutter 3.47.6 (the version used by CI), with Dart `>=3.13.5 <4.0.0`
- Android Studio or Android SDK and JDK 17 for Android builds
- Xcode and CocoaPods for iOS builds

```bash
flutter doctor
flutter devices
```

## Setup and run

```bash
flutter pub get
cd platform-app
flutter run
```

Use `flutter run -d <device-id>` to select a device.

## Localization

Shared localization belongs to `core-ui`, while feature-specific localization
belongs to the plugin that owns the feature:

- `core-ui/lib/src/localization/l10n/app_en.arb`
- `core-ui/lib/src/localization/l10n/app_id.arb`
- `core-ui/l10n.yaml`
- `plugins/<plugin>/lib/src/localization/l10n/<plugin>_en.arb`
- `plugins/<plugin>/lib/src/localization/l10n/<plugin>_id.arb`
- `plugins/<plugin>/l10n.yaml`

Add every message key to both ARB files in the owning package, then generate
the Dart classes:

```bash
cd core-ui
flutter gen-l10n

cd ../plugins/auth
flutter gen-l10n

cd ../catalog
flutter gen-l10n
```

Generated localization files must not be edited manually.

## JSON model generation

Run `build_runner` from the plugin that owns the model:

```bash
cd plugins/auth
dart run build_runner build --delete-conflicting-outputs

cd ../catalog
dart run build_runner build --delete-conflicting-outputs
```

For watch mode, replace `build` with `watch`.

## Native splash

The native splash configuration belongs to the mobile application:

```bash
cd platform-app
dart run flutter_native_splash:create
```

## Format, analyze, and test

From the workspace root:

```bash
dart format .
bash tool/verify.sh
```

`verify.sh` checks formatting, architecture boundaries, static analysis, and
all six package test suites. A root `flutter test` does not replace those
per-package suites. CI runs the same script on pushes and pull requests.

Run an individual package suite when working locally in that package:

```bash
(cd core-api && flutter test)
(cd core-starter && flutter test)
(cd core-ui && flutter test)
(cd plugins/auth && flutter test)
(cd plugins/catalog && flutter test)
(cd platform-app && flutter test)
```

## Build

Build commands run from the deployable platform application:

```bash
cd platform-app
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

On macOS with signing configured:

```bash
flutter build ipa --release
```

Build output is written under `platform-app/build/`. Configure a
production keystore before distributing an Android release build.

## Regenerate everything

```bash
flutter pub get
(cd core-ui && flutter gen-l10n)
(cd plugins/auth && flutter gen-l10n)
(cd plugins/catalog && flutter gen-l10n)
(cd plugins/auth && dart run build_runner build --delete-conflicting-outputs)
(cd plugins/catalog && dart run build_runner build --delete-conflicting-outputs)
```

See the [Plugin Development Guide](feature-development.md) for boundaries,
registration, and feature implementation rules.
