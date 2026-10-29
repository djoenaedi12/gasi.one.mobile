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

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: [
    ...AppLocalizations.localizationsDelegates,
    RequestLocalizations.delegate,
  ],
  home: child,
);
void main() {
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
      expect(find.text('Could not load data'), findsOneWidget);
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
}
