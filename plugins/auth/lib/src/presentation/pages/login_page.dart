import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/src/localization/l10n/auth_localizations.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/auth_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/login_cubit.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    this.actions = const SizedBox.shrink(),
    this.initialUsername = '',
    this.initialPassword = '',
    super.key,
  });

  final Widget actions;
  final String initialUsername;
  final String initialPassword;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _loginFields = {'username', 'password'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    await context.read<LoginCubit>().login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AuthLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: widget.actions,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: BlocConsumer<LoginCubit, LoginState>(
                      listener: (context, state) {
                        if (state case LoginSuccess(:final user)) {
                          context.read<AuthCubit>().signedIn(user);
                        }
                        if (state case LoginFailure()) {
                          final message = _unboundErrorMessage(
                            state,
                            coreLocalizations,
                          );
                          if (message != null) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(message)));
                          }
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is LoginLoading;
                        final failure = switch (state) {
                          LoginFailure(:final failure) => failure,
                          _ => null,
                        };
                        final usernameError = failure?.fieldError('username');
                        final passwordError = failure?.fieldError('password');
                        final colors = Theme.of(context).colorScheme;
                        return Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 40,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppText(
                                localizations.dummyJsonStore,
                                textAlign: TextAlign.center,
                                variant: AppTextVariant.headingMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AppText(
                                localizations.demoLoginDescription,
                                textAlign: TextAlign.center,
                                tone: AppTextTone.muted,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppTextFormField(
                                controller: _usernameController,
                                label: localizations.username,
                                enabled: !isLoading,
                                prefixIcon: const Icon(Icons.person_outline),
                                textInputAction: TextInputAction.next,
                                validator: _requiredValidator,
                                errorText: usernameError,
                                onChanged: (_) =>
                                    context.read<LoginCubit>().clearFailure(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextFormField(
                                controller: _passwordController,
                                label: localizations.password,
                                enabled: !isLoading,
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: _requiredValidator,
                                errorText: passwordError,
                                onChanged: (_) =>
                                    context.read<LoginCubit>().clearFailure(),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton.primary(
                                label: localizations.signIn,
                                onPressed: _submit,
                                isLoading: isLoading,
                                expand: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  String? _unboundErrorMessage(
    LoginFailure state,
    AppLocalizations localizations,
  ) {
    return state.failure.unboundErrorMessage(
      knownFields: _loginFields,
      fallbackMessage: state.failure.localizedMessage(localizations),
    );
  }
}
