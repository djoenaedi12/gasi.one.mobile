import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._preferences) : super(null);

  static const _preferenceKey = 'settings.locale';
  static const supportedLocales = [Locale('en'), Locale('id')];

  final PreferencesStorage _preferences;

  Future<void> load() async {
    final languageCode = await _preferences.readString(_preferenceKey);
    if (isClosed) return;
    if (supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      emit(Locale(languageCode!));
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (isClosed || !supportedLocales.contains(locale) || state == locale) {
      return;
    }
    emit(locale);
    await _preferences.writeString(_preferenceKey, locale.languageCode);
  }
}
