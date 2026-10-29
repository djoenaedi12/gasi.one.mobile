# Platform startup foundation

`platform-app` owns bootstrap, shared services, the only MaterialApp, theme,
localization, navigator, and the generic entry gate. It does not call legacy
`main()` or construct EWorkflowApp. Auth pages and attendance feature routes
remain legacy on main. The five-second splash and migrated auth UI belong to
`cr/mobile-pre-home-attendance-requests`.

## Runtime ownership

| Concern | Owner |
| --- | --- |
| Bootstrap, initialization/retry, disposal | platform `StartupGate` / `AppDependencies` |
| Firebase options, native configuration, certificate, orientation | platform |
| Runtime metadata/device integrity and device ID | core-starter `AppRuntimeService` |
| Firebase/local notifications, token refresh stream | core-starter, composed once by platform |
| Installed token keys and preferences | core-starter storage adapters over the existing backend |
| AuthStatus/AuthRestorer/AuthProvider | core-api contracts |
| Restoration orchestration and generic error/retry UI | platform `AppEntryPage` |
| Company/Login/MFA/recovery/local verification on main | legacy pages via auth registration skeleton |
| User/license/menu/device/context loading | business-context plugin |
| Typed active employee/company/access/session/timezone | core-api context, adapted at composition boundary |
| Home, business routes, version/update policies | legacy module |
| Plugin page routing before fallback | platform `PluginRouteBridge` |

## Startup and lifecycle

```text
main -> bootstrap -> StartupGate -> AppDependencies.initialize
  -> orientation, localization, certificate
  -> installed preferences, saved locale/theme, runtime metadata
  -> shared FirebaseNotificationService initialization
  -> GasioneApp -> Phoenix shell -> AppEntryPage
     -> installed company/session compatibility restore
     -> BusinessContextPlugin.load
     -> legacy Company/Login/local verification/Home destination
```

StartupGate shares one initialization attempt across rebuilds and concurrent
retry, sanitizes initialization failures, and disposes completed dependencies
if startup is abandoned. GasioneApp disposes dependencies once on final removal.
Phoenix restarts shell/context while keeping platform services alive. Notification
permission is requested once per dependency lifetime; listeners are cancelled on
disposal. Existing channel identity, asset keys, certificate, and device ID are
retained.

The entry gate restores once per mount, sanitizes failures, and retries without
recreating platform services. It supplies no feature-specific delay or artwork.

## Compatibility and session boundaries

The platform imports only `package:epeoplecare/legacy_epc.dart`; core/new plugins
cannot import legacy implementations. Legacy pages receive runtime metadata and
push access from the host, including their token-only FirebaseMessagingProvider
adapter. They do not initialize a second notification service.

Main keeps one installed preference/token backend. InstalledTokenStorage reads
`access_token` and `refresh_token`; SessionStore guards request generations.
An injected tenant refresh callback keeps endpoint specifics outside the generic
HTTP interceptor. Legacy company URL repair remains available for installed
`ewf-client` tenant addresses.

BusinessContextPlugin exposes typed active employee context and context changes.
Its unfinished loads cannot reinstall context after clear/new load. While main
still uses old login/settings, LegacyEpcModule also exposes that contract over
Config at the composition boundary. Platform navigation synchronizes context
changes and invalidates the shared client's previous session generation. HTTP
expiry clears business context and returns to the registered legacy login page.

Firebase tap events are available through the notification service. Payload
mapping to migrated attendance details belongs to the Attendance CR.

## Validation

Run `bash tool/verify.sh`, or `bash tool/verify.sh --format --apk` to format and
also produce the Android debug APK. Modular packages and the new legacy
integration surface are analyzed separately from existing legacy lint debt.
Tests cover startup abandon/retry/disposal, soft restart, restore/retry, route
fallback, installed storage, request generations, context loading, and request
foundation behavior. Physical device and signed Store release checks remain in
[the integration runbook](legacy-integration.md).
