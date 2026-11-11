import 'package:flutter/material.dart';

import '../../localization/l10n/app_localizations.dart';
import '../components/buttons/app_button.dart';
import '../components/typography/app_text.dart';
import '../foundations/app_spacing.dart';

/// Branding shown while the host prepares services or restores the session.
/// Failure feedback stays on the splash; retry is delegated to the host.
/// Timing, initialization, and navigation are owned by the host.
class AppSplashPage extends StatelessWidget {
  const AppSplashPage.loading({super.key, this.version}) : onRetry = null;

  const AppSplashPage.failure({
    super.key,
    this.version,
    required VoidCallback this.onRetry,
  });

  /// Metadata can arrive after initialization starts; omit it until available.
  final String? version;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 20,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/branding/logo.png',
                          package: 'gasione_core_ui',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          semanticLabel: strings.appName,
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            liveRegion: true,
                            child: AppText(
                              strings.appPreparationFailed,
                              textAlign: TextAlign.center,
                              tone: AppTextTone.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton.primary(
                            label: strings.retry,
                            onPressed: onRetry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (version != null)
                AppText(
                  strings.appVersion(version!),
                  textAlign: TextAlign.center,
                  tone: AppTextTone.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
