# Legacy EPC Integration Runbook

> Foundation update (29 October 2026): startup and the application shell now
> belong to `platform-app`. Auth/attendance UI cutover remains in the CR branch.
> [Current ownership and prerequisite coverage](mobile-cr-foundation.md) supersedes
> historical runtime/status descriptions below. Native release checks remain applicable.


This document describes how the former EPC mobile application is integrated
into the `gasi.one.mobile` workspace with the smallest practical behavior
change. It also records the current repository state, the compatibility work
already completed, the remaining native-platform work, and the verification
required before a Store release.

The initial goal is release parity, not modernization. The legacy application
must run from the new workspace first. Features can then be migrated one
vertical slice at a time without forcing a full rewrite.

Last verified: 12 October 2026.

## 1. Intended outcome

The parity release has the following shape:

```text
platform-app
  -> starts package:epeoplecare/main.dart
  -> owns Android and iOS projects
  -> owns Store versioning, signing, icons, launch screen, and native permissions
  -> packages the legacy assets

plugins/legacy_epc
  -> keeps the Dart package name epeoplecare
  -> owns the current application shell and legacy navigation
  -> owns the current UI, theme, localization, session, and business logic
  -> initializes Firebase and uses messaging, notifications, and geolocation
```

This arrangement allows `platform-app` to produce the Store artifact while the
legacy application continues to behave and look like the previous EPC app.

### Current result

- `platform-app` is the executable application.
- `plugins/legacy_epc` contains the legacy EPC Dart code.
- The legacy package name remains `epeoplecare`, so existing imports do not
  need to be rewritten.
- `platform-app/lib/main.dart` delegates directly to the legacy entry point.
- Legacy images, translations, and the custom root certificate are packaged by
  `platform-app` under their original asset keys.
- Android debug APK generation succeeds.
- Android Firebase, permissions, signing configuration, icons, app identity,
  and the custom integrity channel have been carried into `platform-app`.
- iOS identity, permission descriptions, Firebase files, icons, launch assets,
  and entitlements have been copied, but iOS signing/capability linkage still
  requires validation in Xcode.

## 2. Explicit non-goals for the parity release

Do not combine the initial integration with any of the following:

- replacing the legacy `Navigator` flow with `go_router`;
- replacing global state, providers, or service locators with Cubits;
- redesigning legacy pages;
- changing client-specific colors or the legacy theme;
- replacing `EasyLocalization`, `AdaptiveTheme`, or `EasyLoading`;
- moving every model and repository into the new architecture;
- initializing Firebase a second time from `core-starter`;
- enabling a sample auth or catalog implementation in the production runtime.

Only `legacy_epc` is currently registered under `plugins` in the active Pub
workspace. If example plugins are restored later, keep them outside the
`platform-app` dependency graph until a real feature migration begins.

## 3. Current workspace structure

```text
gasi.one.mobile/
├── core-api/
├── core-starter/
├── core-ui/
├── docs/
├── platform-app/                 # executable and native projects
│   ├── android/
│   ├── ios/
│   ├── assets/
│   └── lib/main.dart
└── plugins/
    └── legacy_epc/               # legacy EPC Dart package
        ├── lib/
        ├── analysis_options.yaml
        └── pubspec.yaml
```

The folder is named `legacy_epc`, but its Dart package is intentionally still
named `epeoplecare`:

```yaml
name: epeoplecare
```

This preserves imports such as:

```dart
import 'package:epeoplecare/config.dart';
```

## 4. Ownership during parity

| Concern | Current owner |
| --- | --- |
| Executable and Store artifact | `platform-app` |
| Android and iOS projects | `platform-app` |
| Version used for publication | `platform-app/pubspec.yaml` |
| Legacy UI and navigation | `legacy_epc` |
| Legacy theme and tenant colors | `legacy_epc` |
| Localization runtime | `legacy_epc` |
| Session and preferences | `legacy_epc` |
| Firebase initialization | `legacy_epc` |
| FCM behavior and local notifications | `legacy_epc` |
| Geolocation and geocoding behavior | `legacy_epc` |
| Native Firebase files and capabilities | `platform-app` |
| Future migrated features | new feature packages composed by `platform-app` |

There must be only one owner for Firebase initialization, session truth,
application shell, and each route at any point in the migration.

## 5. Reproducing the integration from zero

### 5.1 Preserve a baseline

Before copying anything, record the previous production version and create a
known-good baseline from the old application when it is still available:

```bash
flutter --version
flutter pub get
flutter analyze
flutter build apk --debug
```

Keep screenshots and smoke-test results for login, OTP, home, notification,
attendance, camera/file upload, payroll PDF, logout, and session restoration.
Existing technical debt is allowed in the baseline; unexpected behavior
changes are not.

### 5.2 Create the legacy package

Copy the old Dart source into `plugins/legacy_epc/lib` and retain the original
package name:

```yaml
name: epeoplecare
description: Legacy EPC mobile application.
publish_to: "none"
version: 4.15.0+134

environment:
  sdk: ^3.13.5

resolution: workspace
```

Register it in the workspace root:

```yaml
workspace:
  - core-api
  - core-starter
  - core-ui
  - platform-app
  - plugins/legacy_epc
```

Each package must declare every package that it imports directly. A dependency
declared by `core-starter` does not automatically become a valid direct
dependency of `legacy_epc`.

### 5.3 Make `platform-app` a thin launcher

The executable depends on the workspace package by version constraint:

```yaml
dependencies:
  flutter:
    sdk: flutter
  epeoplecare: ^4.15.0
```

Do not use a `path:` dependency for a package that is already a Pub workspace
member.

The parity entry point is deliberately small:

```dart
import 'package:epeoplecare/main.dart' as legacy;

void main() => legacy.main();
```

At this stage, the legacy `EWorkflowApp` remains the only application shell.
It still owns `MaterialApp`, theme selection, localization, loading overlays,
the navigator key, startup decisions, and legacy routes.

The current executable version is one build above the imported legacy package:

```yaml
# platform-app/pubspec.yaml
version: 4.15.0+135
```

Always confirm the production Store build number before publishing. The new
build number must be higher than every build already uploaded to the Store.

### 5.4 Preserve legacy asset keys

Legacy code loads global asset keys such as `assets/img/logo.png` and
`assets/i18n`. Assets declared only inside a dependency package may require a
package prefix, so the parity build keeps them in the executable:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/img/
    - assets/i18n/en.json
    - assets/i18n/id.json
    - assets/ca/
```

The current asset groups are:

- `platform-app/assets/img/` for legacy images and SVG files;
- `platform-app/assets/i18n/` for English and Indonesian translations;
- `platform-app/assets/ca/isrgrootx1.pem` for the custom trusted root used by
  the legacy bootstrap.

Do not rename these paths during parity. The legacy code loads them directly.

## 6. Dependency alignment and compatibility patches

The legacy code was copied as-is first, then only the changes required by the
current Flutter and plugin APIs were applied.

### Important resolved versions

| Package | Current constraint | Notes |
| --- | --- | --- |
| `firebase_core` | `^4.15.0` | initialized explicitly with generated options |
| `firebase_messaging` | `^16.7.0` | legacy provider remains the runtime owner |
| `flutter_local_notifications` | `^22.3.1` | updated named-parameter APIs |
| `geocoding` | `^5.0.0` | wrapper object API is used |
| `geolocator` | `^14.1.1` | uses `LocationSettings` |
| `permission_handler` | `^12.0.3` | native permission declarations remain in the app |
| `shared_preferences` | `^2.5.5` | existing session keys remain unchanged |
| `flutter_html` | `^3.0.0` | legacy HTML rendering retained |
| `html` | `0.15.6` | intentionally pinned for `flutter_html 3.0.0` compatibility |
| `camera` | `^0.12.1` | resolves the Gradle 9/CameraX compile failure |

### Why `html` is pinned

`flutter_html 3.0.0` still calls an API that is unavailable in `html 0.15.7`.
Allowing Pub to select `0.15.7` caused a Dart compilation failure. The direct
pin below is therefore intentional and must not be removed until
`flutter_html` is upgraded or replaced:

```yaml
html: 0.15.6
```

### Why `camera` was upgraded

With `camera 0.11.x`, Pub selected `camera_android_camerax 0.6.30`, which used
CameraX `1.5.3`. Under Gradle 9, its Java compile classpath did not contain
`CallbackToFutureAdapter`, and `compileDebugJavaWithJavac` failed.

The current constraint is:

```yaml
camera: ^0.12.1
```

It currently resolves to `camera_android_camerax 0.7.5+1`, using CameraX
`1.6.2`, where the upstream classpath problem is fixed. Do not patch files
inside `.pub-cache`; those edits are local, non-reproducible, and will be lost.

### Compatibility changes already applied

- Firebase initialization uses
  `DefaultFirebaseOptions.currentPlatform` and occurs once in legacy `main()`.
- Local notification initialization and display calls use the current named
  parameters and Darwin notification settings.
- Geolocation uses
  `Geolocator.getCurrentPosition(locationSettings: LocationSettings(...))`.
- File and image picking use the current plugin return types and nullable paths.
- Enum conversion and removed/deprecated Flutter APIs were adjusted without
  changing the associated business flow.
- Deprecated radio selection was migrated to the current `RadioGroup` model in
  the affected picker/settings pages.
- The app bootstrap and plugin API calls were updated only where compilation
  required it.

These are compatibility patches, not a license to refactor unrelated legacy
code during parity.

## 7. Firebase, notifications, and location ownership

The current bootstrap performs:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await FirebaseMessaging.instance.setAutoInitEnabled(true);
```

After the first frame, the legacy messaging provider requests notification
permission, initializes local notifications, and listens for foreground FCM
messages.

The native projects supply platform permissions and capabilities, but they do
not initialize a second Firebase application. Do not also start a Firebase
service from `core-starter` while the legacy launcher is active.

The same ownership rule applies to location:

- Dart permission checks, current-position requests, and geocoding remain in
  `legacy_epc`;
- Android manifest permissions and iOS usage descriptions remain in
  `platform-app`.

## 8. Android integration

Use the generated `platform-app/android` project as the base. Merge required
legacy application settings into it; do not overwrite the entire directory
with an older Android project.

### Current Android toolchain

- Gradle wrapper: `9.3.1`
- Android Gradle Plugin: `9.1.0`
- Kotlin plugin: `2.4.0`
- Java/Kotlin target: `17`
- `compileSdk`, `targetSdk`, NDK, and minimum SDK: supplied by the current
  Flutter toolchain
- AndroidX: enabled
- multidex: enabled

### Application identity

Both namespace and application ID are:

```kotlin
namespace = "com.gasi.ewf"
applicationId = "com.gasi.ewf"
```

The application label is `e-PeopleCare`, and the legacy launcher icons are
installed in the standard `mipmap-*` folders.

### Manifest permissions

The current manifest declares:

- `ACCESS_COARSE_LOCATION`;
- `ACCESS_FINE_LOCATION`;
- `INTERNET`;
- `POST_NOTIFICATIONS`;
- `VIBRATE`;
- `USE_BIOMETRIC`;
- `CAMERA`.

Do not restore obsolete broad storage permissions or cleartext-traffic flags
unless a verified feature requirement proves they are necessary.

### Main activity and integrity channel

`MainActivity` extends `FlutterFragmentActivity` because biometric plugins may
require a fragment-based activity. It also exposes the legacy
`app_integrity/verifySignature` method channel.

The expected SHA-256 certificate fingerprint is currently hard-coded. Before a
production release, compare it with the Play App Signing certificate, not only
the local upload keystore. A mismatch may be expected when Google Play signs
the distributed APK with a different certificate.

The existing implementation returns `true` on several lookup exceptions. Treat
this as legacy behavior; hardening it is a separate security task and must be
tested carefully to avoid locking out valid installations.

### Release signing

The release build reads:

```text
platform-app/android/key.properties
platform-app/android/app/key.jks
```

Both are ignored by Git and must never be committed or pasted into
documentation. Ensure they are supplied securely in local and CI release
environments. Confirm the alias and certificate before uploading an AAB.

### Android Firebase configuration

`platform-app/android/app/google-services.json` is present for the production
application ID. The current Gradle scripts do not apply the Google Services
Gradle plugin; Firebase is configured explicitly through generated Dart
options. If the Gradle plugin is enabled later, add it deliberately and verify
that its generated values match `firebase_options.dart`.

### Android launch screen

`flutter_native_splash` has been removed. The app currently uses normal Android
launch themes and `launch_background.xml`. Keep this simple during parity and
verify light/dark startup visually on real devices.

The current parent themes are the platform `NoTitleBar` themes. A migration to
an AppCompat theme was discussed but intentionally deferred. Biometric flows
must therefore be included in device smoke testing.

## 9. iOS integration

Use the current generated iOS project as the base. Keep its modern Flutter
application and scene lifecycle. Do not replace `AppDelegate.swift` or
`SceneDelegate.swift` wholesale with files from an older Flutter project.

### Current iOS settings

- Bundle identifier: `com.gasi.ewf`
- Deployment target: iOS `15.0`
- Display name and bundle name: `e-PeopleCare`
- Swift version: `5.0`
- The current Flutter `AppDelegate` and `SceneDelegate` are retained.
- Legacy app icons and launch images have been copied.
- The launch storyboard shows the EPC launch image on a white background.

### Usage descriptions

`Info.plist` currently contains descriptions for:

- location while in use;
- camera access;
- photo library access;
- Face ID.

It also declares `remote-notification` under `UIBackgroundModes`.

### CocoaPods permission configuration

The Podfile retains the current Flutter setup, `use_frameworks!`, the iOS 15
deployment target, and the following permission-handler definition:

```ruby
'PERMISSION_LOCATION_WHENINUSE=1'
```

Add other permission-handler macros only when the Dart code actually requests
those permissions through `permission_handler`.

### iOS Firebase files

The following production Firebase files are present:

```text
platform-app/ios/Runner/GoogleService-Info.plist
platform-app/ios/firebase_app_id_file.json
```

Do not copy their contents into documentation or logs. The Dart bootstrap uses
explicit generated options; if native auto-configuration is expected, make
sure `GoogleService-Info.plist` has Runner target membership and appears in the
Copy Bundle Resources phase.

### Push notification capability: still requires Xcode validation

`Runner.entitlements` currently contains an `aps-environment` entry, but the
Xcode project does not yet show a `CODE_SIGN_ENTITLEMENTS` reference. Merely
placing the file in the directory is not sufficient. Its current value is
`development`; the final signed entitlement must be controlled by the selected
Xcode capability and provisioning profile.

On a macOS machine, open `Runner.xcworkspace` and complete the following:

1. Select the Runner target and the correct Apple developer team.
2. Set the production bundle identifier to `com.gasi.ewf`.
3. Add the **Push Notifications** capability.
4. Add **Background Modes** and enable **Remote notifications**.
5. Confirm Xcode attaches `Runner/Runner.entitlements` to all required build
   configurations.
6. Confirm the provisioning profile contains the APNs entitlement.
7. Confirm the APNs key or certificate is configured for the matching Firebase
   iOS application.
8. Confirm `GoogleService-Info.plist` target membership if native Firebase
   configuration is used.

Do not hard-code `aps-environment` to production by hand. Let signing and the
selected provisioning profile produce the correct entitlement for each build.

## 10. Verification commands

### Dependency resolution

Run dependency resolution from the executable directory. Pub will resolve the
workspace root automatically:

```bash
cd gasi.one.mobile/platform-app
flutter pub get
```

### Static analysis

```bash
cd gasi.one.mobile
flutter analyze plugins/legacy_epc
```

The current legacy analysis has no compile errors, but still reports legacy
lint debt. The 12 October 2026 run reported 1,917 diagnostics, mostly
information-level lints, plus five known warnings:

- two dynamic `IconData` code-point warnings;
- two unused device-integrity local variables;
- one mutable field warning on `MessagePage`.

Do not treat this count as a permanent baseline. Reduce it incrementally, and
never hide a new compile error among existing lints.

### Android debug build

Use the normal build command rather than `--no-pub` so Flutter can resolve Pub
workspace metadata correctly:

```bash
cd gasi.one.mobile/platform-app
flutter build apk --debug
```

Verified result:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

The build succeeds after the `camera` upgrade. It currently emits non-blocking
toolchain/plugin warnings, including plugins that have not yet migrated to
Built-in Kotlin and an Android SDK command-line-tools version warning.

### Android release build

Before publication:

```bash
cd gasi.one.mobile/platform-app
flutter build appbundle --release
```

Then verify the AAB identity, version, signing certificate, Firebase behavior,
and Play pre-launch report. A successful debug APK does not prove release
signing or Play App Signing compatibility.

### iOS build

iOS has not been compiled in the current Linux environment. On macOS:

```bash
cd gasi.one.mobile/platform-app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

Build and archive the Runner target in Xcode after completing signing and
capabilities. Validate push notifications on a physical device.

## 11. Parity smoke-test checklist

Test at least the following on physical Android and iOS devices:

- cold start and warm start;
- legacy splash-to-login and splash-to-home decisions;
- saved tenant/client restoration;
- username/password login;
- OTP request, resend, validation, expiry, and failure paths;
- session restoration after process termination;
- logout and expired-session handling;
- English and Indonesian localization;
- tenant-specific primary and accent colors;
- notification permission, foreground notification, and notification tap;
- FCM token registration after login;
- location permission, current position, and reverse geocoding;
- attendance check-in/check-out;
- system camera and in-app camera flows;
- gallery, file picker, and attachment upload;
- Face ID/Touch ID or Android biometric verification;
- payroll/letter PDF display and download/share flows;
- behavior with permission denied, denied forever, and restricted states;
- Android light/dark launch screen;
- iOS launch screen and app icon;
- offline, timeout, invalid certificate, 401, and server-error behavior.

## 12. Remaining release blockers and deferred work

The following items are intentionally not presented as complete:

1. Build and archive iOS on macOS/Xcode.
2. Attach and validate the iOS entitlements/capabilities.
3. Validate APNs delivery and Firebase Messaging on a physical iPhone.
4. Verify the Play App Signing certificate against the integrity fingerprint.
5. Build and inspect a release AAB with the real release credentials.
6. Run the parity smoke-test checklist on supported OS versions.
7. Decide whether to retain explicit Dart-only Firebase configuration or also
   enable the native Google Services build integration.
8. Decide whether Android themes need AppCompat changes after biometric device
   testing.
9. Address remaining legacy analyzer warnings incrementally.
10. Upgrade or replace `flutter_html` before removing the `html 0.15.6` pin.

## 13. Rules for incremental migration after parity

Once parity is released, migrate one complete feature flow at a time:

```text
route/menu entry
  -> page and widgets
  -> state management
  -> domain contract
  -> repository/data source
  -> session and navigation integration
  -> tests and rollback switch
```

Auth is a reasonable first migration, but it must include tenant selection,
login, OTP/MFA, session restore, user/menu/access-right data, logout, 401
handling, device/FCM registration, and a bridge for legacy pages. Replacing
only the login widget is not a complete auth migration.

While a page remains legacy, it must keep the legacy theme and tenant colors.
New design-system styling should apply only to routes whose ownership has
actually moved.

For the detailed phased approach, see
[Legacy EPC Incremental Migration Roadmap](legacy-migration-roadmap.md).

## 14. Rollback principle

Every migrated feature must have one composition decision that selects either
the legacy or new implementation. Avoid flags scattered across widgets. A
rollback should restore a complete legacy flow without changing persisted
session data or leaving two owners active for the same route.

The parity build itself remains the reference behavior until every critical
legacy flow has a migrated, tested replacement.
