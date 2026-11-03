import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (mode, theme, palette, status) in [
    ('light', AppTheme.light(), AppColors.light, AppResultStatus.success),
    ('dark', AppTheme.dark(), AppColors.dark, AppResultStatus.failure),
  ]) {
    testWidgets(
      'centered $mode dialog returns typed actions and preserves its host',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await AppResultDialog.show<bool>(
                      context,
                      builder: (dialogContext) => AppResultContent(
                        status: status,
                        title: 'Result',
                        message: 'Review the operation result.',
                        primaryActionLabel: 'Continue',
                        onPrimaryAction: () =>
                            Navigator.pop(dialogContext, true),
                        secondaryActionLabel: 'Review',
                        onSecondaryAction: () =>
                            Navigator.pop(dialogContext, false),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(AppResultContent), findsOneWidget);
        final material = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first;
        expect(tester.widget<Material>(material).color, palette.popover);
        final rect = tester.getRect(material);
        expect(rect.center.dx, closeTo(400, 1));
        expect(rect.center.dy, closeTo(300, 1));
        expect(rect.width, lessThanOrEqualTo(520));
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();
        expect(result, false);
        expect(find.text('Open'), findsOneWidget);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(result, true);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'dialog cancellation returns null and barrier taps are configurable',
    (tester) async {
      var barrierDismissible = true;
      var resolved = false;
      bool? result = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  resolved = false;
                  result = await AppResultDialog.show<bool>(
                    context,
                    barrierDismissible: barrierDismissible,
                    builder: (dialogContext) => AppResultContent(
                      status: AppResultStatus.success,
                      title: 'Saved',
                      message: 'Completed.',
                      primaryActionLabel: 'Continue',
                      onPrimaryAction: () => Navigator.pop(dialogContext, true),
                    ),
                  );
                  resolved = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(resolved, true);
      expect(result, isNull);
      expect(find.byType(Dialog), findsNothing);
      barrierDismissible = false;
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(resolved, false);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(resolved, true);
      expect(result, isNull);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'long dialog scrolls to its action with large text and a keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await AppResultDialog.show<String>(
                    context,
                    builder: (dialogContext) => AppResultContent(
                      status: AppResultStatus.failure,
                      title: 'Please review',
                      message: List.filled(
                        20,
                        'The selected period is closed.',
                      ).join('\n'),
                      primaryActionLabel: 'Back to form',
                      onPrimaryAction: () =>
                          Navigator.pop(dialogContext, 'review'),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final material = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getRect(material).bottom, lessThanOrEqualTo(400));
      await tester.ensureVisible(find.text('Back to form'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to form'));
      await tester.pumpAndSettle();
      expect(result, 'review');
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
  );
}
