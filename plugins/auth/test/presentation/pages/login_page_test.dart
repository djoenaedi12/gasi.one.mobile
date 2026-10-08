import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';
import 'package:gasione_plugin_auth/src/localization/l10n/auth_localizations.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/auth_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/auth_state.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/login_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/pages/login_page.dart';

void main() {
  testWidgets('logs in with the pre-filled demo credentials', (tester) async {
    final repository = _FakeAuthRepository();
    final authCubit = AuthCubit(repository, null);
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider(create: (_) => LoginCubit(repository)),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            AuthLocalizations.delegate,
          ],
          supportedLocales: {
            ...AppLocalizations.supportedLocales,
            ...AuthLocalizations.supportedLocales,
          }.toList(),
          home: const LoginPage(
            initialUsername: 'emilys',
            initialPassword: 'emilyspass',
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(repository.username, 'emilys');
    expect(repository.password, 'emilyspass');
    expect(authCubit.state, isA<AuthAuthenticated>());
    expect(
      (authCubit.state as AuthAuthenticated).user.fullName,
      'Emily Johnson',
    );
  });

  testWidgets('binds matching API errors to fields', (tester) async {
    final repository = _FakeAuthRepository(
      loginResult: const FailureResult(
        ValidationFailure(
          errors: [
            ErrorDetail(
              code: 'invalid_username',
              field: 'username',
              message: 'Username tidak ditemukan',
            ),
          ],
        ),
      ),
    );

    await _pumpLoginPage(tester, repository);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Username tidak ditemukan'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows unbound API errors in a snackbar', (tester) async {
    final repository = _FakeAuthRepository(
      loginResult: const FailureResult(
        ValidationFailure(
          errors: [
            ErrorDetail(
              code: 'invalid_username',
              field: 'username',
              message: 'Username tidak ditemukan',
            ),
            ErrorDetail(
              code: 'login_failed',
              message: 'Login gagal, silakan coba lagi',
            ),
          ],
        ),
      ),
    );

    await _pumpLoginPage(tester, repository);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Username tidak ditemukan'), findsOneWidget);
    expect(find.text('Login gagal, silakan coba lagi'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

Future<void> _pumpLoginPage(
  WidgetTester tester,
  AuthRepository repository,
) async {
  final authCubit = AuthCubit(repository, null);
  addTearDown(authCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(create: (_) => LoginCubit(repository)),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          AuthLocalizations.delegate,
        ],
        supportedLocales: {
          ...AppLocalizations.supportedLocales,
          ...AuthLocalizations.supportedLocales,
        }.toList(),
        home: const LoginPage(
          initialUsername: 'emilys',
          initialPassword: 'emilyspass',
        ),
      ),
    ),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginResult});

  final Result<AuthUser>? loginResult;
  String? username;
  String? password;

  @override
  Future<Result<AuthUser?>> restoreSession() async => const Success(null);

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) async {
    this.username = username;
    this.password = password;
    if (loginResult case final result?) {
      return result;
    }
    return const Success(
      AuthUser(
        id: 1,
        username: 'emilys',
        email: 'emily@example.com',
        firstName: 'Emily',
        lastName: 'Johnson',
        imageUrl: '',
      ),
    );
  }

  @override
  Future<Result<void>> logout() async => const Success(null);
}
