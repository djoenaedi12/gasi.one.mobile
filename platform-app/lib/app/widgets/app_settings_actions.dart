import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/theme/theme_cubit.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

class AppSettingsActions extends StatelessWidget {
  const AppSettingsActions({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final locale = context.watch<LocaleCubit>().state;
    final currentLanguageCode =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            unawaited(context.read<ThemeCubit>().toggle(brightness));
          },
          tooltip: localizations.switchTheme,
          icon: Icon(
            brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
        PopupMenuButton<String>(
          initialValue: currentLanguageCode,
          tooltip: localizations.switchLanguage,
          icon: const Icon(Icons.language),
          onSelected: (languageCode) {
            unawaited(
              context.read<LocaleCubit>().setLocale(Locale(languageCode)),
            );
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'id', child: Text(localizations.indonesian)),
            PopupMenuItem(value: 'en', child: Text(localizations.english)),
          ],
        ),
      ],
    );
  }
}
