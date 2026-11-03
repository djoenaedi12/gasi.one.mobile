# Alur startup sampai halaman pertama

Mulai membaca dari `platform-app/lib/main.dart`, lalu ikuti urutan berikut.
Alur ini berlaku untuk `main`, yang menggunakan `plugins/legacy_epc` sebagai
pemilik halaman. Plugin baru dan splash khusus Pre-Home tetap berada di CR.

```text
main()
  -> bootstrap()
     -> StartupGate: splash minimal 2 detik + initialize, retry bila gagal
        -> AppDependencies.initialize(): siapkan layanan bersama
           -> AppRuntimeService.load(): versi, device ID, keamanan perangkat
        -> GasioneApp
           -> DeviceAccessGate: periksa hasil keamanan
              -> ditolak: halaman perangkat/aplikasi tidak valid; berhenti
              -> diizinkan: buat shell aplikasi
                 -> hubungkan legacy, HTTP, route, tema, bahasa
                 -> AppEntryPage: pulihkan sesi, retry bila gagal
                    -> LegacyEpcModule.restore()
                       -> LegacyBusinessContextBridge.restore()
                    -> LegacyEpcModule.buildEntryPage(status)
                       -> halaman pertama terbuka
```

## 1. Menjalankan persiapan

`bootstrap.dart` memberikan fungsi `AppDependencies.initialize` kepada
`StartupGate` melalui parameter bernama `initialize`. Fungsi diberikan tanpa
`()`; `StartupGate` yang memanggil `widget.initialize()` ketika mulai.

`StartupGate` memasang `AppSplashPage.loading()` dari core-ui selama fungsi itu berjalan.
Persiapan dimulai langsung; hitungan minimum 2 detik berjalan bersamaan, dihitung
dari frame splash pertama. Gate lanjut setelah **persiapan berhasil dan minimum
2 detik terpenuhi**, bukan menambahkan 2 detik setelah persiapan. Jika gagal,
setelah minimum yang sama `AppSplashPage.failure(onRetry: _retry)` menampilkan
pesan dan tombol retry di splash yang sama, dengan logo tetap terlihat.
Setiap retry mendapat minimum splash baru; rebuild biasa
tidak mengulang persiapan atau durasinya. Timer dibatalkan saat gate dilepas.
Tampilan, teks, spacing, dan gaya tombol berada di core-ui; gate hanya mengelola
percobaan dan lifecycle. Versi ditampilkan melalui `versionOf` ketika dependency
sudah tersedia; logo bisa tampil sejak frame pertama tanpa menunggu metadata.
Sebelum preferences siap, bahasa mengikuti locale perangkat yang didukung
(en/id), dengan fallback en. Rebuild widget tidak mengulang persiapan.
Setelah kedua syarat terpenuhi, hasil diberikan ke `GasioneApp` melalui `builder`.

## 2. Menyiapkan kebutuhan aplikasi

`AppDependencies.initialize()` dibaca dari atas ke bawah:

1. `_preparePlatform()`: orientasi, dukungan bahasa, sertifikat HTTPS.
2. Membuka `SharedPreferences` dengan backend dan key instalasi yang sama.
3. `AppRuntimeService.load()`: membaca versi aplikasi, mempertahankan/membuat
   device ID, lalu memeriksa keamanan perangkat.
4. Membaca bahasa tersimpan.
5. `_initializeNotifications()`: menyiapkan Firebase dan notifikasi.
6. Mengembalikan `AppDependencies`, yaitu kumpulan layanan dan pengaturan tersebut.

Tahap ini belum membaca user dari API dan belum memilih halaman login/Home.

Pemeriksaan keamanan memiliki tiga tugas terpisah:

| Fungsi | Tugas |
| --- | --- |
| `DeviceSecurityService.inspect()` | Membaca root/jailbreak, perangkat fisik, developer mode, external storage, signature |
| `DeviceSecurityPolicy.evaluate(report)` | Mengubah fakta tersebut menjadi hasil aturan keamanan yang sudah berlaku |
| `DeviceAccessGate.build()` | Membuka shell jika diizinkan, atau menampilkan `AppDeviceAccessDeniedPage` |

Hasil native juga disimpan pada `DeviceSecurity.report` agar halaman penolakan
menampilkan centang/silang yang benar untuk tiga persyaratan. Bila adapter lama
belum menyediakan report, status ditampilkan sebagai belum tersedia, bukan
dianggap gagal.

Tampilan penolakan berada di `core-ui` dan memakai `AppButton`, `AppText`,
`AppSpacing`, `AppRadius`, serta warna tema. Platform hanya memeriksa akses,
memasang tema/lokalisasi, dan memberikan callback `onExit`. Token warna terang
dan gelap mengikuti web; lihat [Design system](design-system.md).

Signature tidak valid didahulukan bila kedua jenis masalah terjadi sekaligus.
Kegagalan pemanggilan native tetap menjadi kegagalan startup yang bisa dicoba
ulang, bukan diubah menjadi hasil perangkat aman.

Hasil pemeriksaan asli langsung dievaluasi oleh `DeviceSecurityPolicy` dan
dipakai oleh `DeviceAccessGate`. Override lokal untuk pengujian sudah dihapus.
Test otomatis dapat memberikan `checkSecurity` ke `AppRuntimeService` tanpa
mengubah hasil pemeriksaan pada aplikasi yang dijalankan.

## 3. Menghubungkan aplikasi

Seluruh tema dibuat oleh `core-ui/AppTheme`; platform hanya memilih mode.
Startup, gate perangkat, dan shell menggunakan `AppTheme.light()` secara langsung.
Jika perangkat diizinkan, `GasioneApp` memasang bahasa dan shell aplikasi.
`_AppShell.didChangeDependencies()` mengerjakan tiga hal:

1. `_connectLegacyFeatures()`: memberikan layanan bersama ke legacy, membuat
   HTTP client, dan menghubungkan route melalui public boundary legacy.
2. `_configureSessionExpiry()`: mengatur tujuan ketika sesi habis.
3. `_startBackgroundServicesAfterFirstFrame()`: menjalankan update check,
   langganan token notifikasi, serta permintaan izin notifikasi setelah frame
   shell pertama. Ini bukan penentu halaman pertama.

`MaterialApp.home` adalah `AppEntryPage`. Timer StartupGate hanya menentukan
durasi minimum tampilan, bukan memilih halaman. Jika akses perangkat ditolak,
shell ini tidak dipasang, sehingga
pemulihan sesi, permintaan izin, dan layanan latar belakang legacy tidak dimulai.

## 4. Memulihkan sesi

`AppEntryPage._restoreSession()` memanggil kontrak `AuthRestorer.restore()`.
Di `main`, implementasinya adalah `LegacyEpcModule.restore()`, yang
mendelegasikan pekerjaan ke `LegacyBusinessContextBridge.restore()`.

Bridge menjalankan keputusan berurutan:

1. Baca perusahaan dan sesi yang tersimpan. Tanpa perusahaan, kembalikan
   `companyRequired`.
2. Jika perusahaan ada tetapi belum login, kembalikan `loginRequired`.
3. Jika sesi ada, `_restoreUserContext()` memuat user, license, parameter,
   device registration, dan status manager melalui repository existing.
4. Tentukan apakah verifikasi lokal sudah diatur. Sesi tersimpan tetap harus
   melewati verifikasi sebelum Home.

Selama proses ini, `AppEntryPage` melanjutkan tampilan `AppSplashPage.loading()`, dengan
versi dari runtime dan bahasa aktif dari shell. Tidak ada tambahan timer 2 detik.
Bila gagal, pesan dan tombol retry ditampilkan melalui `AppSplashPage.failure`
pada splash yang sama. Retry hanya mengulang pemulihan sesi; layanan platform
yang sudah siap tidak dibuat ulang.
Percobaan restore yang bersamaan memakai pekerjaan yang sama. Module yang sudah
didispose tidak boleh memasang kembali konteks user dari hasil request terlambat.

## 5. Membuka halaman pertama

`LegacyEpcModule.buildEntryPage(status)` menjadi satu pemetaan yang mudah dicari:

| Status | Halaman |
| --- | --- |
| `companyRequired` | `ClientPage` — pilih perusahaan |
| `loginRequired` | `LoginPage` |
| `verificationRequired` | `VerificationPage` |
| `verificationSetupRequired` | `VerificationSetupPage` |
| `authenticated` | `HomePage` |

Restore sesi tersimpan saat ini menghasilkan verifikasi atau setup verifikasi,
bukan langsung `authenticated`. Home terbuka setelah flow autentikasi/verifikasi
legacy berhasil. Detail fitur tersebut tetap milik legacy sampai cutover CR.

## Tempat mengubah perilaku

| Kebutuhan | Lokasi |
| --- | --- |
| Tambah layanan bersama | `platform-app/lib/app/app_dependencies.dart` |
| Ubah cara membaca kondisi perangkat | `core-starter/lib/src/services/device_security_service.dart` |
| Ubah aturan perangkat yang diizinkan | `core-starter/lib/src/services/device_security_policy.dart` |
| Ubah tampilan akses ditolak dan checklist | `core-ui/lib/src/design_system/patterns/app_device_access_denied_page.dart` |
| Ubah token warna dan tema bersama | `core-ui/lib/src/design_system/foundations/app_colors.dart` dan `app_theme.dart` |
| Ubah kapan shell boleh dibuka | `platform-app/lib/app/device_access_gate.dart` |
| Ubah loading/retry saat restore sesi | `platform-app/lib/app/app_entry_page.dart` |
| Ubah pemulihan sesi legacy | `plugins/legacy_epc/lib/src/legacy_business_context_bridge.dart` |
| Ubah pemetaan status ke halaman legacy | `plugins/legacy_epc/lib/src/legacy_epc_module.dart` |

Layanan bersama dimiliki `GasioneApp` dan didispose ketika aplikasi dilepas.
Soft restart legacy membangun shell lagi dengan instance layanan yang sama.
Jika startup dibatalkan sebelum aplikasi dipasang, `StartupGate` membersihkan
hasil inisialisasi yang terlambat selesai.
