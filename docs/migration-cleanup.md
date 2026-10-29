# Migration cleanup map

| Marker / boundary | Current purpose | Removal condition |
| --- | --- | --- |
| FOUNDATION | Shared startup/contracts/storage/network/UI/request infrastructure | Retained when CRs or legacy are removed |
| COMPAT[INSTALLED-DATA] | Existing preferences/token/license/FCM keys | Explicit supported-device data migration |
| COMPAT[INSTALLED-COMPANY] | Repair installed ewf-client URLs | No supported installation needs the old URL |
| COMPAT[ANDROID-CA] | Existing certificate trust | Separate supported-device trust decision |
| COMPAT[NOTIFICATION-CHANNEL] | Preserve installed notification settings | Explicit notification-channel migration |
| TRANSITION[LEGACY-EPC] | Legacy public module and host dependencies | Last legacy page/startup consumer migrated |
| TRANSITION[LEGACY-UI] | EasyLocalization/AdaptiveTheme/EasyLoading/Phoenix compatibility | All feature consumers replaced or explicitly adopted |
| TRANSITION[LEGACY-AUTH] | Directory/refresh callbacks before Pre-Home cutover | Auth plugin owns transport and legacy callers migrate |
| TRANSITION[LEGACY-PUSH] | Old login/OTP token adapter | Last consumer uses injected PushTokenProvider |
| TRANSITION[LEGACY-BUSINESS-CONTEXT] | Installed-state and Config mapping/provider | Home/settings/business consumers use typed contracts |
| TRANSITION[LEGACY-ROUTES] | Existing menu routes | Last route owned by a migrated plugin |
| TRANSITION[LEGACY-UPDATE] | Existing update/device-policy dialogs | Equivalent platform service verified |

On main, Company/Login/recovery/MFA/local verification and all attendance pages
are still legacy. Do not delete them when committing prerequisite work. The CR
worktree preserves the migration implementation and its dedicated tests.

Generic StartupGate/AppEntryPage, PluginRouteBridge, PickerRegistry, core
contracts/services, and the Attendance request foundation remain after cutover.
See [foundation and CR boundaries](mobile-cr-foundation.md) for the scope split.
