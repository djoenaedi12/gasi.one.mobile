// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AuthLocalizationsEn extends AuthLocalizations {
  AuthLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dummyJsonStore => 'DummyJSON Store';

  @override
  String get demoLoginDescription =>
      'Sign in with the pre-filled demo account.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';
}
