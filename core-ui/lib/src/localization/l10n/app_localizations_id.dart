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
  String get signOut => 'Keluar';

  @override
  String get requiredField => 'Kolom ini wajib diisi.';

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
}
