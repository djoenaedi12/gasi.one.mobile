# Legacy EPC Incremental Migration Roadmap

Dokumen ini menjelaskan strategi setelah parity release tercapai. Pendekatan
yang digunakan adalah strangler migration: aplikasi legacy tetap hidup,
sementara ownership suatu alur dipindahkan ke implementasi baru satu per satu.

Roadmap ini disusun berdasarkan kondisi kode saat ini, bukan berdasarkan bentuk
ideal yang mengharuskan rewrite besar di awal.

## Kondisi dan constraint saat ini

Beberapa karakteristik kode lama memengaruhi urutan migrasi:

- `main.dart` sekaligus melakukan bootstrap Firebase, preferences, device info,
  security checks, theme, localization, loading overlay, dan routing.
- Splash menentukan tujuan berdasarkan `Config.client`, `Config.session`,
  `Config.user`, serta verification type.
- Auth membutuhkan client/tenant URL, client ID/secret, package version, device
  token, OTP/MFA, dan verification flow. Migrasi auth bukan hanya mengganti
  halaman login.
- Session disimpan melalui `SharedPreferences` dan disalin ke global `Config`.
- `Repository()` bertindak sebagai service locator untuk hampir seluruh modul
  dan mengambil base URL/token dari provider lama.
- `ApiProvider` menangani 401 dengan global navigator dan langsung membuka
  halaman login lama.
- Menu dan permission berasal dari user/role data di `Config`.
- Banyak halaman memakai `Navigator.push(MaterialPageRoute(...))` secara
  langsung.
- Warna client disimpan di `Config.DEFAULT_COLOR` dan
  `Config.DEFAULT_ACCENT_COLOR`.
- Attendance bergantung pada location, permission, camera, dan konfigurasi
  native, sehingga bukan kandidat migrasi pertama setelah auth.

Konsekuensinya, memigrasikan hanya widget login tanpa compatibility bridge akan
membuat halaman lama kehilangan tenant, token, user, repository configuration,
menu, atau logout/session-expired behavior.

## Prinsip migrasi

### Satu pemilik untuk setiap concern

Pada satu build hanya boleh ada:

- satu application shell aktif;
- satu pemilik session yang authoritative;
- satu Firebase initialization;
- satu owner untuk setiap route;
- satu mekanisme yang menentukan logout/session expired.

Legacy dan implementasi baru boleh hidup bersama, tetapi tidak boleh sama-sama
menjadi sumber kebenaran untuk concern yang sama.

### Pindahkan vertical slice, bukan folder

Satu migrasi harus memindahkan alur lengkap:

```text
route/menu
  -> page dan widgets
  -> state/Cubit
  -> repository contract
  -> repository implementation
  -> data source/API mapping
  -> tests
```

Jangan memindahkan semua model dahulu, lalu semua repository, lalu semua page.
Cara tersebut menghasilkan periode panjang ketika tidak ada fitur yang
benar-benar selesai dan sulit di-rollback.

### Pertahankan visual legacy

Selama suatu page masih legacy, jangan mengganti warnanya dengan design system
baru. Theme dipisahkan berdasarkan subtree:

```text
App
├── new page       -> AppTheme/core-ui
└── legacy page    -> LegacyTheme/Config colors
```

Setelah shell baru menjadi root, legacy page dibungkus `LegacyPageShell`:

```dart
class LegacyPageShell extends StatelessWidget {
  const LegacyPageShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LegacyTheme.light(
        primaryColor: Config.DEFAULT_COLOR,
        accentColor: Config.DEFAULT_ACCENT_COLOR,
      ),
      child: child,
    );
  }
}
```

Pada fase awal, legacy app masih menjadi root sehingga wrapper ini belum
diperlukan. Wrapper baru diperkenalkan saat shell baru mengambil alih.

### Dependency hanya mengarah ke depan

Kode baru tidak boleh mengimpor `package:epeoplecare/...`. Integrasi dilakukan
melalui contract stabil atau adapter di composition root.

```text
new feature ───────> core contract
legacy adapter ────> core contract
platform-app menyusun keduanya
```

Pengecualian import legacy hanya boleh berada di adapter/platform composition,
bukan di domain atau presentation feature baru.

## Fase 0: parity release

Ikuti [Legacy EPC Integration Runbook](legacy-integration.md). Pada akhir fase
ini aplikasi baru secara struktur masih menjalankan behavior lama sepenuhnya.

Exit criteria:

- Store artifact berasal dari `platform-app`;
- semua fitur kritis lama masih berjalan;
- belum ada redesign atau perpindahan route;
- rollback ke release sebelumnya masih tersedia.

## Fase 1: tambahkan seam tanpa mengubah behavior

Tujuan fase ini bukan mengganti UI, melainkan membuat titik sambung yang dapat
di-inject dari `platform-app`.

Pisahkan tanggung jawab besar dari `main.dart` menjadi façade kecil:

```text
LegacyEpcBootstrap     # Firebase, package info, device/security setup
LegacyEpcApp           # façade baru yang membungkus EWorkflowApp/MaterialApp
LegacyTheme            # ThemeData lama dan warna client
LegacyRuntimeState     # view terkontrol atas Config
LegacySessionGateway   # baca/tulis session lama
LegacyRouteOverrides   # optional route/page builders
```

Implementasi di balik façade masih boleh memanggil `Config`, `Repository()`,
dan provider lama. Tujuannya hanya mencegah plugin baru bergantung langsung
pada global tersebut.

Tambahkan characterization test untuk behavior yang akan disentuh lebih dulu:

- keputusan tujuan splash;
- penyimpanan dan restore session;
- pembentukan header API;
- login sukses/gagal;
- OTP required, verify, resend, expired, dan locked;
- response 401 dan logout;
- client selection dan base URL;
- theme color dari appearance setting.

Exit criteria:

- UI masih identik;
- bootstrap dapat dipanggil melalui façade;
- session lama dapat dibaca/ditulis melalui satu gateway;
- tujuan auth dapat diganti lewat injection tanpa plugin legacy mengimpor plugin
  auth baru.

## Fase 2: migrasi auth EPC

Plugin auth yang ada sekarang memakai DummyJSON dan hanya berfungsi sebagai
contoh struktur. Sebelum dipakai production, data source dan modelnya harus
diganti dengan kontrak EPC sebenarnya.

### Scope auth yang sebenarnya

Auth dianggap selesai hanya jika mencakup:

- client/tenant selection dan penyimpanan client;
- login username/password;
- client credentials dan device headers;
- OTP/MFA initiation, verification, dan resend;
- restore session saat startup;
- refresh token sesuai kontrak server;
- current user, roles, menus, dan access rights;
- verification/local-auth decision sesudah login;
- logout;
- session expired/401;
- switch account jika tetap menjadi requirement;
- device ID dan FCM token registration yang terkait login.

Change password/forgot password dapat menjadi sub-feature auth terpisah, tetapi
harus dicatat eksplisit bila belum ikut release pertama auth baru.

### Urutan implementasi auth

1. Rekam request/response contract dari endpoint EPC dan buat fixture yang
   menghapus credential/token sensitif.
2. Definisikan entity serta repository contract auth tanpa import legacy.
3. Implementasikan EPC auth data source menggunakan `ApiClient` baru.
4. Implementasikan client/tenant context; base URL tidak boleh tetap hardcoded
   ke DummyJSON.
5. Implementasikan session restore dan token lifecycle.
6. Buat `LegacySessionBridge` pada composition boundary.
7. Setelah login baru sukses, bridge memperbarui state yang masih dibutuhkan
   page legacy: client, session, user, language, dan repository configuration.
8. Implementasikan UI client/login/OTP/verification baru secara bertahap.
9. Arahkan startup ke auth baru melalui `LegacyRouteOverrides`.
10. Alihkan logout dan 401 handling ke satu coordinator.

Bridge bersifat sementara. Bentuk konseptualnya:

```text
Auth EPC baru
├── SessionStore baru              # authoritative
├── AuthCubit
└── LegacySessionBridge
    ├── menulis key kompatibilitas SharedPreferences
    ├── memperbarui Config.client/session/user
    └── memanggil Repository().initData()
```

Saat page legacy masih menggunakan `Repository()`, bridge harus tetap aktif.
Jangan menghapus key session lama tepat setelah halaman login baru muncul.

### Cutover auth

Gunakan build-time flag atau satu composition decision, bukan dua login aktif:

```text
useNewAuth = false -> seluruh startup/login legacy
useNewAuth = true  -> auth baru + LegacySessionBridge
```

Rollback auth dilakukan dengan mengubah satu decision tersebut. Hindari flag
yang tersebar di banyak widget.

Exit criteria auth:

- cold start, restore, login, OTP, logout, dan 401 lulus;
- setelah login baru, seluruh module legacy tetap dapat memanggil API;
- menu dan permission legacy tetap benar;
- hanya session baru yang authoritative;
- token atau credential tidak tercetak di log;
- auth DummyJSON tidak menjadi dependency runtime.

## Fase 3: pindahkan application shell dan router

Fase ini dilakukan setelah auth baru stabil. `platform-app` mulai memiliki satu
`MaterialApp.router`, theme/localization app-level, dan route guard baru.

Legacy app tidak lagi menjadi `MaterialApp`; ubah menjadi host/scope yang dapat
merender page lama di bawah shell baru. Pertahankan navigator internal untuk
navigasi detail lama bila memindahkan semuanya sekaligus terlalu berisiko.

Route ownership harus eksplisit:

| Route | Owner awal | Owner setelah migrasi |
| --- | --- | --- |
| startup/login/OTP | `legacy_epc` | production auth plugin |
| `/module/leave` | `legacy_epc` | plugin pemilik leave |
| `/module/attendance` | `legacy_epc` | plugin pemilik attendance |
| route belum dimigrasikan | `legacy_epc` | `legacy_epc` |

Satu route tidak boleh didaftarkan oleh dua plugin. Pertahankan path lama jika
masih digunakan notification payload, deep link, menu server, atau bookmark.

`LegacyPageShell` pada fase ini bertanggung jawab untuk:

- legacy `ThemeData` dan warna client;
- localization lama yang masih dibutuhkan;
- loading/error overlay lama bila belum dimigrasikan;
- navigator key/compatibility navigation bila diperlukan.

Exit criteria:

- hanya ada satu `MaterialApp.router`;
- auth baru melindungi route legacy dan baru;
- semua top-level route mempunyai satu owner;
- back navigation dan notification deep link tetap benar;
- page legacy tetap memakai tampilan lama.

## Fase 4: migrasi module per vertical slice

Mulai dengan satu spike berisiko rendah untuk menguji pola end-to-end. Kandidat
awal yang masuk akal adalah module read-only atau module dengan sedikit file,
misalnya salary-slip/payroll atau letter. Pilihan final harus mempertimbangkan
criticality bisnis dan endpoint, bukan jumlah file saja.

Attendance dikerjakan belakangan karena mempunyai coupling ke location,
permission, camera, schedule, native configuration, dan kemungkinan anti-fraud.

Urutan indikatif:

1. read-only/reference flow;
2. letter atau flow CRUD sederhana;
3. overtime/leave;
4. benefit, loan, cash advance, dan business trip;
5. task/workflow dan reusable approval flow;
6. attendance, location, camera, dan device-sensitive flow.

Ini bukan urutan kontrak. Jika business priority berbeda, pilih urutan lain
tetapi tetap gunakan vertical-slice checklist.

### Checklist satu module

1. Inventaris route, menu, permission, page, dialog, picker, endpoint, dan
   notification/deep-link terkait.
2. Tambahkan fixture dan characterization test dari behavior legacy.
3. Definisikan domain entity dan repository contract.
4. Buat transport model/data source yang memetakan payload EPC.
5. Buat repository implementation dengan typed failure.
6. Implementasikan Cubit/state dan page dengan `core-ui`.
7. Pertahankan route/path serta semantics permission.
8. Jalankan legacy dan implementasi baru terhadap data uji yang sama.
9. Alihkan satu route owner ke plugin baru.
10. Release melalui internal/staged rollout.
11. Hapus source legacy module hanya setelah stabilization window selesai.

Definition of done module:

- tidak mengimpor package legacy;
- data flow mengikuti page -> Cubit -> repository contract -> data source;
- loading, empty, error, retry, validation, dan unauthorized state diuji;
- authorization sama atau lebih ketat dari legacy;
- route lama tidak lagi didaftarkan legacy;
- rollback route masih mungkin selama stabilization window;
- telemetry dan error reporting tidak membuka data sensitif.

## Fase 5: migrasi shared capability

Shared capability jangan dipindahkan seluruhnya di awal. Ekstrak saat minimal
dua feature baru benar-benar membutuhkannya dan kontraknya sudah terlihat.

Kandidat shared capability:

- file/media upload dan download;
- employee/reference picker;
- workflow/approval;
- custom fields;
- notification navigation;
- permission/access-right evaluation;
- tenant/client context;
- timezone/date formatting.

Letakkan kontrak lintas plugin di `core-api` hanya jika benar-benar stabil dan
platform-wide. Implementasi network/storage/device berada di `core-starter`.
Widget generik dan design token berada di `core-ui`. Business rule tetap milik
plugin yang relevan.

## Fase 6: hapus legacy runtime

Legacy dapat dihapus hanya jika:

- tidak ada route yang dimiliki `legacy_epc`;
- tidak ada page baru yang membaca `Config`;
- tidak ada penggunaan `Repository()` atau `ApiProvider` lama;
- tidak ada session compatibility key yang masih dibaca;
- notification/deep-link tidak menunjuk route legacy;
- theme/localization legacy tidak lagi dirender;
- Firebase/geolocation ownership sudah jelas pada implementation baru;
- release tanpa legacy telah melewati stabilization window.

Setelah itu:

1. hapus dependency `epeoplecare` dari `platform-app`;
2. hapus `plugins/legacy_epc` dari workspace;
3. hapus compatibility bridge dan route flag;
4. hapus dependency/plugin native yang benar-benar tidak lagi digunakan;
5. jalankan full regression dan Store build.

## Test dan release strategy

Gunakan beberapa lapisan verifikasi:

- characterization test untuk behavior legacy yang akan diganti;
- model/repository/Cubit/widget test untuk implementation baru;
- integration smoke test untuk auth dan module kritis;
- API fixture/contract test untuk payload server;
- manual device test untuk camera, location, biometric, FCM, dan file system;
- internal testing, staged rollout, lalu production rollout.

Setiap release migrasi sebaiknya hanya mengubah sedikit route ownership. Jangan
menggabungkan upgrade dependency besar, shell cutover, auth cutover, dan banyak
module redesign dalam satu release.

## Tracking yang disarankan

Gunakan tabel ownership sederhana sebagai sumber kebenaran:

| Capability/route | Owner | State | Rollback | Catatan |
| --- | --- | --- | --- | --- |
| bootstrap | legacy | parity | old release | belum dipisah |
| client/auth/OTP | legacy | planned | legacy auth | DummyJSON bukan production |
| `/module/leave` | legacy | backlog | legacy route | - |
| `/module/attendance` | legacy | backlog | legacy route | device-sensitive |

Nilai `State` yang disarankan: `legacy`, `characterized`, `in-progress`,
`shadow-tested`, `new`, dan `legacy-removed`.

## Guardrails

- Jangan redesign page yang belum menjadi scope migrasi.
- Jangan membuat plugin baru mengimpor `epeoplecare`.
- Jangan memiliki dua token store authoritative.
- Jangan mengubah route yang dipakai server/menu/notification tanpa mapping.
- Jangan menghapus code legacy pada release yang sama dengan cutover pertama.
- Jangan mencampur compatibility patch dependency dengan perubahan bisnis.
- Jangan menyalin secret, keystore password, token, atau production payload ke
  test fixture dan Git.
- Jangan menyatakan sebuah module selesai hanya karena halaman list sudah baru;
  detail, form, picker, permission, error, deep link, dan side effect juga harus
  berpindah.

