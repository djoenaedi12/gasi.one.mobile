import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione/app/plugin_registry.dart';
import 'package:gasione/app/widgets/app_settings_actions.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.pluginRegistry, super.key});

  final PluginRegistry pluginRegistry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final user = context.select<AuthCubit, AuthUser?>((cubit) {
      return switch (cubit.state) {
        AuthAuthenticated(:final user) => user,
        AuthUnauthenticated() => null,
      };
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.home),
        actions: [
          const AppSettingsActions(),
          IconButton(
            onPressed: () {
              unawaited(context.read<AuthCubit>().logout());
            },
            tooltip: localizations.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = switch (constraints.maxWidth) {
                  < 600 => 3,
                  < 900 => 4,
                  _ => 6,
                };

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user != null) ...[
                              AppText(
                                localizations.helloUser(user.fullName),
                                variant: AppTextVariant.headingSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                            AppText(
                              localizations.mainMenuDescription,
                              tone: AppTextTone.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisExtent: 120,
                        ),
                        delegate: SliverChildListDelegate.fixed([
                          for (final menu in pluginRegistry.activeMenus)
                            _MenuCard(
                              icon: menu.icon,
                              title: menu.titleBuilder(context),
                              onTap: () => context.push(menu.route),
                            ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                title,
                variant: AppTextVariant.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
