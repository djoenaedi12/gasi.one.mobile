# Review kesiapan mobile untuk Pre-Home dan Attendance Requests

Tanggal: 3 November 2026. Lingkup: review kode, kesiapan pengembangan, gap CR,
dan pembagian pekerjaan generic/main versus feature/CR. Bagian review merekam
kondisi sebelum implementasi; tindak lanjut main dicatat terpisah.

## Tindak lanjut implementasi main

Setelah review, scope implementasi dibatasi ke main atas arahan pengguna.
Baseline dan temuan di bawah tetap merupakan catatan kondisi saat review.

| Temuan | Implementasi main | Sisa di CR |
| --- | --- | --- |
| R1 | Fallback endpoint/token format dihapus; refresh hanya melalui TokenRefresher yang diinjeksikan. 401 tanpa strategy mengakhiri sesi melalui callback existing; kegagalan network refresh tidak menghapus sesi. | Implementasi OAuth tenant dan expiry wiring auth baru |
| R2/R3 | Tidak mengubah flow auth CR | Local verification dan guard login/OTP |
| R4 | RequestPickerContributor, PickerScope, serta PluginComposition tersedia dan dipasang pada host main | Menghapus registrasi/re-export generic dari AttendancePlugin ketika CR dilanjutkan |
| R5 | Coordinator menerima initial/warm interaction, menunggu readiness setelah verifikasi, memvalidasi sesi/company/registered route, melakukan dedup dan disposal | Resolver payload serta tujuan detail WFH/Flex/Correction |
| R6 | Workspace dan reference picker memakai ListView.builder; regression test memakai 3.000 item | Tidak ada perubahan UI feature pada tahap ini |
| R7 | Logging default nonaktif; logger yang diaktifkan hanya menulis method/status/error type | Tidak memerlukan perubahan feature |
| R8 | RequestRetryPolicy eksplisit untuk operasi baca; revoke memakai never; cancellation diperiksa sebelum retry | Tidak memerlukan perubahan endpoint backend |

Panduan integrasi dan batas compatibility ada di
[Main readiness foundation](main-readiness-foundation.md). Worktree CR tidak
diubah dan belum disinkronkan dengan hasil implementasi main.

Verifikasi implementasi main pada 3 November 2026: format dan architecture check
lulus, strict analyzer tanpa issue, seluruh 198 test lulus (core-api 8,
core-starter 64, core-ui 81, platform-app 45), serta build Android debug APK
berhasil. Backend live, perangkat fisik, dan iOS belum diverifikasi pada tahap
ini. Perubahan masih berada di working tree main, belum di-commit/push.

## Penilaian

Fondasi sudah cukup untuk melanjutkan pengembangan modular secara bertahap.
Pemisahan core-api, core-starter, core-ui, platform-app, dan plugin membantu
penambahan fitur serta pengujian terpisah. Belum cukup untuk menyatakan CR siap
release atau seluruh aplikasi sudah mudah dipelihara: fitur attendance aktif
masih legacy, beberapa integrasi generic belum terpasang, dan Pre-Home CR belum
memenuhi seluruh flow spesifikasi.

Scalability yang dinilai adalah pertumbuhan fitur/tim dan data pada aplikasi
mobile. Kapasitas backend, jumlah pengguna bersamaan, waktu respons produksi,
dan performa perangkat tidak diukur dalam review ini.

## Baseline dan verifikasi

- Main: `gasi.one.mobile`, HEAD `08d5e74`, termasuk perubahan lokal tracked dan
  untracked yang sudah ada saat review.
- CR: `../.worktrees/mobile-cr`, branch
  `cr/mobile-pre-home-attendance-requests`, HEAD `80d07f6`, termasuk perubahan
  lokal yang belum di-commit. Implementasi auth/business context ada di sini.
- Acuan: dua Technical Specification versi 0.2 di `../gasi.one.cr` untuk Mobile
  Pre-Home dan Mobile Attendance Requests. Keduanya berstatus Draft. Business
  Specification final dan prototype lengkap tidak tersedia sebagai acuan lokal
  dalam review ini; kesesuaian visual dan acceptance criteria final belum dinilai.
- `bash tool/verify.sh` pada main: selesai dengan exit 0; format, architecture,
  analyzer, dan suite core-api/core-starter/core-ui/platform-app lulus.
- Perintah yang sama pada CR: selesai dengan exit 0; format 195 file,
  architecture 8 package, analyzer, dan 142 test pada enam suite lulus.
  Attendance belum memiliki suite test karena vertical slice-nya belum ada.
- Verifikasi menggunakan versi core dan tool milik masing-masing worktree.
  Hasil CR belum membuktikan kompatibilitas dengan perubahan lokal main terbaru.
- Tidak menjalankan APK/iOS build, backend live, push/biometrik perangkat nyata,
  load test, atau UAT. Riwayat build sukses di README bukan hasil build review ini.

## Hal yang sudah mendukung maintainability

1. Dependency rule melarang core bergantung pada plugin, plugin mengimpor plugin
   lain/platform, serta domain mengimpor data/presentation. Ada checker dan test.
2. Typed `Result`/`Failure`, repository contract, serta data adapter memisahkan
   transport dari UI. `ActiveBusinessContext` tidak mengekspos token.
3. `SessionStore` menyerialisasi penulisan token dan memakai generation untuk
   menolak hasil refresh/request dari sesi lama.
4. Request foundation sudah mempunyai pagination, stale-response protection,
   state per Submission/Approval, selection, dan bulk action dengan hasil parsial.
5. Design system, localization, picker launcher, serta startup/lifecycle sudah
   memiliki komponen dan test yang dapat dipakai ulang.
6. Compatibility legacy berada di boundary yang ditandai dengan removal
   condition. CI menjalankan verification script.

## Temuan prioritas

P1 berarti perlu diselesaikan sebelum cutover flow terkait. P2 berarti pekerjaan
fondasi/maintainability yang perlu dijadwalkan sebelum pola diperluas. Temuan di
bawah berasal dari pembacaan kode; skenario baru belum diberi regression test
sebagai bagian dari review ini.

### R1 — P1: refresh OAuth dan session-expiry belum terpasang pada CR

CR `platform-app/lib/app/app_dependencies.dart:52` membuat `ApiClient` tanpa
`refreshTokens` dan tanpa base URL. `AuthPlugin` juga tidak memasang
`setSessionExpiredHandler`. Pada 401, interceptor memakai fallback
`/auth/refresh` dengan JSON camelCase, sedangkan transport login tenant memakai
`/oauth/token` dan token snake_case. Di main, composition masih memasang
`refreshLegacyTokens`; transport tersebut justru dihapus dari legacy CR.

Dampak: login awal dapat berhasil, tetapi refresh ketika access token kedaluwarsa
tidak memakai kontrak tenant yang benar. Redirect/clear context akibat expiry
client baru juga belum mempunyai handler.

Pembagian: engine refresh, generation, dan callback tetap generic di main;
fallback backend hardcoded perlu diganti konfigurasi/strategy eksplisit di main.
Implementasi OAuth tenant dan wiring auth-to-login/context-clear masuk CR auth.
Verifikasi: concurrent 401, refresh sukses, refresh ditolak, refresh offline,
dan hasil refresh lama setelah logout/switch company.

### R2 — P1: local verification CR dapat membuat pengguna terhenti

CR `plugins/auth/lib/src/features/verification/domain/local_verification_method.dart:1`
hanya memiliki PIN dan biometric. `local_verification_page.dart:127` menyediakan
Try Again untuk biometric tanpa pilihan metode lain, sementara Back diblokir.
Setup juga belum mempunyai Skip/password. Ini belum memenuhi FR006 yang meminta
password setelah Skip dan alternatif ketika biometric dibatalkan/tidak tersedia.

Selain itu, `verification_setup_page.dart:97` menunggu penulisan storage dan
callback tanpa catch/finally. Bila penulisan gagal, `_busy` dapat tetap true dan
halaman tidak menyediakan retry yang dapat digunakan.

Pembagian: flow, pilihan metode, fallback, dan error state adalah CR auth.
Adapter OS/secure storage yang benar-benar reusable dapat berada di core-starter;
widget error/loading reusable tetap core-ui. Jangan memindahkan halaman auth ke
core hanya untuk mengejar label generic.

### R3 — P2: invalidasi sesi belum mencakup login/OTP yang masih berlangsung

CR `login_repository_impl.dart:63` mengambil company sebelum network call,
tetapi `_ensureActive()` setelah response hanya mengecek disposal.
`installed_session_storage.dart:101` baru memanggil `beginSession()` saat
menyimpan response. `clearSession()`/`invalidateSession()` dapat berjalan ketika
login masih berlangsung; response lama kemudian dapat memulai generation baru
dan menulis token kembali. Guard `_busy` login tidak mengunci kedua operasi ini.

Pembagian: primitive generation tetap main; CR auth perlu menangkap identity
company dan generation sebelum login/OTP, lalu memeriksanya sebelum seluruh
commit/handoff. Tambahkan test response login/OTP terlambat setelah clearSession
dan company change. UI yang menonaktifkan tombol bukan jaminan di repository.

### R4 — P2: generic picker masih dimiliki AttendancePlugin pada CR

CR `plugins/attendance/lib/src/attendance_plugin.dart:30` mendaftarkan picker
employee, subordinate, working location, shift, dan attachment.
`gasione_plugin_attendance.dart:1` juga me-re-export API generic core. Padahal
leave/overtime/cash advance dapat memakai capability yang sama dan dependency
rule melarang plugin mengimpor plugin lain.

Host CR baru membaca `pageRoutes` dan localization attendance; belum membuat
PickerRegistry dari kontribusinya. Di main pun registry masih sebatas library
yang diuji, belum menjadi service composition aplikasi.

Pembagian: factory/kontributor picker shared di core-ui dengan repository
core-api yang diinjeksikan; adapter data di core-starter; assembly dan registry
di platform-app, semuanya main. CR attendance tinggal memasok filter,
eligibility, dan penggunaan picker. Consumer mengimpor core secara langsung.

### R5 — P2: delivery notifikasi belum mempunyai navigation consumer

Main `core-starter/lib/src/services/notification_service.dart:49` menyediakan
interaction stream dan `getInitialInteraction()`, tetapi tidak ada pemakaian
keduanya di host main maupun CR. FCM registration/local display tidak sama
dengan navigasi ke detail workflow. FR004 Attendance membutuhkan bagian ini.

Pembagian: subscription/disposal, penanganan initial interaction, antrean selama
auth/local verification belum selesai, serta resolver contract masuk main.
Mapping payload WFH/Flex/Correction ke request/detail, route alias, dan
permission/eligibility feature masuk CR attendance.
Test generic harus mencakup cold/warm start, pending login, switch company,
payload invalid, dan navigasi sekali.

### R6 — P2: pagination belum menjamin rendering list tetap ringan

Main `request_workspace.dart:325` dan
`request_reference_picker_content.dart:92` menggunakan `ListView(children: ...)`
dengan loop seluruh item. `request_list_controller.dart:69` terus menambahkan
page ke memori. Setiap rebuild membentuk widget untuk seluruh item yang sudah
dimuat; pagination jaringan sudah ada, tetapi konstruksi widget belum lazy.

Pembagian: ubah shared list menjadi builder/sliver di core-ui pada main.
Pertimbangkan batas retention/cache setelah pengukuran perangkat menunjukkan
kebutuhannya. Jangan menetapkan batas history bisnis tanpa requirement.
Verifikasi scrolling/rebuild pada ribuan item; bulk selection dan PageStorage
harus tetap bekerja.

### R7 — P2: SafeLogInterceptor belum aman untuk payload CR ketika diaktifkan

Main `safe_log_interceptor.dart:18` mencetak URI lengkap tanpa sanitasi query,
dan body hanya disaring berdasarkan beberapa nama key. OTP, PIN, remark,
client_secret, dan signed URL belum tercakup. Revoke menggunakan remark pada
query (`api_request_repository.dart:88`), sehingga redaksi body saja tidak cukup.
`ApiClient` mengaktifkan logger secara default pada debug.

Logger saat ini dimatikan secara eksplisit di host main dan factory auth CR;
jadi temuan ini adalah kelemahan foundation saat dipakai dengan default/debug
logging, bukan bukti kebocoran pada runtime yang diverifikasi.

Pembagian: kebijakan log metadata saja secara default, sanitasi URI/header, dan
test redaction masuk main. Jangan mengandalkan setiap CR mengingat flag logging.

### R8 — P2: retry berdasarkan metode HTTP dapat mengulang revoke

`ApiRequestRepository.execute(revoke)` memakai GET karena kontrak installed API.
`RetryInterceptor` menganggap GET dapat diulang pada timeout/5xx. Bila backend
telah memproses revoke sebelum koneksi gagal, client berpotensi mengirim action
yang sama lagi. Guard tombol tidak mencegah pengulangan transport ini.

Pembagian: sediakan kebijakan retry per request/operation di main dan nonaktifkan
untuk GET yang mempunyai efek perubahan data. Pertahankan endpoint backend
existing sesuai scope CR. Reproduksi dengan simulated timeout setelah server
menerima action; pastikan action dikirim sekali.

## Daftar generic yang masuk main sekarang

Status “ada lokal” tidak berarti sudah di-commit atau sudah tersedia pada CR.

| Item | Penempatan | Kondisi / pekerjaan berikutnya |
| --- | --- | --- |
| Result/Failure, query/page, plugin/page-route/picker contracts | core-api | Sudah ada; pertahankan sebagai fondasi main |
| Active company/employee, permission, session identity, timezone contract | core-api | Sudah ada; dokumen TS Attendance yang menyebut typed employee belum ada perlu diperbarui |
| SessionStore, HTTP, single-flight refresh, configurable TokenRefresher | core-starter | Sudah ada; selesaikan R1/R8 pada engine generic, OAuth konkret tetap auth |
| Request CRUD/workflow, history/executor, attachment/custom-field/reference adapters | core-starter | Sudah ada; jangan diduplikasi atau dipindah ke attendance |
| Request workspace/list/selection/bulk, modal, detail/form scaffold | core-ui | Sudah ada; selesaikan R6 dan test shared behavior |
| Picker key/launcher/registry, page/sheet/dialog, picker form field | core-api + core-ui | Ada, termasuk perubahan lokal main terbaru; lengkapi assembly shared R4 |
| Shared request picker definitions dan localization registration | core-ui + platform-app | Masih ada di AttendancePlugin CR; ekstrak ke main dengan dependency injection |
| Design token/theme, button/input/text, loading/snackbar, result page/content/dialog/sheet | core-ui | Ada lokal main; commit fondasi dan sinkronkan ke CR |
| Generic splash persiapan, startup retry/disposal, device access/security | core-api + core-starter + core-ui + platform-app | Ada lokal main; dipertahankan sebelum plugin CR diaktifkan |
| Route bridge dan duplicate detection | platform-app | Sudah ada; pakai mekanisme contribution yang sama saat plugin bertambah |
| Plugin registry/composition untuk route, locale, picker dan lifecycle | platform-app | Baru parsial/manual; sediakan assembly sederhana dengan duplicate checks, tidak perlu dynamic plugin loading |
| Notification interaction coordinator dan resolver extension point | core-api + platform-app | Belum ada navigation consumer; kerjakan R5 |
| Safe logging dan operation-aware retry | core-starter | Selesaikan R7/R8 beserta regression test |
| Architecture rule, verify script, CI, documentation fondasi | tool + test + docs + CI | Sudah ada; main harus menjadi baseline tunggal untuk CR |

Katalog employee/shift/working location dapat menjadi shared capability karena
digunakan lintas fitur. Definisi tersebut tidak berarti filter eligibility WFH,
allowed shift Flex Hour, atau payload Correction ikut masuk core.

## Daftar yang tetap spesifik CR

| Area | Tetap di CR | Gap saat review |
| --- | --- | --- |
| Splash Pre-Home | Composition/copy/timing sesuai Business Specification | Reconcile dengan generic StartupGate/AppSplashPage main agar owner timer jelas |
| Company Selection | Lookup/selection UX, recently used company, branding | Form lookup sudah ada; history/recent-company UI dan contract belum ada |
| Login | Zero/single/multiple account, preferred account, Different User | Login username/password sudah ada; account selection baru belum ada, switch account masih legacy |
| Recovery dan MFA | Endpoint mapping, OTP expiry/resend, feature copy | Implementasi/test tersedia; backend/device parity belum diverifikasi |
| Local verification | PIN setup/unlock, password/Skip, biometric fallback | R2; penyimpanan PIN plain di preferences masih mengikuti kompatibilitas legacy, bukan migrasi secure storage selesai |
| Auth session | OAuth tenant refresh, expiry-to-login, account history | R1/R3; jangan memasukkan endpoint/payload tenant ke generic interceptor |
| Business context | User/license/menu/access/device-policy/manager mapping dan FCM backend | Implementasi ada; clear pada logout/expiry harus disatukan dengan lifecycle auth, bukan hanya company-entry callback |
| Legacy Home handoff | Mapping konkret BusinessContext ke legacy snapshot | Adapter sudah ada; tetap di composition boundary CR, tidak masuk core |
| Work From Home | Entity/draft/mapper/repository, card/filter/sort/summary/detail/form, duration/location, workflow eligibility | Vertical slice belum ada |
| Flex Hour | Entity/draft/mapper/repository, card/filter/sort/summary/detail/form, shift eligibility | Vertical slice belum ada |
| Attendance Correction | Log pre-form, initial draft, editable date/time, validation, workflow | Vertical slice belum ada |
| Attendance navigation | Alias tiga route, payload resolver konkret, downstream check-in/log/record adapter | `pageRoutes` plugin masih kosong; fallback masih legacy, adapter attendance baru belum ada |
| Feature test dan cutover | Mapper/state/widget/integration dan regression per fitur | Attendance belum memiliki test; jangan menghapus legacy sebelum parity dan rollback window selesai |

Reusable auth/business-context capability tidak otomatis harus dipindah utuh ke
main pada pekerjaan ini. Implementasi endpoint dan flow-nya memang deliverable
CR Pre-Home. Yang masuk main adalah kontrak/primitive generic dan composition
mechanism yang dapat dipakai tanpa mengaktifkan flow CR. Skeleton paket kosong
tidak perlu ditambahkan ke main hanya untuk memenuhi checklist struktur.

## Sinkronisasi fondasi dan urutan pekerjaan

Ada drift nyata antara dua worktree: 3 perbedaan file core-api, 5 core-starter,
47 core-ui, dan 2 tool, termasuk file yang hanya ada di main. Ini adalah
perbandingan konten file lokal, bukan jumlah commit atau konflik merge.
CR masih memakai theme/AdaptiveTheme/EasyLoading lama dan belum memakai
DeviceAccessGate baru main. Setelah memakai aturan main terbaru, import langsung
EasyLoading di CR juga perlu disesuaikan ke AppLoading.

Urutan yang disarankan:

1. Finalisasi dan commit pekerjaan fondasi lokal main yang sudah diverifikasi,
   lalu selesaikan generic R4–R8 dan konfigurasi refresh R1. Pisahkan commit
   menurut concern agar dapat direview dan diserap CR.
2. Simpan pekerjaan CR yang masih uncommitted sebelum menyerap baseline main.
   Rekonsiliasi perubahan app/app_dependencies/entry/startup secara selektif;
   jangan menimpa file host main dengan versi CR lama.
3. Verifikasi main tetap menjalankan legacy tanpa dependency pada plugin CR.
   Sinkronkan core/tool ke CR dan jalankan verification ulang pada hasil gabungan.
4. Lengkapi Pre-Home CR: R1–R3, recently used company, account selection, dan
   handoff/clear context. Test tenant switch, logout, expiry, dan storage failure.
5. Implementasikan WFH, Flex Hour, Correction sebagai vertical slice. Gunakan
   shared workspace/picker/repository tanpa menyalin foundation ke plugin.
6. Cutover route/notification dan downstream integration per feature; lakukan
   backend/device regression sebelum menghapus implementasi legacy terkait.

Keputusan product yang masih diperlukan: Business Specification/prototype final,
field filter/sort per mode, perilaku recorded time ketika tanggal Correction
diubah, serta penamaan WFH/Work From Remote. Ini dependency CR, bukan alasan
menambah business rule spekulatif ke core.

Kriteria pemisahan selesai: main dapat diverifikasi dan dijalankan sendiri dengan
legacy; reusable capability dapat dipakai plugin lain tanpa mengimpor attendance
atau auth; diff CR berisi flow/content/payload/eligibility serta wiring cutover
yang spesifik; hasil gabungan lulus test dan regression yang sesuai.
