import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

const _alpha = RequestReference(id: 1, label: 'Alpha');
const _beta = RequestReference(id: 2, label: 'Beta');
const _blocked = RequestReference(id: 3, label: 'Unavailable', eligible: false);

Result<PageResult<RequestReference>> _page(
  List<RequestReference> rows, {
  int page = 0,
  int totalPages = 1,
}) => Success(
  PageResult(
    content: rows,
    page: page,
    size: 20,
    totalElements: rows.length,
    totalPages: totalPages,
  ),
);

final class _Repository implements RequestReferenceRepository {
  _Repository(this.load);
  final Future<Result<PageResult<RequestReference>>> Function(
    String search,
    int page,
    Map<String, Object?> filters,
  )
  load;
  @override
  Future<Result<PageResult<RequestReference>>> list(
    RequestReferenceKind kind, {
    String search = '',
    int page = 0,
    int size = 20,
    Map<String, Object?> filters = const {},
  }) => load(search, page, filters);
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: [
    ...AppLocalizations.localizationsDelegates,
    RequestLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets(
    'large reference results build rows lazily and retain scrolling selection',
    (tester) async {
      final rows = List.generate(
        3000,
        (i) => RequestReference(id: i, label: 'Location $i'),
      );
      RequestReference? selected;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RequestReferencePickerContent(
              repository: _Repository((_, _, _) async => _page(rows)),
              kind: RequestReferenceKind.workingLocation,
              onSelected: (item) => selected = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListTile).evaluate().length, lessThan(50));
      expect(find.text('Location 2999'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Location 80'),
        500,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 30,
      );
      await tester.tap(find.text('Location 80'));
      expect(selected?.id, 80);
    },
  );

  testWidgets(
    'search waits for a pause and loads only the latest typed query',
    (tester) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RequestReferencePickerContent(
              repository: _Repository((search, _, _) async {
                searches.add(search);
                return _page([_beta]);
              }),
              kind: RequestReferenceKind.employee,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'A');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(find.byType(TextField), 'Al');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 299));
      expect(searches, ['']);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(searches, ['', 'Alpha']);
    },
  );

  testWidgets(
    'keyboard Search submits immediately without a delayed duplicate',
    (tester) async {
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RequestReferencePickerContent(
              repository: _Repository((search, _, _) async {
                searches.add(search);
                return _page([_beta]);
              }),
              kind: RequestReferenceKind.employee,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(searches, ['', 'Beta']);
      await tester.pump(const Duration(milliseconds: 500));
      expect(searches, ['', 'Beta']);
    },
  );

  testWidgets('removing picker cancels pending search', (tester) async {
    final searches = <String>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: RequestReferencePickerContent(
            repository: _Repository((search, _, _) async {
              searches.add(search);
              return _page([_alpha]);
            }),
            kind: RequestReferenceKind.employee,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beta');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
    expect(searches, ['']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late response cannot overwrite results for a newer search', (
    tester,
  ) async {
    final old = Completer<Result<PageResult<RequestReference>>>();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: RequestReferencePickerContent(
            repository: _Repository((search, _, _) async {
              if (search == 'old') return old.future;
              return _page(search == 'new' ? [_beta] : [_alpha]);
            }),
            kind: RequestReferenceKind.employee,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    old.complete(_page([_alpha]));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  for (final presentation in PickerPresentation.values) {
    testWidgets(
      'reference picker selects typed values in ${presentation.name}',
      (tester) async {
        final repository = _Repository(
          (_, _, _) async => _page([_alpha, _blocked]),
        );
        RequestReference? selected;
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selected = switch (presentation) {
                      PickerPresentation.sheet =>
                        await RequestReferencePicker.showModal(
                          context,
                          title: 'Choose employee',
                          repository: repository,
                          kind: RequestReferenceKind.employee,
                        ),
                      PickerPresentation.dialog =>
                        await RequestReferencePicker.showDialog(
                          context,
                          title: 'Choose employee',
                          repository: repository,
                          kind: RequestReferenceKind.employee,
                        ),
                      PickerPresentation.page =>
                        await Navigator.of(context).push<RequestReference>(
                          MaterialPageRoute(
                            builder: (_) => RequestReferencePicker(
                              title: 'Choose employee',
                              repository: repository,
                              kind: RequestReferenceKind.employee,
                            ),
                          ),
                        ),
                    };
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
        if (presentation != PickerPresentation.page) {
          expect(find.byType(Scaffold), findsOneWidget);
        }
        await tester.tap(find.text('Unavailable'));
        await tester.pumpAndSettle();
        expect(selected, isNull);
        expect(find.text('Choose employee'), findsOneWidget);
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        expect(selected, same(_alpha));
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }

  testWidgets('embedded content delegates selection without popping its host', (
    tester,
  ) async {
    RequestReference? selected;
    final repository = _Repository((_, _, _) async => _page([_alpha, _beta]));
    await tester.pumpWidget(
      _app(
        Material(
          child: RequestReferencePickerContent(
            repository: repository,
            kind: RequestReferenceKind.employee,
            isEligible: (item) => item.id != 2,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsNothing);
    await tester.tap(find.text('Beta'));
    expect(selected, isNull);
    await tester.tap(find.text('Alpha'));
    expect(selected, same(_alpha));
    expect(find.byType(RequestReferencePickerContent), findsOneWidget);
  });

  testWidgets('sheet handles keyboard, search, pagination and load retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var fail = true;
    final searches = <String>[];
    final pages = <int>[];
    final repository = _Repository((search, page, filters) async {
      searches.add(search);
      pages.add(page);
      expect(filters, {'active': true});
      if (fail) return const FailureResult(NetworkFailure());
      if (search.isNotEmpty) return _page([_beta]);
      return page == 0
          ? _page([_alpha], totalPages: 2)
          : _page([_beta], page: 1, totalPages: 2);
    });
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => RequestReferencePicker.showModal(
                context,
                title: 'Choose employee',
                repository: repository,
                kind: RequestReferenceKind.employee,
                filters: const {'active': true},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to connect. Check your internet connection.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(pages, [0, 0, 1]);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beta');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(searches.last, 'Beta');
    expect(pages.last, 0);
    expect(find.text('Alpha'), findsNothing);
    expect(
      tester.getBottomLeft(find.byType(ListView)).dy,
      lessThanOrEqualTo(460),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(RequestReferencePickerContent), findsNothing);
  });

  testWidgets('dismissed sheet ignores an in-flight response', (tester) async {
    final response = Completer<Result<PageResult<RequestReference>>>();
    RequestReference? selected = _alpha;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await RequestReferencePicker.showModal(
                  context,
                  title: 'Choose employee',
                  repository: _Repository((_, _, _) => response.future),
                  kind: RequestReferenceKind.employee,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    response.complete(_page([_alpha]));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
    expect(find.text('Open'), findsOneWidget);
  });
}
