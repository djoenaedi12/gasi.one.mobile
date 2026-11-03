// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'GASI:One';

  @override
  String get loading => 'Memuat';

  @override
  String appVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get preparingApp => 'Menyiapkan aplikasi…';

  @override
  String get appPreparationFailed =>
      'Aplikasi belum dapat disiapkan. Silakan coba lagi.';

  @override
  String get signOut => 'Keluar';

  @override
  String get requiredField => 'Kolom ini wajib diisi.';

  @override
  String createResource(String resource) {
    return 'Tambah $resource';
  }

  @override
  String editResource(String resource) {
    return 'Ubah $resource';
  }

  @override
  String selectResource(String resource) {
    return 'Pilih $resource';
  }

  @override
  String noResources(String resource) {
    return '$resource belum tersedia';
  }

  @override
  String get noDataAvailable => 'Belum ada data tersedia.';

  @override
  String get noOptionsAvailable => 'Belum ada pilihan tersedia.';

  @override
  String deleteResourceQuestion(String resource) {
    return 'Hapus $resource?';
  }

  @override
  String deleteRecordQuestion(String label) {
    return 'Hapus $label?';
  }

  @override
  String validationRequired(String field) {
    return '$field wajib diisi.';
  }

  @override
  String validationMaxLength(String field, int maxLength) {
    return '$field maksimal $maxLength karakter.';
  }

  @override
  String validationWholeNumber(String field) {
    return '$field harus berupa bilangan bulat yang valid.';
  }

  @override
  String validationNumber(String field) {
    return '$field harus berupa angka yang valid.';
  }

  @override
  String validationIsoDate(String field) {
    return '$field harus berupa tanggal ISO yang valid.';
  }

  @override
  String get home => 'Beranda';

  @override
  String get mainMenuDescription => 'Pilih menu untuk mengelola data aplikasi.';

  @override
  String helloUser(String name) {
    return 'Halo, $name';
  }

  @override
  String get title => 'Nama';

  @override
  String get description => 'Deskripsi';

  @override
  String get search => 'Cari';

  @override
  String get code => 'Kode';

  @override
  String get name => 'Nama';

  @override
  String get edit => 'Ubah';

  @override
  String get delete => 'Hapus';

  @override
  String get add => 'Tambah';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get retry => 'Coba lagi';

  @override
  String get operationSuccessful => 'Operasi berhasil';

  @override
  String get operationFailed => 'Operasi gagal.';

  @override
  String get networkError =>
      'Tidak dapat terhubung. Periksa koneksi internet Anda.';

  @override
  String get timeoutError => 'Waktu permintaan habis. Silakan coba lagi.';

  @override
  String get unauthorizedError =>
      'Sesi Anda sudah tidak valid. Silakan masuk kembali.';

  @override
  String get forbiddenError =>
      'Anda tidak memiliki izin untuk melakukan tindakan ini.';

  @override
  String get notFoundError => 'Data yang diminta tidak ditemukan.';

  @override
  String get validationError => 'Beberapa data yang dikirim tidak valid.';

  @override
  String get conflictError => 'Permintaan bertentangan dengan data saat ini.';

  @override
  String get rateLimitError =>
      'Terlalu banyak permintaan. Tunggu lalu coba lagi.';

  @override
  String get serverError => 'Server mengalami masalah. Silakan coba lagi.';

  @override
  String get invalidResponseError => 'Respons server tidak valid.';

  @override
  String get requestCancelled => 'Permintaan dibatalkan.';

  @override
  String get unknownError => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get switchTheme => 'Ganti tema';

  @override
  String get switchLanguage => 'Ganti bahasa';

  @override
  String get english => 'Inggris';

  @override
  String get indonesian => 'Indonesia';

  @override
  String get pageNotFound => 'Halaman tidak ditemukan';

  @override
  String routeNotFound(String routeName) {
    return 'Rute $routeName tidak ditemukan.';
  }

  @override
  String get loadMore => 'Muat lebih banyak';

  @override
  String get unsafeDeviceTitle => 'Perangkat tidak memenuhi standar keamanan';

  @override
  String get unsafeDeviceMessage =>
      'GASI:One memerlukan perangkat fisik tanpa root atau jailbreak, dengan mode pengembang dinonaktifkan, dan aplikasi terpasang di penyimpanan internal.\n\nGunakan perangkat lain jika perangkat di-root, di-jailbreak, atau berupa emulator. Nonaktifkan mode pengembang, atau pasang ulang di penyimpanan internal bila diperlukan.\n\nHubungi administrator jika membutuhkan bantuan.';

  @override
  String get invalidApplicationTitle => 'Aplikasi tidak valid';

  @override
  String get invalidApplicationMessage =>
      'Signature aplikasi tidak cocok. Silakan pasang ulang aplikasi dari toko resmi.';

  @override
  String get exitApplication => 'Keluar';

  @override
  String get unsafeDeviceIntroduction =>
      'Demi keamanan data Anda, GASI:One hanya berjalan pada perangkat yang memenuhi persyaratan berikut:';

  @override
  String get deviceIntegrityRequirement =>
      'Tidak di-root, di-jailbreak, atau berupa emulator';

  @override
  String get developerModeRequirement => 'Mode pengembang dinonaktifkan';

  @override
  String get internalStorageRequirement => 'Terpasang di penyimpanan internal';

  @override
  String get deviceRemediationTitle => 'Silakan:';

  @override
  String get deviceIntegrityRemediation =>
      'Gunakan perangkat lain jika di-root, di-jailbreak, atau berupa emulator';

  @override
  String get developerModeRemediation =>
      'Nonaktifkan mode pengembang jika masih aktif';

  @override
  String get internalStorageRemediation =>
      'Pasang ulang di penyimpanan internal jika terpasang di kartu SD';

  @override
  String get deviceAdministratorHelp =>
      'Atau hubungi Administrator jika diperlukan.';

  @override
  String get deviceRequirementMet => 'Persyaratan terpenuhi';

  @override
  String get deviceRequirementNotMet => 'Persyaratan tidak terpenuhi';

  @override
  String get deviceRequirementUnavailable => 'Hasil pemeriksaan tidak tersedia';

  @override
  String appCopyright(int year) {
    return '© $year GASI:One';
  }
}
