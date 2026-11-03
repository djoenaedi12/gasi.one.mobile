import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (name, theme, palette) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    testWidgets(
      '$name picker dialog is centered and returns a typed selection',
      (tester) async {
        int? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selected = await AppPickerDialog.show<int>(
                      context,
                      title: 'Choose employee',
                      builder: (dialogContext) => ListView(
                        children: [
                          ListTile(
                            title: const Text('Employee 7'),
                            onTap: () => Navigator.pop(dialogContext, 7),
                          ),
                        ],
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
        expect(find.text('Choose employee'), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
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
        await tester.tap(find.text('Employee 7'));
        await tester.pumpAndSettle();
        expect(selected, 7);
        expect(find.text('Open'), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
      },
    );
  }

  testWidgets(
    'dialog reserves bounded list space when keyboard and large text are used',
    (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      var search = '';
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await AppPickerDialog.show<int>(
                    context,
                    title: 'Choose an employee',
                    builder: (dialogContext) => Column(
                      children: [
                        TextField(onChanged: (value) => search = value),
                        Expanded(
                          child: ListView(
                            children: [
                              for (var i = 0; i < 20; i++)
                                ListTile(
                                  title: Text('Employee $i'),
                                  onTap: () => Navigator.pop(dialogContext, i),
                                ),
                            ],
                          ),
                        ),
                      ],
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
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'employee');
      await tester.pumpAndSettle();
      expect(search, 'employee');
      expect(
        tester.getBottomLeft(find.byType(ListView)).dy,
        lessThanOrEqualTo(460),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Employee 19'),
        250,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Employee 19'));
      await tester.pumpAndSettle();
      expect(selected, 19);
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('barrier and close button return null while retaining the host', (
    tester,
  ) async {
    var barrierDismissible = true;
    var resolved = false;
    int? selected = 7;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resolved = false;
                selected = await AppPickerDialog.show<int>(
                  context,
                  barrierDismissible: barrierDismissible,
                  builder: (_) => const Center(child: Text('Choose')),
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
    expect(selected, isNull);
    expect(resolved, true);
    barrierDismissible = false;
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(resolved, false);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(resolved, true);
    expect(selected, isNull);
    expect(find.text('Open'), findsOneWidget);
  });
}
