# Migrasi business context

`plugins/business_context` sekarang menjadi pemilik pemuatan data setelah token
auth tersedia dan sebelum Home dibuka. Plugin ini tidak mengimpor `auth`,
`platform-app`, atau `legacy_epc`; seluruh dependency runtime diinjeksikan oleh
composition root.

## Alur aktif

```text
Restore session pada main (login/OTP plugin pada branch CR)
  -> platform membaca seed instalasi melalui compatibility bridge
  -> BusinessContextPlugin.load(username)
     -> GET user beserta role/menu/access right
     -> validasi SESSION_MOBILE_DEVICE saat login baru
     -> PUT device ID
     -> muat license, timezone, SHOW_DISABLED_MENU, SWITCH_ACCOUNT
     -> muat status manager
     -> hasilkan BusinessContext
     -> registrasi token FCM ke backend secara best effort
  -> LegacyBusinessContextAdapter memasang context ke Config
  -> verifikasi lokal
  -> Home legacy
```

Restore aplikasi tidak mengulang penolakan single-device, sesuai perilaku lama,
tetapi tetap mengikat device ID. Login/OTP baru menjalankan validasi single-device
dan mengembalikan failure `DEVICE_NOT_SAME` jika perangkat tidak sesuai. Failure
ini membatalkan session yang baru ditulis oleh auth.

## Kepemilikan

| Bagian | Pemilik |
| --- | --- |
| Token/company/login/OTP pada main | legacy melalui composition boundary |
| Target token/company/login/OTP setelah CR | `plugins/auth` |
| User, menu, permission, license, parameter, manager | `plugins/business_context` |
| Device policy dan binding device ID | service di `plugins/business_context` |
| Registrasi FCM backend | service di `plugins/business_context` |
| Firebase/native notification lifecycle | `core-starter` dan `platform-app` |
| Urutan auth -> context -> verifikasi -> Home | `platform-app` |
| Mapping sementara ke `Config` | compatibility adapter/bridge |

`BusinessUser.compatibilityPayload` sengaja menyimpan graph user lengkap untuk
`User.fromJson` legacy. Field ini bertanda `TRANSITION[LEGACY-BUSINESS-CONTEXT]`
dan dihapus setelah Home serta fitur bisnis memakai `BusinessUser.menus` dan
`BusinessUser.permissions` secara langsung.

## Kompatibilitas instalasi

License cache masih membaca key `license`, `expiry_date`, `modules`,
`company_code`, dan `host_name`. Token FCM backend tetap disimpan pada key
`fcmToken`. Seluruhnya bertanda `COMPAT[INSTALLED-DATA]`; penghapusan EPC tidak
otomatis mengizinkan perubahan format tersebut.

## Batas legacy tersisa

`LegacyBusinessContextBridge` adalah satu-satunya kode yang mengakses provider,
model, dan `Config` EPC untuk flow ini. `platform-app` hanya mengimpor public
surface `package:epeoplecare/legacy_epc.dart`. Setelah Home dan pemanggil bisnis
tidak membaca `Config`, hapus:

- `LegacyBusinessContextAdapter` di platform;
- `LegacyBusinessContextBridge` dan snapshot license di legacy;
- `BusinessUser.compatibilityPayload`;
- callback `LegacyEpcModule.businessContextChanged`.

Plugin `business_context`, model domain, repository Dio, device policy, dan
registrasi push backend tetap digunakan sesudah cleanup tersebut.

## Typed contract untuk plugin baru

`BusinessContextProvider` di `core-api` menyediakan `ActiveBusinessContext`
(company, employee, username, permission, manager, timezone, dan opaque session
ID) serta stream perubahan. `BusinessUser.employee` dipetakan dari user payload,
bukan dari model legacy. `BusinessContextPlugin` mengimplementasikan provider
tersebut dan menolak load lama yang selesai setelah clear/load berikutnya.

Di main, login existing masih menulis `Config`. `LegacyEpcModule` mengadaptasinya
ke contract yang sama agar feature baru tidak membaca `Config`. Platform
menginvalisasi generasi shared SessionStore saat sesi berubah dan membersihkan
context saat expiry. CR Pre-Home dapat mengganti provider ini dengan
`BusinessContextPlugin` setelah semua pemanggil auth dimigrasikan.
