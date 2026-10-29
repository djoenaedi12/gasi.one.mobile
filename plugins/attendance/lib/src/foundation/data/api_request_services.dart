import 'package:dio/dio.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import 'request_api.dart';

final class ApiRequestReferenceRepository
    implements RequestReferenceRepository {
  ApiRequestReferenceRepository(this.api);
  final RequestApi api;
  @override
  Future<Result<PageResult<RequestReference>>> list(
    RequestReferenceKind kind, {
    String search = '',
    int page = 0,
    int size = 20,
    Map<String, Object?> filters = const {},
  }) => requestResult(() async {
    final endpoint = switch (kind) {
      RequestReferenceKind.employee => '/api/v1/employee/reference',
      RequestReferenceKind.subordinate => '/api/v1/employee/subordinate',
      RequestReferenceKind.workingLocation =>
        '/api/v1/working-location/reference',
      RequestReferenceKind.shift => '/api/v1/shift/reference',
    };
    return requestPage(
      await api.get(
        endpoint,
        query: {
          ...filters,
          'page': page < 0 ? 0 : page,
          'size': size.clamp(1, 100),
          if (search.isNotEmpty) 'name.like': search,
          if (kind == RequestReferenceKind.shift) 'showInRequest': true,
        },
      ),
      (row) => RequestReference(
        id: requestInt(row, 'id'),
        label: requestString(row, 'name'),
        code: row['code'] as String?,
        eligible:
            kind != RequestReferenceKind.shift ||
            row['show_in_request'] != false,
      ),
    );
  });
}

final class ApiRequestAttachmentRepository implements AttachmentRepository {
  ApiRequestAttachmentRepository(this.api);
  final RequestApi api;
  @override
  Future<Result<RequestAttachment>> upload({
    required String path,
    required String name,
    required String contentType,
  }) => requestResult(() async {
    final mime = DioMediaType.parse(contentType);
    final data = requestObject(
      await api.upload(
        '/api/v1/media/upload',
        FormData.fromMap({
          'ext': mime.subtype,
          'file': await MultipartFile.fromFile(
            path,
            filename: name,
            contentType: mime,
          ),
        }),
      ),
    );
    return RequestAttachment(
      id: requestInt(data, 'id'),
      name: requestString(data, 'name'),
      contentType: requestString(data, 'content_type'),
      size: requestInt(data, 'size'),
    );
  });
  @override
  Future<Result<List<int>>> download(String name) => requestResult(
    () =>
        api.bytes('/api/v1/media/downloadByName/${Uri.encodeComponent(name)}'),
  );
}

final class ApiRequestCustomFieldRepository implements CustomFieldRepository {
  ApiRequestCustomFieldRepository(this.api);
  final RequestApi api;
  @override
  Future<Result<List<CustomFieldDefinition>>> fields(
    String entityType,
  ) => requestResult(() async {
    // Fetch bounded pages rather than relying on the legacy unbounded size=-1.
    final fields = <CustomFieldDefinition>[];
    var page = 0;
    while (true) {
      final result = requestPage(
        await api.get(
          '/api/v1/customfield',
          query: {
            'type': entityType,
            'sort': 'position,ASC',
            'page': page,
            'size': 100,
          },
        ),
        (row) => CustomFieldDefinition(
          id: requestInt(row, 'id'),
          name: requestString(row, 'name'),
          type: requestString(row, 'custom_field_type'),
          required: row['required'] == true,
          editable: row['editable'] == true,
          defaultValue: row['default_value'] as String?,
          minLength: row['min_length'] as int?,
          maxLength: row['max_length'] as int?,
          options: [
            for (final option in requestObjects(
              row['custom_field_enumerations'] ?? [],
            ))
              CustomFieldOption(
                requestInt(option, 'enumeration').toString(),
                requestString(option, 'name'),
              ),
            if (row['possible_values'] is String)
              for (final value
                  in (row['possible_values'] as String)
                      .split(RegExp(r'\r?\n'))
                      .where((s) => s.isNotEmpty))
                CustomFieldOption(value, value),
          ],
        ),
      );
      fields.addAll(result.content);
      if (!result.hasNext) return fields;
      if (result.content.isEmpty || result.page != page) {
        throw const FormatException('Invalid field pagination.');
      }
      page++;
    }
  });
}

final class ApiWorkflowReferenceRepository
    implements WorkflowReferenceRepository {
  ApiWorkflowReferenceRepository(this.api);
  final RequestApi api;
  @override
  Future<Result<List<WorkflowNode>>> overrideNodes({
    required int employeeId,
    required String routeType,
  }) => requestResult(
    () async => [
      for (final row in requestObjects(
        await api.get(
          '/api/v1/workflow/node/getoverridenode',
          query: {'employee': employeeId, 'routeType': routeType},
        ),
      ))
        WorkflowNode(
          id: requestInt(row, 'id'),
          name: row['name'] as String? ?? '',
          editable: row['editable'] == true,
          ownerType: row['node_owner_type'] as String?,
          ownerIds: [
            for (final owner in requestObjects(row['node_owners'] ?? []))
              requestInt(owner, 'owner_id'),
          ],
        ),
    ],
  );
  @override
  Future<Result<List<WorkflowHistoryEntry>>> sendBackTargets(int workflowId) =>
      requestResult(
        () async => [
          for (final row in requestObjects(
            await api.get('/api/v1/workflow/detail/send-back/$workflowId'),
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
}
