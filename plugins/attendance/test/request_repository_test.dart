import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_attendance/gasione_plugin_attendance.dart';

final class _Context implements BusinessContextProvider {
  ActiveBusinessContext? value = ActiveBusinessContext(
    company: const CompanyIdentity(
      code: 'ACME',
      baseUrl: 'https://tenant.test/epc',
    ),
    employee: const EmployeeIdentity(id: 7, name: 'Employee'),
    username: 'employee',
    serverTimezone: '+07:00',
    isManager: true,
    permissions: {},
    sessionId: 'one',
  );
  @override
  ActiveBusinessContext? get activeContext => value;
  @override
  Stream<ActiveBusinessContext?> get contextChanges => const Stream.empty();
}

final class _Api extends ApiClient {
  _Api() : super(enableLogging: false, enableRetry: false);
  Object? data;
  Completer<void>? gate;
  final calls = <({String method, String path, Map<String, Object?> values})>[];
  Future<Map<String, dynamic>> _respond(
    String method,
    String path,
    Map<String, Object?> values,
  ) async {
    calls.add((method: method, path: path, values: values));
    await gate?.future;
    return {'success': true, 'data': data};
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) => _respond('GET', path, queryParameters ?? {});
  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?>? data,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) => _respond('POST', path, data ?? {});
  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, Object?>? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) => _respond('PUT', path, data ?? {});
}

Map<String, Object?> _page(List<Object?> items) => {
  'content': items,
  'number': 0,
  'size': 10,
  'total_elements': items.length,
  'total_pages': 1,
};
void main() {
  late _Api api;
  late _Context context;
  late RequestApi transport;
  setUp(() {
    api = _Api();
    context = _Context();
    transport = RequestApi(client: api, context: context, headers: () => {});
  });
  tearDown(() => api.close());
  ApiRequestRepository<int, String> repository() => ApiRequestRepository(
    api: transport,
    endpoint: '/api/v1/feature',
    decode: (row) => row['id'] as int,
    encodeDraft: (draft, action) => {
      'name': draft,
      'workflow_status': action == WorkflowAction.draft
          ? 'DRAFTED'
          : 'SUBMITTED',
    },
    encodeQuery: (query) => {...query.filters, 'requestNo.like': query.search},
  );
  test('uses installed pagination and pending approval route', () async {
    api.data = _page([
      {'id': 1},
    ]);
    final result = await repository().list(
      RequestQuery(mode: RequestMode.approval, search: 'A', sort: ['id,DESC']),
    );
    expect((result as Success<PageResult<int>>).data.content, [1]);
    expect(
      api.calls.single.path,
      'https://tenant.test/epc/api/v1/feature/approval/pending',
    );
    expect(api.calls.single.values, {
      'requestNo.like': 'A',
      'page': 0,
      'size': 10,
      'sort': ['id,DESC'],
    });
  });
  test(
    'create/update keep feature payload and workflow status mapping',
    () async {
      api.data = {'id': 8};
      expect(
        await repository().create('draft', action: WorkflowAction.draft),
        isA<Success<int>>(),
      );
      expect(api.calls.last.values['workflow_status'], 'DRAFTED');
      await repository().update(8, 'submitted', action: WorkflowAction.submit);
      expect(api.calls.last.method, 'PUT');
      expect(api.calls.last.path.endsWith('/8'), true);
      expect(api.calls.last.values['workflow_status'], 'SUBMITTED');
    },
  );
  test('workflow uses existing single approval and revoke contracts', () async {
    final repo = repository();
    for (final action in [
      WorkflowAction.approve,
      WorkflowAction.reject,
      WorkflowAction.sendBack,
      WorkflowAction.pullBack,
    ]) {
      expect(
        await repo.execute(
          WorkflowCommand(
            action: action,
            workflowId: 9,
            remark: 'test',
            sendBackDetailId: 4,
          ),
        ),
        isA<Success<void>>(),
      );
      expect(api.calls.last.path.endsWith('/approval'), true);
      expect(api.calls.last.values['workflow'], {'id': 9});
    }
    expect(api.calls.map((c) => c.values['workflow_status']), [
      'APPROVED',
      'REJECTED',
      'SENDBACKED',
      'PULLBACKED',
    ]);
    await repo.execute(
      const WorkflowCommand(action: WorkflowAction.revoke, workflowId: 9),
    );
    expect(api.calls.last.method, 'GET');
    expect(api.calls.last.path.endsWith('/revoked-request'), true);
  });
  test(
    'old company response is discarded and no-session requests fail closed',
    () async {
      api.gate = Completer<void>();
      api.data = {'id': 1};
      final pending = repository().find(1);
      await Future<void>.delayed(Duration.zero);
      context.value = null;
      api.gate!.complete();
      expect(
        (await pending as FailureResult<int>).failure,
        isA<CancelledFailure>(),
      );
      final count = api.calls.length;
      expect(
        (await repository().find(1) as FailureResult<int>).failure,
        isA<UnauthorizedFailure>(),
      );
      expect(api.calls.length, count);
    },
  );
  test('malformed pagination maps to InvalidResponseFailure', () async {
    api.data = {'content': <Object?>[], 'number': 'bad'};
    expect(
      (await repository().list(
        RequestQuery(),
      ) as FailureResult<PageResult<int>>).failure,
      isA<InvalidResponseFailure>(),
    );
  });
  test(
    'custom fields preserve enumeration values and newline list choices',
    () async {
      api.data = _page([
        {
          'id': 1,
          'name': 'Choice',
          'custom_field_type': 'ENUMERATION',
          'required': true,
          'editable': true,
          'custom_field_enumerations': [
            {'name': 'First', 'enumeration': 3},
          ],
        },
        {
          'id': 2,
          'name': 'List',
          'custom_field_type': 'LIST',
          'required': false,
          'editable': true,
          'possible_values': 'A\r\nB',
        },
      ]);
      final result = await ApiRequestCustomFieldRepository(transport)
          .fields('Feature');
      final fields = (result as Success<List<CustomFieldDefinition>>).data;
      expect(fields.first.options.single.value, '3');
      expect(fields.first.options.single.label, 'First');
      expect(fields.last.options.map((o) => o.value), ['A', 'B']);
    },
  );
}
