import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

final class _References implements RequestReferenceRepository {
  final calls = <(RequestReferenceKind, Map<String, Object?>)>[];
  @override
  Future<Result<PageResult<RequestReference>>> list(
    RequestReferenceKind kind, {
    String search = '',
    int page = 0,
    int size = 20,
    Map<String, Object?> filters = const {},
  }) async {
    calls.add((kind, filters));
    return Success(
      PageResult(
        content: [RequestReference(id: 7, label: 'Office')],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
      ),
    );
  }
}

void main() {
  testWidgets(
    'shared picker launches through scope without a business plugin',
    (tester) async {
      final references = _References();
      final registry = PickerRegistry(
        RequestPickerContributor(references).pickers,
      );
      RequestReference? selection;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            RequestLocalizations.delegate,
          ],
          home: PickerScope(
            launcher: registry,
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selection = await PickerScope.of(context).open(
                      context,
                      RequestPickerKeys.workingLocation,
                      request: const PickerRequest(
                        title: 'Choose location',
                        arguments: {'active': true},
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(references.calls.single.$1, RequestReferenceKind.workingLocation);
      expect(references.calls.single.$2, {'active': true});
      await tester.tap(find.text('Office'));
      await tester.pumpAndSettle();
      expect(selection?.id, 7);
      expect(find.text('Open'), findsOneWidget);
    },
  );
}
