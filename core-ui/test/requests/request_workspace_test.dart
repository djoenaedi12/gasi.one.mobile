import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

final class _Context implements BusinessContextProvider {
  final changes = StreamController<ActiveBusinessContext?>.broadcast();
  int generation = 1;
  @override
  ActiveBusinessContext get activeContext => ActiveBusinessContext(
    company: const CompanyIdentity(
      code: 'ACME',
      baseUrl: 'https://example.test',
    ),
    employee: const EmployeeIdentity(id: 7, name: 'Employee'),
    username: 'employee',
    serverTimezone: '+07:00',
    isManager: true,
    permissions: {},
    sessionId: 'session-$generation',
  );
  @override
  Stream<ActiveBusinessContext?> get contextChanges => changes.stream;
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: [
    ...AppLocalizations.localizationsDelegates,
    RequestLocalizations.delegate,
  ],
  home: child,
);
void main() {
  testWidgets(
    'large histories build visible rows lazily and select all loaded approvals',
    (tester) async {
      final context = _Context();
      final rows = List.generate(3000, (i) => i);
      Future<Result<PageResult<int>>> load(RequestQuery _) async => Success(
        PageResult(
          content: rows,
          page: 0,
          size: rows.length,
          totalElements: rows.length,
          totalPages: 1,
        ),
      );
      final submission = RequestListController<int>(
        mode: RequestMode.submission,
        load: load,
      );
      final approval = RequestListController<int>(
        mode: RequestMode.approval,
        load: load,
      );
      final selection = RequestSelectionController<int>(
        idOf: (i) => i,
        canSelect: (_) => true,
        canExecute: (_, _) => true,
        execute: (_, _, _) async => const Success<void>(null),
      );
      addTearDown(() {
        submission.dispose();
        approval.dispose();
        selection.dispose();
      });
      addTearDown(context.changes.close);
      var built = 0;
      await tester.pumpWidget(
        _app(
          RequestWorkspace<int>(
            title: 'Requests',
            context: context,
            submission: submission,
            approval: approval,
            selection: selection,
            idOf: (i) => i,
            cardBuilder: (_, item, mode) {
              built++;
              return SizedBox(height: 64, child: Text('row-$item'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(submission.items, hasLength(3000));
      expect(built, lessThan(100));
      expect(find.text('row-2999'), findsNothing);
      await tester.tap(find.text('My Approval'));
      await tester.pumpAndSettle();
      selection.selectAll(approval.items);
      await tester.pump();
      expect(selection.selectedIds, hasLength(3000));
      expect(built, lessThan(200));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('workspace shows a localized load failure and retries the list', (
    tester,
  ) async {
    final context = _Context();
    var fail = true;
    Future<Result<PageResult<int>>> load(RequestQuery query) async => fail
        ? const FailureResult(TimeoutFailure(message: 'Dio timeout'))
        : Success(
            PageResult(
              content: [7],
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
            ),
          );
    final submission = RequestListController<int>(
      mode: RequestMode.submission,
      load: load,
    );
    final approval = RequestListController<int>(
      mode: RequestMode.approval,
      load: load,
    );
    addTearDown(() {
      submission.dispose();
      approval.dispose();
    });
    addTearDown(context.changes.close);
    await tester.pumpWidget(
      _app(
        RequestWorkspace<int>(
          title: 'Requests',
          context: context,
          submission: submission,
          approval: approval,
          idOf: (i) => i,
          cardBuilder: (_, item, _) => Text('Request $item'),
        ),
        locale: const Locale('id'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Waktu permintaan habis. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.textContaining('Dio'), findsNothing);
    fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Request 7'), findsOneWidget);
    expect(find.byType(AppErrorView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (succeeded, message, colorOf) in [
    (2, '2 succeeded, 0 failed', (BuildContext c) => c.semanticColors.success),
    (1, '1 succeeded, 1 failed', (BuildContext c) => c.semanticColors.warning),
    (
      0,
      '0 succeeded, 2 failed',
      (BuildContext c) => Theme.of(c).colorScheme.error,
    ),
  ]) {
    testWidgets('bulk approval reports $message using its feedback status', (
      tester,
    ) async {
      final context = _Context();
      Future<Result<PageResult<int>>> load(RequestQuery query) async => Success(
        PageResult(
          content: [1, 2],
          page: 0,
          size: 20,
          totalElements: 2,
          totalPages: 1,
        ),
      );
      final submission = RequestListController<int>(
        mode: RequestMode.submission,
        load: load,
      );
      final approval = RequestListController<int>(
        mode: RequestMode.approval,
        load: load,
      );
      final selection = RequestSelectionController<int>(
        idOf: (i) => i,
        canSelect: (_) => true,
        canExecute: (_, _) => true,
        execute: (item, _, _) async => item <= succeeded
            ? const Success<void>(null)
            : const FailureResult(ForbiddenFailure()),
      );
      addTearDown(() {
        submission.dispose();
        approval.dispose();
        selection.dispose();
      });
      addTearDown(context.changes.close);
      await tester.pumpWidget(
        _app(
          RequestWorkspace<int>(
            title: 'Requests',
            context: context,
            submission: submission,
            approval: approval,
            selection: selection,
            idOf: (i) => i,
            cardBuilder: (_, item, _) => Text('Request $item'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Approval'));
      await tester.pumpAndSettle();
      selection.selectAll([1, 2]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Approve'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        bar.backgroundColor,
        colorOf(tester.element(find.byType(SnackBar))),
      );
      expect(selection.selectedIds, {
        for (var i = succeeded + 1; i <= 2; i++) i,
      });
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'workspace retains mode queries, swipes, and clears selection on Back/session switch',
    (tester) async {
      final context = _Context();
      Future<Result<PageResult<int>>> load(RequestQuery query) async => Success(
        PageResult(
          content: [context.generation],
          page: 0,
          size: 10,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      final submission = RequestListController<int>(
        mode: RequestMode.submission,
        load: load,
      );
      final approval = RequestListController<int>(
        mode: RequestMode.approval,
        load: load,
      );
      final selection = RequestSelectionController<int>(
        idOf: (i) => i,
        canSelect: (_) => true,
        canExecute: (_, _) => true,
        execute: (_, _, _) async => const Success<void>(null),
      );
      addTearDown(() {
        submission.dispose();
        approval.dispose();
        selection.dispose();
      });
      addTearDown(context.changes.close);
      await tester.pumpWidget(
        _app(
          RequestWorkspace<int>(
            title: 'Requests',
            context: context,
            submission: submission,
            approval: approval,
            selection: selection,
            idOf: (i) => i,
            cardBuilder: (_, item, mode) =>
                ListTile(title: Text('${mode.name}-$item')),
            filterBuilder: (context, mode, query) => TextButton(
              onPressed: () => Navigator.pop(context, <String, Object?>{
                'status': 'APPROVED',
              }),
              child: const Text('Apply filter'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'invoice');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(submission.query.search, 'invoice');
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filter'));
      await tester.pumpAndSettle();
      expect(submission.query.filters, {'status': 'APPROVED'});
      await tester.drag(find.byType(TabBarView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('approval-1'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'pending');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(approval.query.search, 'pending');
      await tester.longPress(find.text('approval-1'));
      await tester.pumpAndSettle();
      expect(selection.selectedIds, {1});
      expect(find.text('1 selected'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(selection.selecting, false);
      expect(find.text('Requests'), findsOneWidget);
      await tester.tap(find.text('My Submission'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'invoice',
      );
      expect(submission.query.filters, {'status': 'APPROVED'});
      context.generation = 2;
      context.changes.add(context.activeContext);
      await tester.pumpAndSettle();
      expect(find.text('submission-2'), findsOneWidget);
      expect(find.text('submission-1'), findsNothing);
      expect(submission.query.search, '');
      expect(approval.query.search, '');
      expect(selection.selectedIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'form keeps values after failure and suppresses duplicate submission',
    (tester) async {
      var calls = 0;
      final gate = Completer<Result<void>>();
      final text = TextEditingController();
      addTearDown(text.dispose);
      await tester.pumpWidget(
        _app(
          RequestFormScaffold(
            title: 'Request',
            sections: [TextFormField(controller: text)],
            onSave: (_) {
              calls++;
              return gate.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'keep this');
      await tester.tap(find.text('Submitted'));
      await tester.tap(find.text('Submitted'));
      await tester.pump();
      expect(calls, 1);
      gate.complete(const FailureResult(NetworkFailure()));
      await tester.pumpAndSettle();
      expect(text.text, 'keep this');
      expect(
        find.text('Unable to connect. Check your internet connection.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'custom fields validate impossible dates and preserve enumeration wire value',
    (tester) async {
      final key = GlobalKey<FormState>();
      final values = <int, String?>{};
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Form(
              key: key,
              child: RequestCustomFieldsSection(
                fields: const [
                  CustomFieldDefinition(
                    id: 1,
                    name: 'Date',
                    type: 'DATE',
                    required: true,
                    editable: true,
                  ),
                  CustomFieldDefinition(
                    id: 2,
                    name: 'Choice',
                    type: 'ENUMERATION',
                    required: true,
                    editable: true,
                    defaultValue: '3',
                    options: [CustomFieldOption('3', 'First')],
                  ),
                ],
                values: values,
                onChanged: (id, value) => values[id] = value,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '2026-02-31');
      expect(key.currentState!.validate(), false);
      await tester.enterText(find.byType(TextFormField), '2026-02-28');
      expect(key.currentState!.validate(), true);
      key.currentState!.save();
      expect(values, {1: '2026-02-28', 2: '3'});
    },
  );

  testWidgets(
    'form preserves business guidance and quietly handles cancellation',
    (tester) async {
      var cancel = false;
      await tester.pumpWidget(
        _app(
          RequestFormScaffold(
            title: 'Request',
            sections: const [Text('Form content')],
            onSave: (_) async => FailureResult(
              cancel
                  ? const CancelledFailure()
                  : const ValidationFailure(
                      message: 'Attendance date is required',
                    ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Submitted'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance date is required'), findsOneWidget);
      cancel = true;
      await tester.tap(find.text('Submitted'));
      await tester.pumpAndSettle();
      expect(find.text('Attendance date is required'), findsNothing);
      expect(find.text('The request was cancelled.'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Submitted'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
