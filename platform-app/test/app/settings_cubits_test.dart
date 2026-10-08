import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/theme/theme_cubit.dart';

import '../helpers/memory_preferences_storage.dart';

void main() {
  test('theme selection is persisted and restored', () async {
    final preferences = MemoryPreferencesStorage();
    final cubit = ThemeCubit(preferences);
    final restoredCubit = ThemeCubit(preferences);
    addTearDown(cubit.close);
    addTearDown(restoredCubit.close);

    await cubit.setThemeMode(ThemeMode.dark);
    await restoredCubit.load();

    expect(restoredCubit.state.themeMode, ThemeMode.dark);
  });

  test('locale selection is persisted and restored', () async {
    final preferences = MemoryPreferencesStorage();
    final cubit = LocaleCubit(preferences);
    final restoredCubit = LocaleCubit(preferences);
    addTearDown(cubit.close);
    addTearDown(restoredCubit.close);

    await cubit.setLocale(const Locale('id'));
    await restoredCubit.load();

    expect(restoredCubit.state, const Locale('id'));
  });
}
