# Mobile foundation dan pemisahan CR

Main menampung prerequisite bersama untuk Technical Specification Mobile
Pre-Home dan Mobile Attendance Requests versi 0.2. Satu branch
`cr/mobile-pre-home-attendance-requests` menampung kedua scope CR dan memakai
commit prerequisite pada main sebagai base.

## Ownership

| Area | Main / prerequisite | Combined CR |
| --- | --- | --- |
| Entry | Bootstrap, StartupGate, generic restore/retry, lifecycle | Splash lima detik dan entry behavior spesifik |
| Auth | AuthProvider/AuthRestorer, storage/session, skeleton registration | Company/history, login/account, recovery, MFA, local verification UI dan migrasinya |
| Business context | Typed employee/company/access/session/timezone, loader, adapter | Integrasi handoff flow Pre-Home baru |
| Design system | Token, input/button, loading/error/empty/retry/dialog, typed picker registry | Copy dan composition spesifik feature |
| Attendance | Skeleton/package/localization, request foundation | WFH, Flex Hour, Correction beserta pre-form |
| Workflow | Shared repository contract/transport, metadata/history/executor/media/custom fields | Payload, eligibility, validation dan action mapping spesifik feature |
| Request workspace | Submission/Approval, swipe, retained mode state, search/pagination, filter/sort/summary slots | Card, filter/sort, summary/detail/form content |
| Multiple approval | Long press, checkbox/count, Done/Back, select loaded rows, partial results/retry | Eligibility dan payload tiap feature |
| Existing routes | Plugin bridge dan legacy fallback | Cutover tiga route, notification mapping dan downstream adapter |

## Coverage prerequisite

| Specification | Prerequisite teknis | Implementasi |
| --- | --- | --- |
| Pre-Home 1–4 | Modular host/core/plugin skeleton; legacy tetap runnable | Workspace, `AuthPlugin`, `BusinessContextPlugin`, `LegacyEpcModule` |
| Pre-Home 5–6 | Runtime/Firebase/preferences/secure storage/HTTP/localization/theme; auth/session seam | `AppDependencies`, core-starter services/storage, core-api auth/context contracts |
| Pre-Home 7–8 | Generic UI, startup/route/lifecycle/failure mapping dan test | core-ui, `StartupGate`, `AppEntryPage`, `PluginRouteBridge`, foundation tests |
| Attendance 1–3 | Foundation, typed active context/shared client, skeleton/registration | core-api context, shared `ApiClient`, `AttendancePlugin` |
| Attendance 4 | Shared workflow/create/update/draft/submit/action/history/executor/media/custom-field contracts dan adapters | core-api requests; Attendance `foundation/data` |
| Attendance 5–6 | Workspace, retained mode state, generic modal/detail/form and content slots | `RequestWorkspace`, controllers, `request_components.dart` |
| Attendance 7–8 | Selection/bulk plus feature builders/eligibility/action extension points | `RequestSelectionController`, workspace callbacks |
| Attendance 9 | Employee/subordinate/location/shift/file picker contract dan registry; reference/custom-field services | `RequestPickerKeys`, `PickerRegistry`, Attendance pickers/services/form sections |
| Attendance 12 | Existing Home/check-in/log/record/notification tetap dimiliki legacy | Tidak ada route attendance yang dialihkan pada main |

Approval Business Specification/prototype (Pre-Home 9; Attendance 10) dan
ketersediaan endpoint existing (Pre-Home 10; Attendance 11) adalah dependency
eksternal. Kode foundation tidak dapat memberikan approval atau membuktikan
ketersediaan backend tanpa environment dan akses tim terkait.

## Integration contract

`RequestApi` menerima shared `ApiClient`, `BusinessContextProvider`, dan metadata
header dari composition root. Plugin tidak membaca Config/token legacy. Respons
dari company/sesi lama ditolak; workspace membersihkan data saat context berubah.
Provider transitional ada pada public legacy boundary sampai CR memigrasikan auth.

Feature membuat `ApiRequestRepository<T, Draft>` dengan endpoint, decode,
encodeDraft, encodeQuery, dan bila diperlukan encodeWorkflow. Shared adapter
menggunakan pagination existing (`number`, `total_pages`, `total_elements`),
`/approval/pending`, `/approval`, history, dan `/revoked-request`. Tidak ada
endpoint bulk baru. Create/update hanya menerima draft/submit; aksi lain memakai
workflow command. Feature tetap menentukan business eligibility dan permission.

`RequestWorkspace` menerima controller Submission dan Approval terpisah.
Feature memiliki lifecycle controller. Card/modal/section diberikan sebagai
builder, bukan konfigurasi flag visual tiap field. Filter/sort modal mengembalikan
value bertipe melalui Navigator.pop. Long press memulai selection pada Approval.
Select all mencakup row eligible yang sudah dimuat; UI menyebut batas ini secara
eksplisit. Bulk berjalan berurutan dan tidak mengulang row yang sudah berhasil.

## Local handoff

- Main working directory: `gasi.one.mobile`.
- Combined CR worktree: `../.worktrees/mobile-cr`.
- Backup awal: `/tmp/gasi-mobile-branch-split-20261029`.

Prerequisite disimpan sebagai commit tersendiri di main. Branch CR dimulai
dari commit foundation tersebut; perubahan CR existing tetap berada di worktree
CR sebagai perubahan yang belum di-commit. Lihat dokumen handoff di worktree CR
untuk status dan batas scope pekerjaan CR.

## Verification

`bash tool/verify.sh` melakukan dependency resolution offline, format check,
architecture check, strict analysis modular packages, dan unit/widget tests.
`--format` memformat file foundation sebelum menjalankan pemeriksaan tersebut.
Lint existing dalam keseluruhan legacy package tidak disembunyikan dengan
perubahan analyzer global. Device/native smoke test dan validasi endpoint live
tetap harus dilakukan sebelum release, termasuk installed session, local
verification, FCM, file access, dan downstream attendance.

Validation pada 29 Oktober 2026: architecture check, strict analyzer seluruh
paket modular beserta integration surface legacy, dan 93 unit/widget tests lulus.
Build `platform-app` APK debug juga berhasil. Validasi backend live dan perangkat
fisik tetap diperlukan sebelum release. Petunjuk branch CR tersedia pada
`../.worktrees/mobile-cr/docs/cr-worktree-handoff.md`.
