import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/src/design_system/components/buttons/app_button.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_text.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_radius.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_semantic_colors.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';
import 'package:gasione_core_ui/src/localization/l10n/app_localizations.dart';

/// Shared security feedback. The host supplies observations and an exit action;
/// this page never checks the device, decides access, or terminates the process.
class AppDeviceAccessDeniedPage extends StatelessWidget {
  const AppDeviceAccessDeniedPage({
    super.key,
    required this.security,
    required this.onExit,
  });

  final DeviceSecurity security;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xl + AppSpacing.xs,
                          bottom: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeading(context, strings),
                            if (security.signatureValid)
                              ..._buildDeviceRequirements(strings)
                            else ...[
                              const SizedBox(height: AppSpacing.md),
                              AppText(
                                strings.invalidApplicationMessage,
                                textAlign: TextAlign.center,
                                tone: AppTextTone.muted,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    AppButton.primary(
                      label: strings.exitApplication,
                      onPressed: onExit,
                      expand: true,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppText(
                      strings.appCopyright(DateTime.now().year),
                      textAlign: TextAlign.center,
                      variant: AppTextVariant.bodySmall,
                      tone: AppTextTone.muted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(BuildContext context, AppLocalizations strings) {
    final semantic = context.semanticColors;
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: semantic.warningContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: semantic.onWarningContainer,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md + AppSpacing.xxs),
        AppText(
          security.signatureValid
              ? strings.unsafeDeviceTitle
              : strings.invalidApplicationTitle,
          textAlign: TextAlign.center,
          variant: AppTextVariant.titleLarge,
        ),
      ],
    );
  }

  List<Widget> _buildDeviceRequirements(AppLocalizations strings) {
    final report = security.report;
    final requirements = [
      (
        label: strings.deviceIntegrityRequirement,
        met: report == null ? null : !report.jailbroken && report.realDevice,
      ),
      (
        label: strings.developerModeRequirement,
        met: report == null ? null : !report.developmentMode,
      ),
      (
        label: strings.internalStorageRequirement,
        met: report == null ? null : !report.externalStorage,
      ),
    ];
    return [
      const SizedBox(height: AppSpacing.sm),
      AppText(
        strings.unsafeDeviceIntroduction,
        textAlign: TextAlign.center,
        tone: AppTextTone.muted,
      ),
      const SizedBox(height: AppSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < requirements.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppSpacing.lg,
                      child: AppText('${index + 1}.'),
                    ),
                    Expanded(child: AppText(requirements[index].label)),
                    const SizedBox(width: AppSpacing.xs),
                    _RequirementStatus(
                      requirement: requirements[index].label,
                      met: requirements[index].met,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppText(strings.deviceRemediationTitle),
            const SizedBox(height: AppSpacing.xs),
            _NumberedInstruction(
              number: 1,
              text: strings.deviceIntegrityRemediation,
            ),
            _NumberedInstruction(
              number: 2,
              text: strings.developerModeRemediation,
            ),
            _NumberedInstruction(
              number: 3,
              text: strings.internalStorageRemediation,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(strings.deviceAdministratorHelp, tone: AppTextTone.muted),
          ],
        ),
      ),
    ];
  }
}

class _RequirementStatus extends StatelessWidget {
  const _RequirementStatus({required this.requirement, required this.met});

  final String requirement;
  final bool? met;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final semantic = context.semanticColors;
    final colors = Theme.of(context).colorScheme;
    final (status, icon, foreground, background) = switch (met) {
      true => (
        strings.deviceRequirementMet,
        Icons.check_rounded,
        semantic.onSuccessContainer,
        semantic.successContainer,
      ),
      false => (
        strings.deviceRequirementNotMet,
        Icons.close_rounded,
        semantic.onWarningContainer,
        semantic.warningContainer,
      ),
      null => (
        strings.deviceRequirementUnavailable,
        Icons.question_mark_rounded,
        colors.onSurfaceVariant,
        colors.surfaceContainer,
      ),
    };
    return Semantics(
      label: '$requirement: $status',
      child: Tooltip(
        message: status,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _NumberedInstruction extends StatelessWidget {
  const _NumberedInstruction({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      bottom: AppSpacing.xxs,
      left: AppSpacing.xxs,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('$number. '),
        Expanded(child: AppText(text)),
      ],
    ),
  );
}
