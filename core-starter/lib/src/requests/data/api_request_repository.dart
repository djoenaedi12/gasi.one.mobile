import 'package:gasione_core_api/gasione_core_api.dart';

import 'request_api.dart';

/// Reusable CRUD/workflow adapter; feature payloads and query names stay in the
/// owning feature. No WFH, Flex Hour, or Correction endpoint is registered here.
final class ApiRequestRepository<T, D> implements RequestRepository<T, D> {
  ApiRequestRepository({
    required this.api,
    required this.endpoint,
    required this.decode,
    required this.encodeDraft,
    required this.encodeQuery,
    this.encodeWorkflow,
    this.listEndpoint,
  });
  final RequestApi api;
  final String endpoint;
  final String Function(RequestQuery)? listEndpoint;
  final T Function(Map<String, dynamic>) decode;
  final Map<String, Object?> Function(D, WorkflowAction) encodeDraft;
  final Map<String, Object?> Function(RequestQuery) encodeQuery;
  final Map<String, Object?> Function(WorkflowCommand)? encodeWorkflow;
  @override
  Future<Result<PageResult<T>>> list(RequestQuery query) =>
      requestResult(() async {
        final suffix = query.mode == RequestMode.approval
            ? '/approval/pending'
            : '';
        return requestPage(
          await api.get(
            listEndpoint?.call(query) ?? '$endpoint$suffix',
            query: {
              ...encodeQuery(query),
              'page': query.page < 0 ? 0 : query.page,
              'size': query.size.clamp(1, 100),
              if (query.sort.isNotEmpty) 'sort': query.sort,
            },
          ),
          decode,
        );
      });
  @override
  Future<Result<T>> find(int id) => requestResult(
    () async => decode(requestObject(await api.get('$endpoint/$id'))),
  );
  void _saveAction(WorkflowAction action) {
    if (action != WorkflowAction.draft && action != WorkflowAction.submit) {
      throw ArgumentError('Create/update only accept draft or submit.');
    }
  }

  @override
  Future<Result<T>> create(D draft, {required WorkflowAction action}) =>
      requestResult(() async {
        _saveAction(action);
        return decode(
          requestObject(await api.post(endpoint, encodeDraft(draft, action))),
        );
      });
  @override
  Future<Result<T>> update(int id, D draft, {required WorkflowAction action}) =>
      requestResult(() async {
        _saveAction(action);
        return decode(
          requestObject(
            await api.put('$endpoint/$id', encodeDraft(draft, action)),
          ),
        );
      });
  @override
  Future<Result<void>> execute(WorkflowCommand command) =>
      requestResult(() async {
        if (command.action == WorkflowAction.revoke) {
          await api.get(
            '$endpoint/revoked-request',
            query: {
              'workflow': command.workflowId,
              'remark': command.remark,
              if (command.employeeId != null) 'employee': command.employeeId,
            },
          );
          return;
        }
        if (command.action == WorkflowAction.draft ||
            command.action == WorkflowAction.submit) {
          throw ArgumentError('Draft/submit require a complete feature draft.');
        }
        if (command.action == WorkflowAction.sendBack &&
            command.sendBackDetailId == null) {
          throw const FormatException('Send back requires a workflow detail.');
        }
        await api.post(
          '$endpoint/approval',
          encodeWorkflow?.call(command) ??
              {
                'workflow': {'id': command.workflowId},
                'workflow_status': switch (command.action) {
                  WorkflowAction.approve => 'APPROVED',
                  WorkflowAction.reject => 'REJECTED',
                  WorkflowAction.sendBack => 'SENDBACKED',
                  WorkflowAction.pullBack => 'PULLBACKED',
                  _ => throw ArgumentError('Unsupported workflow action.'),
                },
                'remark': command.remark,
                'workflow_detail': command.sendBackDetailId == null
                    ? null
                    : {'id': command.sendBackDetailId},
              },
        );
      });
  @override
  Future<Result<List<WorkflowHistoryEntry>>> history(int workflowId) =>
      requestResult(
        () async => [
          for (final row in requestObjects(
            await api.get('$endpoint/approval/history/$workflowId'),
          ))
            WorkflowHistoryEntry(
              id: requestInt(row, 'id'),
              status: row['workflow_status'] == null
                  ? null
                  : WorkflowStatus.parse(requestString(row, 'workflow_status')),
              executor: row['executor'] == null
                  ? null
                  : requestEmployee(requestObject(row['executor'])),
              executedAt: row['executed_date'] == null
                  ? null
                  : DateTime.parse(requestString(row, 'executed_date')),
              remark: row['remark'] as String?,
            ),
        ],
      );
  @override
  Future<Result<List<WorkflowExecutor>>> executors(int workflowId) =>
      requestResult(
        () async => [
          for (final row in requestObjects(
            await api.get('/api/v1/workflow/detail/approval/$workflowId'),
          ))
            WorkflowExecutor(employee: requestEmployee(row)),
        ],
      );
}
