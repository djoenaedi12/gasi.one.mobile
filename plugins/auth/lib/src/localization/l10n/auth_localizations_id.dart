// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AuthLocalizationsId extends AuthLocalizations {
  AuthLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get dummyJsonStore => 'Toko DummyJSON';

  @override
  String get demoLoginDescription =>
      'Masuk dengan akun demo yang sudah tersedia.';

  @override
  String get username => 'Nama pengguna';

  @override
  String get password => 'Kata sandi';

  @override
  String get signIn => 'Masuk';
}
