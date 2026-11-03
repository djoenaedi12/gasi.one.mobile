import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

Widget _app({ThemeData? theme, VoidCallback? onAction}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  builder: AppLoading.init(),
  home: Scaffold(
    body: Center(
      child: AppButton.primary(label: 'Action', onPressed: onAction ?? () {}),
    ),
  ),
);

Future<void> _animate(WidgetTester tester, Future<void> action) async {
  var completed = false;
  final completion = action.then((_) => completed = true);
  // The spinner never settles. Advance a bounded number of frames instead
  // of pumpAndSettle, including the overlay's deferred first animation frame.
  for (var frame = 0; frame < 20 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(completed, true, reason: 'Overlay transition did not complete.');
  await completion;
  await tester.pump();
}

Future<void> _show(WidgetTester tester, String status) =>
    _animate(tester, AppLoading.show(status: status));

Future<void> _dismiss(WidgetTester tester) =>
    _animate(tester, AppLoading.dismiss());

void main() {
  testWidgets(
    'overlay blocks interaction until dismissed and can be shown again',
    (tester) async {
      var presses = 0;
      await tester.pumpWidget(_app(onAction: () => presses++));
      expect(AppLoading.isVisible, false);
      try {
        await _show(tester, 'Saving');
        expect(AppLoading.isVisible, true);
        expect(find.text('Saving'), findsOneWidget);
        await tester.tap(find.text('Action'), warnIfMissed: false);
        expect(presses, 0);
        await tester.tapAt(const Offset(10, 10));
        expect(AppLoading.isVisible, true);

        await _dismiss(tester);
        expect(AppLoading.isVisible, false);
        expect(find.text('Saving'), findsNothing);
        await tester.tap(find.text('Action'));
        expect(presses, 1);

        await _show(tester, 'Loading again');
        expect(find.text('Loading again'), findsOneWidget);
      } finally {
        await _dismiss(tester);
      }
      expect(AppLoading.isVisible, false);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (name, theme, palette) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    testWidgets('overlay follows $name theme tokens', (tester) async {
      await tester.pumpWidget(_app(theme: theme));
      try {
        await _show(tester, 'Working');
        final status = tester.widget<Text>(find.text('Working'));
        expect(status.style?.color, palette.foreground);
        final containers = tester.widgetList<Container>(
          find.ancestor(
            of: find.text('Working'),
            matching: find.byType(Container),
          ),
        );
        expect(
          containers.any((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == palette.card;
          }),
          true,
        );
      } finally {
        await _dismiss(tester);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
