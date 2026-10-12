# Legacy EPC Incremental Migration Roadmap

This document defines how the EPC application will move from
`plugins/legacy_epc` into the new GASI One architecture without a big-bang
rewrite. It starts after the legacy code has been integrated into
`platform-app`, and it remains valid until the legacy runtime can be removed.

The approach is a strangler migration: the existing application stays usable
while ownership of complete feature flows moves to new packages one at a time.

For parity setup, native configuration, dependency compatibility, and release
verification, see the
[Legacy EPC Integration Runbook](legacy-integration.md). For the target plugin
structure and dependency rules, see the
[Plugin Development Guide](feature-development.md).

Last updated: 12 October 2026.

## 1. Current status

The repository is currently at **Phase 0: parity validation**.

Implemented:

- `platform-app` is the deployable application.
- `platform-app` delegates to `package:epeoplecare/main.dart`.
- `plugins/legacy_epc` owns the current application shell, UI, session,
  Firebase bootstrap, navigation, and business modules.
- Legacy assets and production native identifiers have been moved into
  `platform-app`.
- The legacy source compiles with the current dependency set.
- Android debug APK generation succeeds.

Not yet sufficient to close Phase 0:

- Android release AAB and production signing validation;
- Play App Signing certificate validation for the integrity check;
- iOS signing, entitlements, capabilities, archive, and physical-device tests;
- full Android and iOS parity smoke testing;
- internal or staged release validation.

No new production auth or business plugin is currently active. Any previous
sample auth/catalog implementation must be treated only as a structural
reference, not as reusable EPC production logic.

## 2. Why the migration must be incremental

The legacy system has several runtime couplings that make page-by-page copying
unsafe unless boundaries are introduced first:

- `main.dart` performs Firebase, preferences, certificates, package/device
  information, theme, localization, loading overlay, and application startup.
- The splash flow decides its destination from `Config.client`,
  `Config.session`, `Config.user`, and the configured verification method.
- Authentication depends on tenant/client selection, client credentials,
  device information, FCM token registration, OTP/MFA, and local verification.
- Session data is persisted through `SharedPreferences` and mirrored into
  global `Config` values.
- `Repository()` behaves as a service locator for most legacy modules and
  derives base URL and token state from legacy providers.
- Legacy 401 handling uses a global navigator and directly redirects to the
  old login flow.
- Menus and access checks are derived from legacy user and role data.
- Many pages navigate directly using `Navigator.push` and
  `MaterialPageRoute`.
- Tenant colors are stored in `Config.DEFAULT_COLOR` and
  `Config.DEFAULT_ACCENT_COLOR`.
- Attendance combines location, camera, permissions, device state, schedules,
  and native configuration.

As a result, replacing only a visible page may silently break session restore,
API headers, tenant selection, access rights, notification navigation, or
logout behavior.

## 3. Migration principles

### 3.1 One authoritative owner per concern

At any point in a build, there must be exactly one authoritative owner for:

- the application shell;
- session and credential lifecycle;
- Firebase initialization;
- each top-level route;
- logout and session-expiry decisions;
- each menu/access-right decision;
- any persisted key being actively migrated.

Legacy and new implementations may coexist, but they must not both make final
decisions for the same concern.

### 3.2 Migrate vertical slices, not directory layers

A completed migration unit includes the entire user flow:

```text
route or menu entry
  -> page and widgets
  -> Cubit/state
  -> domain entity and repository contract
  -> repository implementation
  -> remote/local data source and API mapping
  -> session, permission, and navigation integration
  -> automated tests and rollback decision
```

Avoid migrating all models first, then all repositories, then all pages. That
creates a long period in which nothing is releasable and rollback is unclear.

### 3.3 Preserve legacy appearance until route ownership moves

An unmigrated page must keep the legacy theme, tenant colors, copy, layout, and
interaction behavior. The new design system applies only to routes that have
explicitly moved to a new owner.

After the new shell becomes the root, the visual boundary should be explicit:

```text
Application shell
├── migrated route -> core-ui and the new design system
└── legacy route   -> LegacyPageShell and legacy tenant colors
```

The compatibility shell may internally read `Config` while the legacy runtime
exists. New feature presentation code must not do so.

### 3.4 Dependencies point toward stable contracts

New feature packages must not import `package:epeoplecare/...`.

```text
new feature ---------> stable contract
legacy adapter ------> stable contract
platform-app --------> composes both implementations
```

Imports from `epeoplecare` are allowed only inside clearly named compatibility
adapters or the platform composition boundary. They are forbidden in new
domain, data, and presentation layers.

### 3.5 Compatibility bridges are temporary and measurable

A bridge must have:

- a named owner;
- a list of legacy fields/keys it synchronizes;
- tests for both directions where applicable;
- a removal condition;
- telemetry or logs that do not expose credentials or personal data.

Do not create an open-ended adapter that becomes a second permanent service
locator.

### 3.6 Every cutover has one rollback switch

Use one composition decision per migrated flow:

```text
legacy owner <---- one route/feature decision ----> new owner
```

Do not scatter feature flags throughout widgets, repositories, and API clients.
The rollback path must restore the complete legacy flow, not a mixture of old
and new screens.

## 4. Standard workflow for every migration slice

Every feature follows the same lifecycle.

### Step 1: inventory

Record:

- route names and navigation entry points;
- menus, roles, access-right checks, and tenant conditions;
- pages, dialogs, pickers, and reusable widgets;
- endpoints, headers, request/response payloads, and error behavior;
- local storage keys and side effects;
- deep links and notification payload routes;
- permissions and native capabilities;
- analytics or operational events;
- dependencies on other legacy modules.

### Step 2: characterize legacy behavior

Add tests or fixtures before changing ownership. Cover successful behavior and
important failure paths. Scrub tokens, credentials, tenant secrets, employee
data, and production identifiers from fixtures.

### Step 3: define the boundary

Create domain entities and repository contracts that represent the business
capability, not the legacy JSON shape. Put cross-plugin contracts in
`core-api` only when they are genuinely stable and platform-wide.

### Step 4: implement the new vertical slice

Follow the package flow documented in `feature-development.md`:

```text
Page -> Cubit -> repository contract -> repository implementation
     -> data source -> core-starter infrastructure
```

### Step 5: integrate without changing the legacy owner

Register the new implementation behind a single composition decision. At this
stage it may be test-only, internal-only, or shadow-tested, but the production
route still belongs to legacy.

### Step 6: compare

Run legacy and new behavior against equivalent test data. Compare:

- API inputs and meaningful outputs;
- authorization decisions;
- navigation results;
- persisted state and side effects;
- loading, empty, error, retry, and offline behavior;
- localization and visual acceptance criteria.

### Step 7: cut over one owner

Move the route/menu owner in one composition change. Do not delete the legacy
implementation in the same release.

### Step 8: stabilize, then remove

Use internal testing and staged rollout. Remove the legacy slice and its bridge
only after the agreed stabilization window and rollback review.

## 5. Phase 0 — parity release

### Objective

Publish the integrated legacy behavior from `platform-app` without redesign or
route migration.

### Required work

Complete every blocker in `legacy-integration.md`, including:

- release version and signing validation;
- Android AAB generation and certificate verification;
- iOS signing, Firebase/APNs capabilities, archive, and physical-device tests;
- parity smoke testing for critical legacy flows;
- internal/staged distribution and rollback preparation.

### Exit criteria

- Store-ready artifacts originate from `platform-app`.
- Critical behavior matches the previous production application.
- Firebase, notifications, location, camera, biometrics, and attachments work
  on supported physical devices.
- No production route is owned by a sample or incomplete plugin.
- A known-good rollback artifact remains available.

Do not begin a production route cutover before this phase is complete. Boundary
preparation and characterization tests may start in parallel if they do not
change runtime ownership.

## 6. Phase 1 — introduce legacy seams without behavior changes

### Objective

Make the legacy runtime composable from `platform-app` without changing what
users see.

### Proposed seams

Introduce small façades around existing behavior:

```text
LegacyEpcBootstrap
  Firebase, certificates, preferences, package/device initialization

LegacyEpcApp
  controlled entry point around the current EWorkflowApp

LegacyRuntimeState
  controlled read/write access to required Config values

LegacySessionGateway
  read/write/clear access to current session persistence

LegacyRouteOverrides
  injectable builders for routes selected for migration

LegacyTheme
  legacy ThemeData and tenant colors for the compatibility subtree
```

The first implementation behind these façades may still call `Config`,
`Repository()`, and existing providers. Their purpose is to contain legacy
coupling, not to hide a rewrite inside Phase 1.

### Characterization tests

Prioritize tests for:

- splash destination decisions;
- tenant/client restoration and base URL selection;
- session save, restore, and clear behavior;
- API authorization headers;
- login success and failure;
- OTP required, resend, validation, expiry, and lockout;
- 401 handling and logout;
- user, menu, role, and access-right restoration;
- tenant theme colors;
- notification route resolution.

### Exit criteria

- Visible behavior remains unchanged.
- Bootstrap can be invoked through one façade.
- Legacy session state is accessible through one gateway.
- A top-level route can be overridden from composition without a new plugin
  importing legacy internals.
- Tests protect the startup and session behaviors needed by the auth migration.

## 7. Phase 2 — migrate EPC authentication

Auth is the recommended first major migration because it establishes the
session boundary needed by every later feature. It is not merely a replacement
login page.

### Production auth scope

The first production auth cutover must cover:

- tenant/client discovery, selection, and persistence;
- username/password login;
- client credentials and required device headers;
- OTP/MFA initiation, verification, resend, expiry, and lockout;
- session persistence and cold-start restoration;
- refresh-token behavior if supported by the EPC contract;
- current user, roles, menus, and access rights required by legacy pages;
- post-login verification and local-auth decision;
- logout and account switching where required;
- session expiry and 401 coordination;
- device ID and FCM token registration tied to login.

Forgot-password and change-password flows may be separate auth milestones, but
their inclusion or deferral must be explicit before cutover.

### Implementation sequence

1. Capture sanitized EPC request/response fixtures and error cases.
2. Define auth, tenant, session, user, menu, and access-right domain models.
3. Define repository contracts without importing legacy types.
4. Implement EPC remote data sources with the shared `ApiClient`.
5. Implement the authoritative session store and token lifecycle.
6. Implement auth state/Cubits for startup, tenant, login, OTP, and logout.
7. Add a `LegacySessionBridge` at the composition boundary.
8. Synchronize only the legacy state still required by unmigrated modules.
9. Integrate the new auth pages through `LegacyRouteOverrides`.
10. Move logout and 401 behavior to one session coordinator.
11. Shadow-test and then cut over the complete auth route group.

### Legacy session bridge

Conceptually:

```text
New EPC auth
├── SessionStore                 # authoritative owner
├── Auth state/Cubits
└── LegacySessionBridge
    ├── writes required compatibility SharedPreferences keys
    ├── updates Config.client/session/user
    ├── restores menu/access-right data needed by legacy pages
    └── refreshes legacy repository configuration
```

The bridge remains active while legacy pages depend on `Config` or
`Repository()`. Do not delete old persistence keys immediately after the new
login UI appears.

### Auth cutover and rollback

Use one composition decision:

```text
useNewAuth = false -> complete legacy startup/auth flow
useNewAuth = true  -> new auth flow plus LegacySessionBridge
```

The flag name and mechanism may differ, but there must not be separate switches
for login, OTP, session restore, logout, and 401 behavior.

### Exit criteria

- Cold start, restore, login, OTP, verification, logout, switch-account where
  applicable, and 401 flows pass.
- All remaining legacy modules can call authenticated APIs after new login.
- Legacy menus and permissions remain correct.
- The new session store is the only authoritative credential owner.
- Old async login/refresh operations cannot overwrite a newer session.
- Tokens and credentials are absent from logs, fixtures, and error messages.
- Rollback restores the complete legacy auth flow.

## 8. Phase 3 — move the application shell and router

Start this phase only after new auth is stable.

### Objective

Make `platform-app` own one application shell, router, theme preference,
localization composition, plugin registry, and route guards while continuing to
host unmigrated legacy pages.

The new shell files that previously existed as examples may be recreated from
the current platform architecture, but they must not reintroduce sample
business dependencies.

### Required structure

- one `MaterialApp.router`;
- one router assembled from active route owners;
- one session-aware redirect policy;
- one plugin registry/composition root;
- one app-level localization composition;
- a `LegacyPageShell` for unmigrated routes;
- a controlled legacy navigator only where nested legacy navigation is still
  necessary.

### Route ownership table

Maintain an explicit table during this phase:

| Route group | Initial owner | Target owner |
| --- | --- | --- |
| startup, tenant, login, OTP | `legacy_epc` | new EPC auth package |
| migrated business route | `legacy_epc` | owning feature package |
| unmigrated business route | `legacy_epc` | `legacy_epc` |
| global unknown/error route | legacy shell | `platform-app` |

One route pattern must never be registered by two owners. Preserve paths used
by server menus, notification payloads, deep links, and external bookmarks, or
provide a tested compatibility mapping.

### Legacy page shell responsibilities

The wrapper for unmigrated routes may provide:

- legacy `ThemeData` and tenant colors;
- legacy localization delegates still required by those pages;
- loading/error overlays not yet migrated;
- compatibility navigation and navigator keys;
- adapters for session, permission, or notification navigation.

### Exit criteria

- Only one top-level `MaterialApp.router` exists.
- Every top-level route has one documented owner.
- New auth protects both legacy and migrated routes.
- Back navigation, restoration, deep links, and notification navigation pass.
- Legacy pages retain their existing appearance and behavior.
- Disabling a migrated route returns ownership cleanly to its rollback path.

## 9. Phase 4 — prove the module pattern with a low-risk pilot

Before migrating complex modules, complete one small production vertical slice
to validate contracts, packaging, routing, tests, rollout, and rollback.

### Candidate characteristics

Prefer a feature that is:

- read-only or low-mutation;
- limited in route count;
- not device-sensitive;
- not central to login/session lifecycle;
- backed by a stable EPC endpoint;
- easy to compare with legacy behavior.

A payroll/letter read-only flow may be suitable, subject to business
criticality, privacy requirements, and API stability. Choose based on risk, not
only source-file count.

### Pilot exit criteria

- The feature is a valid package following `feature-development.md`.
- It imports no legacy package.
- The new route is production-owned by the new feature package.
- Legacy and new authorization semantics match.
- Loading, empty, error, retry, offline, and unauthorized behavior are tested.
- Internal/staged rollout completes without a parity regression.
- The rollback decision works without a data migration reversal.
- Lessons are incorporated into the standard feature template/checklist.

## 10. Phase 5 — migrate business modules by vertical slice

An indicative risk-based order is:

1. read-only/reference flows;
2. letter or a simple workflow/CRUD flow;
3. overtime and leave;
4. benefit, loan, cash advance, and business trip;
5. tasks, approvals, and reusable workflow behavior;
6. attendance, location, camera, and device-sensitive flows.

This is not a fixed business commitment. Priority may change, but every module
must satisfy the standard workflow and definition of done.

### Module definition of done

A module is migrated only when:

- all in-scope list, detail, form, dialog, and picker paths have moved;
- its package imports no `epeoplecare` code;
- its data flow follows the target package architecture;
- transport models do not leak into domain or presentation;
- API failures become typed failures;
- loading, empty, error, retry, validation, and unauthorized states are tested;
- menu visibility and access decisions are equivalent or stricter;
- deep links and notification navigation are handled;
- side effects and persisted data are documented;
- the route has exactly one production owner;
- monitoring and error reporting do not expose sensitive data;
- rollback remains available through the stabilization window;
- legacy source removal happens only after stabilization.

### Attendance is intentionally late

Attendance should not be used as the first module migration. It combines:

- fine/coarse location and denied-permission states;
- geocoding and network fallbacks;
- system and in-app camera behavior;
- schedules and attendance business rules;
- device/integrity checks;
- Android/iOS native configuration;
- possible anti-fraud controls.

Before its cutover, location, media, permission, device, and time abstractions
must already be proven by simpler production features.

## 11. Phase 6 — extract shared capabilities when proven

Do not move every legacy helper into a core package at the beginning. Extract a
shared capability only after at least two new features need a stable version of
the same contract.

Likely candidates include:

- file/media upload and download;
- employee/reference pickers;
- workflow and approvals;
- custom fields;
- notification route resolution;
- access-right evaluation;
- tenant/client context;
- timezone and date formatting;
- permission and device capability wrappers.

Placement rules:

| Concern | Preferred package |
| --- | --- |
| stable cross-plugin contract/value type | `core-api` |
| network, storage, device, or platform implementation | `core-starter` |
| generic design token or reusable presentation component | `core-ui` |
| business-specific rule or UI | owning feature package |
| temporary legacy translation | compatibility adapter/composition boundary |

Avoid turning core packages into a collection of copied legacy utilities.

## 12. Phase 7 — remove the legacy runtime

`legacy_epc` may be removed only when all of the following are true:

- no production route is owned by `legacy_epc`;
- no new page reads `Config`;
- no runtime code uses legacy `Repository()` or `ApiProvider`;
- no session compatibility key is still required;
- no deep link, notification, or server menu points to a legacy-only route;
- no legacy theme/localization subtree is rendered;
- Firebase, notification, location, and device ownership have moved explicitly;
- compatibility adapters report no remaining consumers;
- a release without the legacy runtime has passed the stabilization window.

Removal sequence:

1. Disable all legacy route ownership in an internal build.
2. Run full regression and compare artifact/plugin dependencies.
3. Remove the `epeoplecare` dependency from `platform-app`.
4. Remove `plugins/legacy_epc` from the workspace.
5. Remove session, route, theme, and runtime compatibility bridges.
6. Remove native plugins and permissions that are genuinely unused.
7. Rebuild Android and iOS Store artifacts.
8. Complete staged rollout before declaring the migration finished.

## 13. Testing and release strategy

Use layered verification:

- characterization tests for legacy behavior being replaced;
- model parsing and mapping tests;
- repository and data-source tests;
- Cubit state-transition tests;
- widget and navigation tests;
- API fixture/contract tests;
- integration tests for auth and critical journeys;
- physical-device tests for FCM, camera, location, biometrics, and file access;
- internal testing and staged production rollout.

Keep releases narrow. Do not combine all of the following in one release:

- a Flutter or dependency-stack upgrade;
- the application-shell cutover;
- the auth cutover;
- several module redesigns;
- native signing or Firebase migration.

If a prerequisite dependency upgrade is required, stabilize it in a parity
release before changing route ownership.

## 14. Tracking model

Maintain one ownership register as the source of truth. A suggested format is:

| Capability/route | Current owner | State | New owner | Rollback | Removal gate |
| --- | --- | --- | --- | --- | --- |
| bootstrap | legacy | parity-validation | platform | previous release | shell stable |
| tenant/auth/OTP | legacy | planned | EPC auth | legacy auth | auth stabilization |
| `/module/leave` | legacy | backlog | leave plugin | legacy route | route stabilization |
| `/module/attendance` | legacy | backlog | attendance plugin | legacy route | device validation |

Recommended states:

```text
legacy
characterized
in-development
shadow-tested
cutover-ready
new-owner
stabilizing
legacy-removed
```

State changes should be tied to evidence: tests, build results, device results,
rollout metrics, and an owner—not only a percentage estimate.

## 15. Decision record required for each cutover

Before changing production ownership, record:

- scope and intentionally deferred behavior;
- old and new owner;
- route/menu/deep-link mapping;
- session and persistence impact;
- permission/native impact;
- API contract and failure mapping;
- automated and manual evidence;
- feature decision/flag location;
- rollback instructions;
- stabilization duration and removal gate;
- responsible engineer/team.

This can be a pull-request section, issue template, or architecture decision
record, as long as it remains discoverable.

## 16. Guardrails

- Do not redesign a page outside the active migration scope.
- Do not let new feature code import `epeoplecare`.
- Do not keep two authoritative token stores.
- Do not initialize Firebase twice.
- Do not register the same route pattern in two owners.
- Do not change paths used by server menus or notifications without a mapping.
- Do not delete legacy code in the first cutover release.
- Do not combine a compatibility dependency patch with unrelated business
  behavior changes.
- Do not store production tokens, credentials, keystore data, employee data, or
  unsanitized payloads in fixtures or Git.
- Do not call a module migrated when only its list page has moved.
- Do not move a helper into core merely because it is used extensively by
  legacy code.
- Do not remove a compatibility bridge without proving it has no consumers.

The migration is complete only when the new application owns every production
route and runtime concern, and a stabilized Store release no longer packages
`legacy_epc`.
