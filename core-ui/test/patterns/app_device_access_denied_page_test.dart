import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

const _security = DeviceSecurity(
  unsafeDevice: true,
  signatureValid: true,
  report: DeviceSecurityReport(
    jailbroken: false,
    realDevice: true,
    developmentMode: true,
    externalStorage: false,
    signatureValid: true,
  ),
);

void main() {
  for (final (name, theme, palette) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    testWidgets('shared security page uses $name tokens and delegates Exit', (
      tester,
    ) async {
      var exited = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppDeviceAccessDeniedPage(
            security: _security,
            onExit: () => exited = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pageContext = tester.element(
        find.byType(AppDeviceAccessDeniedPage),
      );
      expect(Theme.of(pageContext).scaffoldBackgroundColor, palette.background);
      final heading = tester.widget<Text>(
        find.text('Device Does Not Meet Security Standard'),
      );
      expect(heading.style?.color, palette.foreground);
      final help = tester.widget<Text>(
        find.text('Or contact Administrator if needed.'),
      );
      expect(help.style?.color, palette.mutedForeground);
      final buttonMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(buttonMaterial.color, palette.primary);
      final warningIcon = tester.widget<Icon>(find.byIcon(Icons.close_rounded));
      expect(warningIcon.color, pageContext.semanticColors.onWarningContainer);
      for (final icon in tester.widgetList<Icon>(
        find.byIcon(Icons.check_rounded),
      )) {
        expect(icon.color, pageContext.semanticColors.onSuccessContainer);
      }
      expect(exited, false);
      await tester.tap(find.widgetWithText(AppButton, 'Exit'));
      expect(exited, true);
      expect(tester.takeException(), isNull);
    });
  }
}
