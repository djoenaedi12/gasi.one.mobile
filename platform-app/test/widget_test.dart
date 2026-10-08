import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/theme/theme_cubit.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';

import 'helpers/memory_preferences_storage.dart';

void main() {
  testWidgets('shows the login form', (tester) async {
    final preferences = MemoryPreferencesStorage();
    final repository = _NoopAuthRepository();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => LocaleCubit(preferences)),
          BlocProvider(create: (_) => AuthCubit(repository, null)),
          BlocProvider(create: (_) => LoginCubit(repository)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginPage(),
        ),
      ),
    );

    expect(find.text('DummyJSON Store'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthUser?>> restoreSession() async => const Success(null);

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> logout() async => const Success(null);
}
