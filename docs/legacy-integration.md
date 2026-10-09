# Legacy EPC Integration Runbook

Dokumen ini menjelaskan cara memasukkan aplikasi `epc.client.mobile` ke
workspace `gasi.one.mobile` dengan perubahan perilaku seminimal mungkin.
Target pertama bukan membersihkan arsitektur, melainkan menghasilkan aplikasi
yang setara dengan aplikasi lama dan dapat diterbitkan sebagai update di Store.

Status dokumen: rencana implementasi. Langkah-langkah di bawah belum berarti
sudah diterapkan ke repository.

## Sasaran

- Kode sumber `epc.client.mobile` tetap tersedia sebagai referensi dan tidak
  dimodifikasi.
- Salinan kode lama berada di `plugins/legacy_epc`.
- `platform-app` menjadi executable dan pemilik konfigurasi native Android/iOS.
- Untuk parity release, `platform-app` menjalankan aplikasi legacy
  (`EWorkflowApp`) sebagai satu-satunya application shell.
- Warna, theme, localization, navigation, session, Firebase, geolocation, dan
  alur bisnis lama tetap bekerja seperti sebelumnya.
- `plugins/auth` dan `plugins/catalog` tetap berada di repository sebagai
  contoh, tetapi tidak menjadi dependency runtime `platform-app`.

## Bukan sasaran parity release

- Mengganti `Navigator` dengan `go_router`.
- Mengganti provider/singleton lama dengan Cubit.
- Memindahkan model dan repository lama ke clean architecture.
- Mengganti `EasyLocalization`, `AdaptiveTheme`, atau widget lama.
- Menggunakan auth DummyJSON yang saat ini ada di plugin contoh.
- Mengubah desain halaman lama.

## Bentuk workspace yang dituju

```text
gasi.one.mobile/
├── core-api/
├── core-starter/
├── core-ui/
├── platform-app/                 # executable dan native projects
└── plugins/
    ├── auth/                     # contoh, belum dipakai production app
    ├── catalog/                  # contoh, belum dipakai production app
    └── legacy_epc/               # salinan aplikasi EPC lama
        ├── lib/
        ├── analysis_options.yaml
        └── pubspec.yaml
```

Package `legacy_epc` tetap menggunakan nama Dart package `epeoplecare`.
Dengan demikian import lama seperti berikut tidak perlu ditulis ulang:

```dart
import 'package:epeoplecare/config.dart';
```

Nama folder dan nama package sengaja berbeda. `legacy_epc` menjelaskan peran
foldernya, sedangkan `epeoplecare` mempertahankan kompatibilitas source code.

## 1. Siapkan branch dan baseline

Mulai dari worktree bersih dan simpan hasil build aplikasi lama sebagai
baseline.

```bash
cd /home/gasiwfh/Documents/flutter/gasi.one.mobile
git switch -c migration/legacy-epc-parity

cd ../epc.client.mobile
flutter pub get
flutter analyze
flutter build apk --debug
```

Catat versi Flutter, hasil analyzer, serta warning yang memang sudah ada pada
aplikasi lama. Parity tidak mensyaratkan semua technical debt lama langsung
hilang.

## 2. Buat package legacy

Dari root `gasi.one.mobile`:

```bash
mkdir -p plugins/legacy_epc
cp -a ../epc.client.mobile/lib plugins/legacy_epc/
cp ../epc.client.mobile/analysis_options.yaml plugins/legacy_epc/
```

Jangan memindahkan file dari project lama. Project lama tetap menjadi sumber
pembanding selama proses parity.

Salin `pubspec.yaml` lama ke `plugins/legacy_epc`, lalu ubah metadata berikut:

```yaml
name: epeoplecare
description: Legacy EPC mobile application.
version: 4.15.0+134
publish_to: none

environment:
  sdk: ^3.13.5

resolution: workspace
```

Tambahkan package ke workspace root tanpa menghapus package contoh:

```yaml
workspace:
  - core-api
  - core-starter
  - core-ui
  - platform-app
  - plugins/auth
  - plugins/catalog
  - plugins/legacy_epc
```

## 3. Selaraskan dependency

Setiap package Dart wajib mendeklarasikan package yang di-import secara
langsung. Walaupun dependency yang sama sudah digunakan `core-starter`,
`legacy_epc` tetap perlu mendeklarasikannya.

Gunakan constraint yang selaras dengan workspace:

| Dependency | Constraint legacy lama | Constraint workspace |
| --- | --- | --- |
| `firebase_core` | `^3.13.0` | `^4.15.0` |
| `firebase_messaging` | `^15.2.5` | `^16.7.0` |
| `flutter_local_notifications` | `^19.1.0` | `^22.3.1` |
| `geocoding` | `^3.0.0` | `^5.0.0` |
| `geolocator` | `^14.0.0` | `^14.1.1` |
| `permission_handler` | `^12.0.0+1` | `^12.0.3` |
| `shared_preferences` | `^2.5.3` | `^2.5.5` |

Dependency lama lainnya dipertahankan dahulu. Jalankan `flutter pub get` dari
root workspace karena seluruh package workspace menggunakan satu resolution.
Apabila terjadi breaking API, lakukan compatibility patch hanya pada salinan di
`plugins/legacy_epc`; jangan mengubah alur atau desain sekaligus.

Contoh compatibility patch yang diperbolehkan:

- penyesuaian signature method plugin;
- penggantian API deprecated yang sudah dihapus;
- penyesuaian null-safety atau type;
- penyesuaian konfigurasi Android/iOS untuk versi plugin baru.

Refactor repository, perubahan state management, dan redesign bukan bagian
dari patch ini.

## 4. Pertahankan asset key lama

Kode lama memuat asset dengan key global seperti `assets/img/logo.png` dan
`assets/i18n`. Asset milik dependency package biasanya membutuhkan package
prefix, sehingga meletakkan asset hanya di `legacy_epc` dapat mengubah key-nya.

Untuk parity, copy asset ke aplikasi utama:

```bash
cp -a ../epc.client.mobile/assets/. platform-app/assets/
```

Daftarkan dari `platform-app/pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/img/
    - assets/i18n/en.json
    - assets/i18n/id.json
    - assets/ca/
```

`assets/images/` milik struktur baru boleh tetap ada. Deklarasi asset lama di
pubspec `legacy_epc` tidak diperlukan selama source masih memakai key global.

## 5. Jadikan platform-app launcher tipis

Versi production pertama dari repository baru harus lebih tinggi dari build
Store terakhir. Jika versi terakhir adalah `4.15.0+134`, gunakan minimal:

```yaml
version: 4.15.0+135
```

Dependency production `platform-app` cukup mengarah ke package legacy:

```yaml
dependencies:
  flutter:
    sdk: flutter
  epeoplecare: ^4.15.0
```

Karena menggunakan Pub workspace, gunakan version constraint di atas, bukan
`path:`. `plugins/auth` dan `plugins/catalog` tetap berada di workspace tetapi
tidak didaftarkan sebagai dependency `platform-app`.

Entry point minimum:

```dart
import 'package:epeoplecare/main.dart' as legacy;

void main() => legacy.main();
```

Pada tahap ini `EWorkflowApp` tetap menjadi satu-satunya `MaterialApp`.
`AdaptiveTheme`, `EasyLocalization`, `EasyLoading`, `Config.navigatorKey`, dan
route lama tetap dimiliki aplikasi legacy.

File shell contoh yang masih mengimpor plugin auth/catalog tidak boleh tetap
menjadi source aktif `platform-app` setelah dependency tersebut dihapus dari
pubspec. Simpan melalui Git atau pindahkan menjadi package contoh terpisah.
Jangan sekadar membiarkan import tidak ter-resolve, karena `flutter analyze`
tetap memeriksa file yang tidak dipanggil oleh `main.dart`.

## 6. Ownership Firebase dan geolocation

Selama parity release, ownership-nya adalah:

```text
platform-app
├── Android/iOS configuration, permissions, signing
└── legacy_epc
    ├── Firebase initialization dan messaging behavior
    ├── local notification behavior
    └── geolocation/geocoding behavior
```

Dependency Firebase dan location dideklarasikan langsung oleh `legacy_epc`.
`platform-app` tidak perlu mendeklarasikannya jika tidak mengimpor API tersebut.
Native plugin tetap ikut ke binary secara transitif.

Firebase hanya boleh diinisialisasi satu kali. Selama launcher menjalankan
legacy app, jangan sekaligus membuat `FirebaseNotificationService` dari
`core-starter`. `firebase_options.dart` lama tetap digunakan sampai Firebase
dipindahkan dengan sengaja pada fase berikutnya.

## 7. Merge native configuration

Gunakan folder Android/iOS baru sebagai basis. Jangan menyalin seluruh folder
native lama karena dapat menurunkan versi AGP, Kotlin, Java, atau project
settings baru.

### Android

Pertahankan dari project baru:

- Android Gradle Plugin dan Kotlin plugin baru;
- Java 17;
- struktur Gradle/Flutter terbaru.

Merge dari project lama:

- `applicationId` dan `namespace` production;
- minimum SDK yang dibutuhkan plugin dan aplikasi lama;
- release signing configuration;
- signing certificate lama;
- `google-services.json`;
- camera, biometric, internet, location, dan notification permission;
- application label, notification metadata, dan launch mode;
- icon, splash, dan resource production.

Jangan memasukkan password keystore atau signing key baru ke Git. Update Play
Store wajib ditandatangani dengan certificate yang sama dengan release lama.

### iOS

Merge dari project lama:

- production bundle identifier;
- Apple team, signing, dan provisioning;
- `GoogleService-Info.plist`;
- `Runner.entitlements`;
- camera, Face ID, location, microphone, dan photo-library descriptions;
- background modes dan Firebase messaging settings;
- application display name, icon, dan splash.

Pertahankan project structure dan deployment configuration baru jika tidak ada
alasan kompatibilitas untuk menggantinya.

## 8. Verifikasi bertahap

Lakukan verifikasi per checkpoint. Jangan menunggu seluruh integrasi selesai.

### Checkpoint A: dependency

```bash
cd /home/gasiwfh/Documents/flutter/gasi.one.mobile
flutter pub get
```

### Checkpoint B: legacy package

```bash
cd plugins/legacy_epc
flutter analyze
```

### Checkpoint C: application

```bash
cd ../../platform-app
flutter analyze
flutter run
```

### Checkpoint D: behavior parity

Verifikasi minimal:

- client selection dan client URL;
- login, OTP/MFA, restore session, dan logout;
- verification method/local authentication;
- theme dan warna per client;
- localization Inggris/Indonesia;
- FCM token, foreground notification, dan notification tap;
- permission serta pengambilan lokasi;
- attendance/check-in;
- camera/image picker;
- upload, download, PDF, dan share;
- switch account;
- response 401, license invalid, rate limit, dan maintenance.

### Checkpoint E: Store artifact

```bash
cd platform-app
flutter build appbundle --release
```

Sebelum upload, cocokkan application ID/bundle ID, signing certificate,
version/build number, Firebase project, icon, privacy declarations, dan runtime
permissions dengan release production sebelumnya. Distribusikan dahulu melalui
internal testing sebelum production rollout.

## Definition of done parity release

Parity release selesai bila:

- aplikasi dibangun dari `gasi.one.mobile/platform-app`;
- source runtime lama berada di `plugins/legacy_epc`;
- auth/catalog contoh tidak menjadi dependency `platform-app`;
- UI dan warna halaman lama tidak berubah secara sengaja;
- alur kritis pada checklist parity lulus di Android dan iOS;
- AAB/IPA memakai identity dan signing production lama;
- tidak ada dua Firebase initialization atau dua pemilik session;
- build dapat dikembalikan ke source lama bila ditemukan regression kritis.

