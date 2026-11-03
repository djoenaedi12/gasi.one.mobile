# Main readiness foundation

Main menyediakan capability generic untuk plugin berikutnya. Implementasi
halaman/endpoint/payload Pre-Home dan Attendance Requests tetap di CR.

## HTTP dan session

`ApiClient` menerima `TokenRefresher` untuk transport refresh yang spesifik
backend. Tidak ada fallback `/auth/refresh`, format JSON, atau endpoint tenant
yang dipilih oleh core. HTTP client yang dipakai refresher harus dikelola oleh
pemilik strategy; jangan membuat siklus refresh pada request refresh itu sendiri.
Parameter lama `refreshDio` telah diganti dengan strategy ini.

Tanpa strategy, 401 membersihkan sesi dan menjalankan session-expired callback.
Refresh yang ditolak dengan status 400/401/403 juga membersihkan sesi; error
network/timeout yang terpetakan sebagai ApiException/DioException mempertahankan
sesi agar dapat dicoba lagi. Single-flight dan session generation tetap berlaku.
Main masih menginjeksikan `refreshLegacyTokens` pada composition boundary.

GET/bytes/download memakai `RequestRetryPolicy.readOnly` untuk retry transient.
GET yang mengubah data wajib memakai `RequestRetryPolicy.never`; request revoke
sudah menggunakannya. POST/PUT/delete/upload tidak mendapat retry transient.
Auth replay setelah 401 tetap dipisahkan dari retry transient: response 401
berarti server menolak authorization sebelum memproses action.

`enableLogging` default false. Jika diaktifkan, SafeLogInterceptor hanya mencatat
method, status HTTP, dan jenis error. URL/path, query, header, body request,
body response, serta pesan exception tidak dicetak.

## Composition dan picker

`PluginComposition` berada di platform-app karena menggabungkan core-starter,
core-ui, dan kontribusi feature. Ia memeriksa duplikasi plugin code, route,
picker ID, menu route, serta localization delegate type. Plugin pada Navigator
host menyumbang halaman melalui `PageRouteContributor`; kontrak GoRouter tetap
tersedia untuk migrasi host berikutnya.

`AppDependencies.createPlugins` adalah factory untuk instance baru pada setiap
shell, termasuk soft restart. Plugin dapat mengimplementasikan `PluginLifecycle`
untuk start/dispose sekali. Disposal berjalan dalam urutan terbalik, termasuk
instance yang sudah dikonstruksi tetapi belum sempat start. Host melepas plugin
sebelum menutup shared ApiClient. Dependency lain yang diinjeksi dari luar plugin
tetap dilepas oleh pemiliknya.

`RequestPickerContributor` di core-ui menyediakan picker employee/subordinate,
working location, shift, dan file. Repository diinjeksikan melalui core-api;
adapter installed API berada di core-starter. Host main memasang registry berisi
kontribusi shared tersebut dan kontribusi plugin, lalu mengeksposnya melalui
`PickerScope`. Tidak memerlukan AttendancePlugin.

```dart
final selected = await PickerScope.of(context).open(
  context,
  RequestPickerKeys.workingLocation,
  request: const PickerRequest(
    title: 'Choose location',
    arguments: {'active': true},
  ),
);
```

Feature tetap memiliki filter, permission, dan eligibility action-nya. Akses
capability generic dilakukan dengan mengimpor core secara langsung, tanpa
re-export melalui plugin bisnis.

## Notification navigation

`NotificationInteraction`, `NotificationDestination`, dan
`NotificationDestinationResolver` berada di core-api. Plugin dapat
mengimplementasikan resolver untuk menafsirkan payload feature, memeriksa
permission, dan mengembalikan tujuan dengan companyCode eksplisit. Route tujuan
harus menjadi page contribution yang terdaftar. Host tidak mengeksekusi route
mentah yang disisipkan ke payload dan tidak menggunakan legacy fallback untuk
tujuan notifikasi yang tidak dikenali.

`NotificationNavigationCoordinator` di platform-app:

- Membaca initial interaction sekali serta mendengarkan interaction berikutnya.
- Menunggu business context dan sinyal readiness setelah local verification.
- Mengikat pending interaction pada session/company/base URL ketika tersedia;
  perubahan sesi membuang pending action sesi lama dan membatalkan readiness.
- Memeriksa company tujuan dan route terdaftar sebelum navigasi.
- Membatasi antrean pending pada 16 interaction dan dedup cache pada 128 ID.
- Menutup subscription dan membatalkan scheduled work saat disposal.

Firebase/native interaction memakai ID stabil yang sama untuk remote dan local
notification. `getInitialInteraction()` mengonsumsi initial interaction sehingga
soft restart tidak menjalankannya kembali. Identitas dedup dan antrean hanya
tersimpan di memori.

Main belum mendaftarkan resolver WFH/Flex Hour/Correction. Payload yang belum
dikenali diabaikan; pemetaan feature tersebut tetap deliverable CR.

`TRANSITION[LEGACY-NAVIGATION]` pada LegacyEpcModule/Config/Home mengirim sinyal
post-frame setelah Home benar-benar dimasuki. Business context yang sudah dimuat
sebelum PIN/biometrik bukan sinyal unlock. Bridge ini dihapus ketika auth baru
memberi readiness langsung kepada host. `TRANSITION[LEGACY-SESSION]` mengadopsi
snapshot token legacy melalui penulisan serialized SessionStore agar service
generic tidak tetap terblokir setelah pergantian context.

## List dan verifikasi

RequestWorkspace dan RequestReferencePickerContent membangun row secara lazy.
Pagination dan data yang sudah dimuat tetap dipertahankan, termasuk selection
atas seluruh row yang dimuat. Tidak ada batas history bisnis baru.

Jalankan `bash tool/verify.sh` untuk format, architecture, strict analyzer, dan
seluruh suite main. Regression test mencakup configured refresh, late refresh,
rejected/transient refresh, revoke timeout/503, metadata-only logging, picker
tanpa business plugin, list 3.000 row, registry/lifecycle, dan notification
cold/warm start, local verification, tenant switch, invalid payload, dedup,
bounded queue, serta disposal.

Hasil 3 November 2026: seluruh 198 test lulus, analyzer bersih, architecture dan
format check lulus. `flutter build apk --debug` dari platform-app berhasil;
artifact berada di `platform-app/build/app/outputs/flutter-apk/app-debug.apk`.
Validasi backend live/perangkat fisik dan build iOS belum dijalankan.
