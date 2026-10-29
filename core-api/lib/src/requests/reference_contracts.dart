import '../context/active_business_context.dart';
import '../pagination/page_result.dart';
import '../picker/picker.dart';
import '../result/result.dart';

enum RequestReferenceKind { employee, subordinate, workingLocation, shift }

final class RequestReference {
  const RequestReference({
    required this.id,
    required this.label,
    this.code,
    this.eligible = true,
  });
  final int id;
  final String label;
  final String? code;
  final bool eligible;
}

abstract interface class RequestReferenceRepository {
  Future<Result<PageResult<RequestReference>>> list(
    RequestReferenceKind kind, {
    String search = '',
    int page = 0,
    int size = 20,
    Map<String, Object?> filters = const {},
  });
}

abstract final class RequestPickerKeys {
  static const employee = PickerKey<RequestReference>('request.employee');
  static const subordinate = PickerKey<RequestReference>('request.subordinate');
  static const workingLocation = PickerKey<RequestReference>(
    'request.working-location',
  );
  static const shift = PickerKey<RequestReference>('request.shift');
  static const attachment = PickerKey<RequestAttachmentSelection>(
    'request.attachment',
  );
}

final class RequestAttachmentSelection {
  const RequestAttachmentSelection({
    required this.path,
    required this.name,
    required this.contentType,
  });
  final String path;
  final String name;
  final String contentType;
}

/// Features supply their installed request-for-other permission name.
final class RequestForOtherPolicy {
  const RequestForOtherPolicy({required this.entity, required this.action});
  final String entity;
  final String action;
  bool allows(ActiveBusinessContext context, int employeeId) =>
      context.employee.id == employeeId || context.permits(entity, action);
}
