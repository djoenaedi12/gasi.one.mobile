import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('resolves typography variant and semantic tone from theme', (
    tester,
  ) async {
    final theme = ThemeData(
      extensions: const [
        AppSemanticColors(
          success: Colors.green,
          onSuccess: Colors.white,
          successContainer: Colors.greenAccent,
          onSuccessContainer: Colors.black,
          warning: Colors.orange,
          onWarning: Colors.black,
          warningContainer: Colors.orangeAccent,
          onWarningContainer: Colors.black,
          info: Colors.blue,
          onInfo: Colors.white,
          infoContainer: Colors.blueAccent,
          onInfoContainer: Colors.white,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const AppText(
          'Saved',
          variant: AppTextVariant.title,
          tone: AppTextTone.success,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Saved'));
    final resolvedTheme = Theme.of(tester.element(find.byType(AppText)));
    expect(
      text.style?.fontWeight,
      resolvedTheme.textTheme.titleMedium?.fontWeight,
    );
    expect(
      text.style?.color,
      resolvedTheme.extension<AppSemanticColors>()!.success,
    );
  });
}
