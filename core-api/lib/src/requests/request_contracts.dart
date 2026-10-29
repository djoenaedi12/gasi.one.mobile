import '../context/active_business_context.dart';
import '../errors/failure.dart';
import '../pagination/page_result.dart';
import '../result/result.dart';

enum RequestMode { submission, approval }

enum WorkflowStatus {
  drafted('DRAFTED'),
  submitted('SUBMITTED'),
  approved('APPROVED'),
  rejected('REJECTED'),
  revoked('REVOKED'),
  cancelled('CANCELLED'),
  approvalProcess('APPROVAL_PROCESS'),
  sentBack('SENDBACKED'),
  pulledBack('PULLBACKED');

  const WorkflowStatus(this.wireValue);
  final String wireValue;
  static WorkflowStatus parse(String value) => values.firstWhere(
    (s) => s.wireValue == value,
    orElse: () => throw const FormatException('Invalid workflow status.'),
  );
}

enum WorkflowAction {
  draft,
  submit,
  approve,
  reject,
  sendBack,
  pullBack,
  revoke,
}

final class WorkflowHistoryEntry {
  const WorkflowHistoryEntry({
    required this.id,
    required this.status,
    this.executor,
    this.executedAt,
    this.remark,
  });
  final int id;
  final WorkflowStatus? status;
  final EmployeeIdentity? executor;
  final DateTime? executedAt;
  final String? remark;
}

final class WorkflowExecutor {
  const WorkflowExecutor({this.nodeId, required this.employee});
  final int? nodeId;
  final EmployeeIdentity employee;
}

final class RequestAttachment {
  const RequestAttachment({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
  });
  final int id;
  final String name;
  final String contentType;
  final int size;
}

final class CustomFieldOption {
  const CustomFieldOption(this.value, this.label);
  final String value;
  final String label;
}

final class CustomFieldDefinition {
  const CustomFieldDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.editable,
    this.defaultValue,
    this.minLength,
    this.maxLength,
    this.options = const [],
  });
  final int id;
  final String name;
  final String type;
  final bool required;
  final bool editable;
  final String? defaultValue;
  final int? minLength;
  final int? maxLength;
  final List<CustomFieldOption> options;
}

final class CustomFieldValue {
  const CustomFieldValue(this.fieldId, this.value);
  final int fieldId;
  final Object? value;
}

final class RequestMetadata {
  const RequestMetadata({
    required this.id,
    required this.number,
    required this.status,
    required this.employee,
    this.workflowId,
    this.createdAt,
  });
  final int id;
  final String number;
  final WorkflowStatus status;
  final EmployeeIdentity employee;
  final int? workflowId;
  final DateTime? createdAt;
}

final class RequestQuery {
  RequestQuery({
    this.mode = RequestMode.submission,
    this.search = '',
    Map<String, Object?> filters = const {},
    List<String> sort = const [],
    this.page = 0,
    this.size = 10,
  }) : filters = Map.unmodifiable(filters),
       sort = List.unmodifiable(sort);
  final RequestMode mode;
  final String search;

  /// Feature-owned mapping to the installed API's query names.
  final Map<String, Object?> filters;
  final List<String> sort;
  final int page;
  final int size;
  RequestQuery copyWith({
    String? search,
    Map<String, Object?>? filters,
    List<String>? sort,
    int? page,
  }) => RequestQuery(
    mode: mode,
    search: search ?? this.search,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    size: size,
  );
}

final class WorkflowCommand {
  const WorkflowCommand({
    required this.action,
    required this.workflowId,
    this.remark = '',
    this.sendBackDetailId,
    this.employeeId,
  });
  final WorkflowAction action;
  final int workflowId;
  final String remark;
  final int? sendBackDetailId;
  final int? employeeId;
}

abstract interface class RequestRepository<T, D> {
  Future<Result<PageResult<T>>> list(RequestQuery query);
  Future<Result<T>> find(int id);
  Future<Result<T>> create(D draft, {required WorkflowAction action});
  Future<Result<T>> update(int id, D draft, {required WorkflowAction action});
  Future<Result<void>> execute(WorkflowCommand command);
  Future<Result<List<WorkflowHistoryEntry>>> history(int workflowId);
  Future<Result<List<WorkflowExecutor>>> executors(int workflowId);
}

final class BulkActionResult {
  BulkActionResult({
    required Set<int> succeeded,
    required Map<int, Failure> failures,
  }) : succeeded = Set.unmodifiable(succeeded),
       failures = Map.unmodifiable(failures);
  final Set<int> succeeded;
  final Map<int, Failure> failures;
}

abstract interface class AttachmentRepository {
  Future<Result<RequestAttachment>> upload({
    required String path,
    required String name,
    required String contentType,
  });
  Future<Result<List<int>>> download(String name);
}

abstract interface class CustomFieldRepository {
  Future<Result<List<CustomFieldDefinition>>> fields(String entityType);
}

final class WorkflowNode {
  WorkflowNode({
    required this.id,
    required this.name,
    required this.editable,
    required this.ownerType,
    required List<int> ownerIds,
  }) : ownerIds = List.unmodifiable(ownerIds);
  final int id;
  final String name;
  final bool editable;
  final String? ownerType;
  final List<int> ownerIds;
}

abstract interface class WorkflowReferenceRepository {
  Future<Result<List<WorkflowNode>>> overrideNodes({
    required int employeeId,
    required String routeType,
  });
  Future<Result<List<WorkflowHistoryEntry>>> sendBackTargets(int workflowId);
}
