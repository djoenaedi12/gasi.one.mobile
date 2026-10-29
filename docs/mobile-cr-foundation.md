# Mobile foundation dan pemisahan CR

Main hanya memuat `plugins/legacy_epc`. Seluruh paket dan wiring plugin baru,
termasuk auth, business_context, dan attendance, berada pada branch
`cr/mobile-pre-home-attendance-requests`.

## Pembagian

| Area | Main | CR |
| --- | --- | --- |
| Platform | Bootstrap, StartupGate, generic entry/route bridge, lifecycle, theme/localization | Wiring dan cutover plugin baru, Splash dan entry flow spesifik |
| core-api | Auth/context, plugin extension points, request/workflow/picker contracts | Penggunaan kontrak oleh plugin |
| core-starter | HTTP/session/storage/services dan generic request data adapters | Endpoint/payload/eligibility spesifik feature |
| core-ui | Design system, picker registry, generic request controller/workspace/modal/form/selection | Composition dan konten UI feature |
| plugins | legacy_epc dengan existing auth/Home/attendance/context restore | auth, business_context, attendance beserta skeleton dan registration |

Request transport ada di `core-starter/lib/src/requests/data`. Request
controllers, localization, workspace, selection, picker, dan form ada di
`core-ui/lib/src/requests`. Keduanya mengikuti dependency rule core; core-ui
tidak bergantung pada core-starter. Plugin mengonsumsi kontrak core-api dan
infrastruktur core melalui composition root.

Skeleton dan aktivasi plugin yang disebut sebagai prerequisite pada spesifikasi
ikut dikerjakan di CR sesuai pembagian branch ini. Main menyediakan fondasi
generiknya. Approval prototype/Business Specification dan ketersediaan backend
merupakan dependency eksternal.

## Runtime main

Platform mendelegasikan restore user/license/parameter/device/manager kepada
public legacy boundary. Existing Company/Login/verification dan Home tetap
berjalan tanpa dependency pada plugin baru. Generic AuthRestorer dan
BusinessContextProvider tetap tersedia di core-api.

## Verification dan lokasi kerja

Jalankan `bash tool/verify.sh`; `--format --apk` juga memformat dan membangun
Android debug APK. Tool menemukan plugin baru secara otomatis di branch CR;
main memeriksa core/platform dan integration surface legacy.

Main: `gasi.one.mobile`. Worktree CR: `../.worktrees/mobile-cr`.
Tidak ada push otomatis. Validasi backend live, perangkat fisik, dan signing
release tetap diperlukan sebelum release.

Verifikasi koreksi pembagian pada 29 Oktober 2026: 88 test main, strict analyzer,
architecture check, dan build APK debug lulus dengan plugins/legacy_epc sebagai
satu-satunya plugin pada main.
