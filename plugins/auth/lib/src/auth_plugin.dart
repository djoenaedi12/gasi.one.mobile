import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:gasione_plugin_auth/src/data/repositories/auth_repository_impl.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';
import 'package:gasione_plugin_auth/src/localization/l10n/auth_localizations.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/auth_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/login_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/pages/login_page.dart';

abstract final class AuthRoutes {
  static const login = '/login';
}

final class AuthPlugin implements AppPlugin {
  AuthPlugin._({
    required this.repository,
    required this.authCubit,
    required this._loginActionsBuilder,
    required this.initialUsername,
    required this.initialPassword,
  });

  factory AuthPlugin.fromRepository(
    AuthRepository repository, {
    AuthUser? initialUser,
    WidgetBuilder? loginActionsBuilder,
    String initialUsername = '',
    String initialPassword = '',
  }) {
    return AuthPlugin._(
      repository: repository,
      authCubit: AuthCubit(repository, initialUser),
      loginActionsBuilder: loginActionsBuilder,
      initialUsername: initialUsername,
      initialPassword: initialPassword,
    );
  }

  static Future<AuthPlugin> create({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    WidgetBuilder? loginActionsBuilder,
    String initialUsername = '',
    String initialPassword = '',
  }) async {
    final repository = AuthRepositoryImpl(
      AuthRemoteDataSource(apiClient),
      tokenStorage,
    );
    final sessionResult = await repository.restoreSession();
    final initialUser = switch (sessionResult) {
      Success(:final data) => data,
      FailureResult() => null,
    };

    return AuthPlugin._(
      repository: repository,
      authCubit: AuthCubit(repository, initialUser),
      loginActionsBuilder: loginActionsBuilder,
      initialUsername: initialUsername,
      initialPassword: initialPassword,
    );
  }

  final AuthRepository repository;
  final AuthCubit authCubit;
  final WidgetBuilder? _loginActionsBuilder;
  final String initialUsername;
  final String initialPassword;

  @override
  String get code => 'auth';

  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    AuthLocalizations.delegate,
  ];

  @override
  List<Locale> get supportedLocales => AuthLocalizations.supportedLocales;

  @override
  List<PluginMenuItem> get menus => const [];

  @override
  List<PluginRoute> get routes => [
    PluginRoute(
      path: AuthRoutes.login,
      builder: (context, state) => BlocProvider(
        create: (_) => LoginCubit(repository),
        child: LoginPage(
          actions:
              _loginActionsBuilder?.call(context) ?? const SizedBox.shrink(),
          initialUsername: initialUsername,
          initialPassword: initialPassword,
        ),
      ),
    ),
  ];
}
