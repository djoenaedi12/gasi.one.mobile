# Design system mobile

Warna, komponen, dan tampilan bersama dimiliki `core-ui`. Platform memasang tema
dan menghubungkan callback aplikasi. Halaman fitur bisnis tetap milik plugin.

## Token warna

`AppColors.light` dan `AppColors.dark` menyalin 30 peran warna bersama dari
`gasi.one.web/core-ui/src/index.css` (`:root` dan `.dark`), diperiksa pada
30 Oktober 2026. Perubahan CSS acuan terakhir: commit `6de94b8`.
Ini salinan baseline, bukan sinkronisasi otomatis saat build mobile.

| Peran | Light | Dark |
| --- | --- | --- |
| `primary` | `#0072CE` | `#1188E7` |
| `background` | `#F8FAFC` | `#0F172A` |
| `foreground` | `#0F172A` | `#FFFFFF` |
| `mutedForeground` | `#475569` | `#CBD5E1` |
| `success` | `#0CE956` | `#42FF82` |
| `warning` | `#EEBD2B` | `#FBD76A` |
| `destructive` | `#EF0619` | `#FF4252` |

Peran card, popover, secondary, surface, neutral, muted, accent, info, link,
border, input, dan ring juga tersedia dengan nama yang mengikuti web.
Token chart, table, sidebar, dan navbar tidak diperlukan oleh halaman ini;
tambahkan padanannya ketika komponen mobile terkait membutuhkan.

## Tema Flutter

`AppTheme.light()` dan `AppTheme.dark()` menghubungkan palet dengan API yang
sudah dipakai komponen:

| Token/API | Pemakaian |
| --- | --- |
| `ThemeData.scaffoldBackgroundColor` | `background` |
| `ColorScheme.primary / onPrimary` | `primary / primaryForeground` |
| `ColorScheme.surface / onSurface` | `background / foreground` |
| `ColorScheme.onSurfaceVariant` | `mutedForeground` |
| `ColorScheme.secondaryContainer / onSecondaryContainer` | `secondary / secondaryForeground` |
| `ColorScheme.error / onError` | `destructive / destructiveForeground` |
| `AppSemanticColors` | success, warning, info dan warna foreground/container |

Web belum mendefinisikan container success/warning/info. Mobile menurunkannya
dari warna status dengan tint 12% di atas background. Foreground container
menggunakan foreground web pada mode terang dan warna status terang pada mode
gelap, supaya ikon di atas tint tetap terbaca.

Tema juga menerapkan `AppTypography` dan konfigurasi komponen Material yang
dipakai `AppButton` serta input. Contoh pemasangan oleh host:

```dart
MaterialApp(
  theme: AppTheme.light(),
  home: ...,
)
```

`AppTheme` di core-ui menjadi satu-satunya pembuat tema aplikasi. StartupGate,
DeviceAccessGate, serta shell aplikasi memakai tema tersebut. Factory tema di
platform-app sudah dihapus; tidak ada factory tema terpisah untuk legacy.

Aplikasi saat ini memakai `AppTheme.light()` secara langsung pada startup,
gate perangkat, dan shell. Tidak ada pembacaan atau penyimpanan pilihan mode.
`AppTheme.dark()` tetap tersedia sebagai fondasi core-ui; belum diaktifkan pada
flow aplikasi. Warna perusahaan tidak menentukan tema global. Gaya yang masih
ditulis langsung dalam widget legacy dimigrasikan bersama widget tersebut.

## Halaman persiapan aplikasi

Startup aplikasi memakai satu `AppSplashPage`, dengan logo yang sama seperti splash
legacy dan footer versi ketika metadata tersedia. Asset logo dimiliki paket
core-ui di `assets/branding/logo.png`; logo lama tetap ada untuk konsumen legacy.
`AppSplashPage.loading(version: ...)` menampilkan kondisi persiapan berjalan.
Splash ini tidak memiliki timer, membaca Config/storage, atau melakukan navigasi.

Jika gagal, `AppSplashPage.failure(onRetry: ...)` menambahkan pesan error
terlokalisasi dan `AppButton.primary` untuk retry di bawah logo. Splash dan versi
tetap berada di layar yang sama. Komponen hanya meneruskan klik ke callback host.
Saat retry dimulai, pesan dan tombol dihilangkan sampai ada hasil berikutnya.
Warna dan tipografi memakai token tema; error diumumkan melalui live region.

StartupGate di platform mengelola future dan minimum splash 2 detik secara
bersamaan. AppEntryPage melanjutkan splash selama pemulihan sesi, tanpa durasi
minimum tambahan. Keduanya memakai `AppSplashPage.failure(onRetry: ...)`
jika gagal. MaterialApp, pemasangan tema, dan lokalisasi tetap dikonfigurasi oleh
host aplikasi. Layout splash memiliki safe area dan scroll untuk viewport kecil.

## Komponen halaman keamanan

`AppDeviceAccessDeniedPage` berada di
`core-ui/lib/src/design_system/patterns/app_device_access_denied_page.dart`.
Komposisinya memakai:

- `AppButton.primary`: tombol Exit dan interaksi melalui callback `onExit`.
- `AppText`: judul, isi, instruksi, serta footer dengan variant/tone tema.
- `AppSpacing` dan `AppRadius`: jarak serta radius yang konsisten.
- `ColorScheme` dan `AppSemanticColors`: warna dari tema aktif.

Halaman ini menerima `DeviceSecurity` dari `core-api` untuk menampilkan hasil
checklist. Halaman tidak mengakses `safe_device`, melakukan navigasi, atau
memanggil `exit(0)`. Tindakan keluar disediakan oleh `platform-app`.

Ubah nilai palet di `app_colors.dart`, pemetaan/konfigurasi tema di
`app_theme.dart`, dan komposisi halaman di pattern tersebut. Hindari menulis
ulang warna hex, TextStyle, atau implementasi tombol di halaman pemakai.

## Loading: skeleton dan overlay

`AppSkeleton` menampilkan placeholder pada area konten yang sedang dimuat.
`AppLoading` menampilkan overlay blocking untuk proses seperti login, simpan,
atau kirim pengajuan. Overlay menggunakan flutter_easyloading sebagai detail
implementasi di core-ui; pemakai mengimpor `gasione_core_ui`.

Pasang overlay sekali pada builder aplikasi:

```dart
MaterialApp(
  theme: AppTheme.light(),
  builder: AppLoading.init(),
  home: ...,
)
```

Pemanggilan dari presentation layer:

```dart
await AppLoading.show(status: AppLocalizations.of(context).loading);
try {
  await save();
} finally {
  await AppLoading.dismiss();
}
```

`AppLoading.isVisible` tersedia untuk membaca status overlay. Show/dismiss
mengendalikan satu overlay global; pemanggil bertanggung jawab menutup proses
yang dibukanya. Skeleton dan progress inline pada komponen memiliki fungsi
tersendiri, sehingga tidak menutupi seluruh layar ketika konten dimuat.

Warna background, indikator, dan teks mengikuti tema; spacing dan radius memakai
token core-ui. Overlay memblokir interaksi dan tetap terbuka ketika mask disentuh.
Platform dan fitur baru memakai AppLoading. Pemanggilan EasyLoading existing
di legacy tetap dipertahankan sampai halaman tersebut dimigrasikan; keduanya
menggunakan overlay yang sama. Import vendor pada kode modular hanya boleh
berada di `components/feedback/app_loading.dart`, diperiksa oleh architecture
check dengan pengecualian legacy yang eksplisit. Tidak ada tipe atau enum vendor
pada API publik bridge.

## Snackbar dan pesan error

`AppSnackbar` menampilkan umpan balik singkat tanpa menghalangi interaksi pada
halaman. Implementasinya memakai `ScaffoldMessenger` milik Flutter, sehingga
tidak memerlukan package atau overlay tambahan. Gunakan `BuildContext` di bawah
`MaterialApp` dengan `AppTheme` dan `Scaffold` aktif.

```dart
AppSnackbar.success(context, AppLocalizations.of(context).operationSuccessful);
AppSnackbar.warning(context, message);
AppSnackbar.info(context, message);
AppSnackbar.error(context, message);
```

Varian memakai pasangan token status dan foreground-nya, beserta ikon berbeda.
Radius, spacing, dan tipografi mengikuti core-ui. Pesan terbaru menggantikan
pesan sebelumnya beserta antreannya; snackbar dapat ditutup manual dan hilang
otomatis setelah empat detik.

Untuk kegagalan operasi yang sudah menghasilkan `Failure`, gunakan:

```dart
AppSnackbar.failure(context, failure);
```

Alur error tetap mengikuti boundary paket:

1. `core-starter`: `ApiErrorMapper` dan `FailureMapper` mengubah error transport
   menjadi kontrak `Failure` dari `core-api`.
2. `core-ui`: `failure.localizedMessage(AppLocalizations.of(context))` memilih
   pesan sesuai bahasa aktif. Network, timeout, sesi tidak valid, server,
   invalid response, dan unknown memakai panduan terjemahan. Kegagalan bisnis
   seperti validasi/konflik mempertahankan pesan API yang tidak kosong; tanpa
   pesan API, dipakai terjemahan default.
3. Presentation memilih letak pesan: `AppErrorView` untuk daftar/picker yang
   gagal dimuat, error inline untuk form, dan `AppSnackbar.failure` untuk
   kegagalan aksi singkat. `AppResultPage` tetap untuk hasil satu alur penuh.

`CancelledFailure` tidak memunculkan snackbar atau error form. Snackbar hanya
menampilkan pesan; navigasi ketika sesi habis tetap milik handler sesi di
platform. Tidak ada import Dio atau core-starter dari core-ui.

Fondasi request sudah memakai pesan typed pada workspace, reference picker,
dan form. Hasil bulk memakai success jika semua berhasil, warning jika hanya
sebagian berhasil, dan error jika semua gagal. Pemakaian feedback di legacy
tetap dipertahankan sampai halaman terkait dimigrasikan.

## Konten, halaman, dan modal

Komponen isi tidak memiliki `Scaffold` atau menentukan navigasi. Wrapper
halaman/modal mengatur viewport dan cara membuka/menutup tampilan.

| Komponen | Tanggung jawab |
| --- | --- |
| `AppResultContent` | Ikon status, judul, pesan, dan callback tombol hasil |
| `AppResultPage` | Halaman penuh dengan `Scaffold` dan konten hasil yang bisa di-scroll |
| `AppResultDialog.show<T>` | Modal hasil di tengah layar, mengembalikan `T?` |
| `AppResultSheet.show<T>` | Bottom sheet hasil, scroll sesuai panjang konten, mengembalikan `T?` |
| `RequestReferencePickerContent` | Pencarian, pagination, eligibility, dan callback `onSelected` |
| `RequestReferencePicker` | Wrapper halaman reference picker |
| `RequestReferencePicker.showModal` | Membuka reference picker sebagai bottom sheet dan mengembalikan pilihan |
| `RequestReferencePicker.showDialog` | Membuka reference picker sebagai dialog tengah dan mengembalikan pilihan |
| `AppPickerDialog.show<T>` | Dialog picker di tengah dengan tinggi terbatas, header Close, dan hasil bertipe |
| `AppPickerSheet.show<T>` | Wadah modal bersama untuk picker dengan tinggi terbatas dan header Close |

`AppResultDialog` memakai `Dialog` dengan posisi tengah, lebar maksimum 520,
scroll untuk konten panjang, serta inset yang mengikuti keyboard. Warna dialog
mengikuti tema; radius dan spacing memakai token core-ui. Konten picker
membutuhkan tinggi terbatas karena memiliki list sendiri; jangan memasukkannya
ke `SingleChildScrollView` tanpa batas tinggi. `AppPickerSheet` menyediakan
tinggi 85% dari ruang yang tersedia dan menyesuaikan ketika keyboard terbuka.
`AppPickerDialog` menyediakan dialog tengah selebar maksimum 520 dengan tinggi
85% dari area dialog (dibatasi maksimum 600 sebelum faktor tinggi). Ruang list
menyesuaikan keyboard; list tetap mengatur scroll-nya sendiri. Header judul dan
Close dipakai bersama dengan sheet. Warna, radius, dan spacing mengikuti token.
Wrapper modal memakai safe area dan warna dari tema yang sama.

Contoh membuka hasil proses sebagai modal di tengah layar:

```dart
final continueFlow = await AppResultDialog.show<bool>(
  context,
  builder: (dialogContext) => AppResultContent(
    status: AppResultStatus.success,
    title: title,
    message: message,
    primaryActionLabel: continueLabel,
    onPrimaryAction: () => Navigator.pop(dialogContext, true),
  ),
);
```

Callback memakai `dialogContext` agar yang ditutup adalah modal. Dismiss/back
mengembalikan `null`; konten tidak otomatis memilih aksi untuk pemakai.
`barrierDismissible: false` mencegah penutupan lewat tap di luar dialog; tombol
back tetap dapat menutupnya. Untuk modal dari bawah, gunakan
`AppResultSheet.show<T>` dengan pola builder dan callback yang sama.

Reference picker bisa dibuka langsung dengan
`RequestReferencePicker.showModal(context, title: title, repository: references,
kind: RequestReferenceKind.employee)` untuk sheet, atau `showDialog(...)` dengan
parameter yang sama untuk dialog tengah. Pendaftaran dialog melalui registry:

```dart
PickerDefinition<RequestReference>.dialog(
  key: RequestPickerKeys.employee,
  contentBuilder: (dialogContext, request) => RequestReferencePickerContent(
    repository: references,
    kind: RequestReferenceKind.employee,
    filters: request.arguments,
    onSelected: (value) => Navigator.pop(dialogContext, value),
  ),
)
```

Pemanggil tetap memakai `PickerLauncher.open` / `PickerRegistry.open` dengan
`PickerRequest(title: title)`. Registry membaca `PickerPresentation` dari
definisi dan memilih halaman, sheet, atau dialog. `AppPickerFormField.onPick` tetap
menerima `Future<T?>`; pembatalan tidak mengganti nilai field sebelumnya.
Registrasi `PickerDefinition(pageBuilder: ...)` tetap membuka halaman.
Gunakan `PickerDefinition.sheet(contentBuilder: ...)` untuk modal dari bawah.
Ketiga wadah mempertahankan pemeriksaan key/type dari registry. Pembatalan lewat
Close, back, atau tap di luar modal mengembalikan null. Pada pemakaian langsung,
`AppPickerDialog.show(barrierDismissible: false, ...)` menonaktifkan tap di luar;
Close dan back tetap tersedia.

`AppPickerFormField` membatasi satu pemanggilan `onPick` yang masih berjalan per
field, termasuk beberapa tap sebelum rebuild. Pembatalan mengaktifkan field
kembali tanpa mengganti nilainya. Hasil terlambat diabaikan jika widget/field
sudah dilepas, nilai dari host mengganti instance FormField, atau field menjadi
disabled/read-only. Launcher tetap bertanggung jawab atas penanganan errornya;
status sedang memilih dibersihkan melalui `finally`.

Pencarian reference picker memakai debounce 300 ms. Tombol Search pada keyboard
langsung mengirim query dan membatalkan timer tertunda; penutupan picker juga
membatalkan timer. RequestListController mengabaikan respons query lama setelah
query baru dimulai, sehingga hasil terbaru tidak ditimpa respons terlambat.

Tombol aksi pada fondasi Request (workspace, form, remark dialog, pagination,
dan file picker) memakai `AppButton`; spacing memakai `AppSpacing`. Radius
interaksi picker field memakai `AppRadius`. Kebijakan workflow, eligibility,
payload, validasi custom field, dan nilai wire tetap dimiliki kontrak/fitur.

Pada saat pemisahan ini, `AppResultPage` baru digunakan oleh test, sedangkan
registrasi reference picker Attendance masih ada di branch CR dan masih
berbentuk halaman. Branch CR dan pemakaian legacy tidak diubah oleh refactor ini.
