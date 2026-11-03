import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

Widget _app({
  ThemeData? theme,
  Locale locale = const Locale('en'),
  required WidgetBuilder builder,
}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: Builder(builder: builder)),
);

void main() {
  for (final (mode, theme, palette) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    testWidgets('feedback variants follow $mode tokens and retain text', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        _app(
          theme: theme,
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      );
      for (final (show, message, background, foreground, icon) in [
        (
          AppSnackbar.success,
          'Saved',
          palette.success,
          palette.successForeground,
          Icons.check_circle_outline,
        ),
        (
          AppSnackbar.error,
          'Save failed',
          palette.destructive,
          palette.destructiveForeground,
          Icons.error_outline,
        ),
        (
          AppSnackbar.warning,
          'Some items failed',
          palette.warning,
          palette.warningForeground,
          Icons.warning_amber_rounded,
        ),
        (
          AppSnackbar.info,
          'Updated information',
          palette.info,
          palette.infoForeground,
          Icons.info_outline,
        ),
      ]) {
        show(context, message);
        await tester.pumpAndSettle();
        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(bar.backgroundColor, background);
        expect(bar.behavior, SnackBarBehavior.floating);
        expect(
          tester.widget<Text>(find.text(message)).style?.color,
          foreground,
        );
        expect(tester.widget<Icon>(find.byIcon(icon)).color, foreground);
      }
    });
  }

  testWidgets('new feedback replaces queued messages and can be closed', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        builder: (value) {
          context = value;
          return const SizedBox();
        },
      ),
    );
    AppSnackbar.info(context, 'Old');
    await tester.pumpAndSettle();
    AppSnackbar.info(context, 'Pending');
    AppSnackbar.success(context, 'Latest');
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Latest'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('feedback expires and permits page interaction', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _app(
        builder: (context) => TextButton(
          onPressed: () {
            presses++;
            AppSnackbar.info(context, 'Information');
          },
          child: const Text('Action'),
        ),
      ),
    );
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(presses, 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failures use the current locale and cancellation stays silent', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        locale: const Locale('id'),
        builder: (value) {
          context = value;
          return const SizedBox();
        },
      ),
    );
    AppSnackbar.failure(context, const CancelledFailure());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    AppSnackbar.failure(
      context,
      const UnauthorizedFailure(message: 'JWT expired at 123'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Sesi Anda sudah tidak valid. Silakan masuk kembali.'),
      findsOneWidget,
    );
    expect(find.textContaining('JWT'), findsNothing);
    AppSnackbar.failure(context, const CancelledFailure());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
