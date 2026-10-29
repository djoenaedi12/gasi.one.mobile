final class EmployeeIdentity {
  const EmployeeIdentity({required this.id, required this.name, this.number});
  final int id;
  final String name;
  final String? number;
}

final class CompanyIdentity {
  const CompanyIdentity({required this.code, required this.baseUrl});
  final String code;
  final String baseUrl;
}

final class BusinessAccess {
  const BusinessAccess(this.entity, this.action);
  final String entity;
  final String action;

  @override
  bool operator ==(Object other) =>
      other is BusinessAccess &&
      entity.toLowerCase().trim() == other.entity.toLowerCase().trim() &&
      action.toLowerCase().trim() == other.action.toLowerCase().trim();
  @override
  int get hashCode =>
      Object.hash(entity.toLowerCase().trim(), action.toLowerCase().trim());
}

/// Immutable, token-free context supplied at the composition boundary.
final class ActiveBusinessContext {
  ActiveBusinessContext({
    required this.company,
    required this.employee,
    required this.username,
    required this.serverTimezone,
    required this.isManager,
    required Set<BusinessAccess> permissions,
    required this.sessionId,
  }) : permissions = Set.unmodifiable(permissions);
  final CompanyIdentity company;
  final EmployeeIdentity employee;
  final String username;
  final String serverTimezone;
  final bool isManager;
  final Set<BusinessAccess> permissions;

  /// Opaque generation identifier; never an access or refresh token.
  final String sessionId;
  bool permits(String entity, String action) =>
      permissions.contains(BusinessAccess(entity, action));
}

abstract interface class BusinessContextProvider {
  ActiveBusinessContext? get activeContext;
  Stream<ActiveBusinessContext?> get contextChanges;
}
