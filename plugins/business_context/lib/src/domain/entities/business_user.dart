import 'package:gasione_core_api/gasione_core_api.dart';

import 'business_menu.dart';
import 'business_permission.dart';

final class BusinessUser {
  BusinessUser({
    required this.id,
    required this.username,
    required this.name,
    required this.deviceId,
    this.employee,
    required List<BusinessMenu> menus,
    required Set<BusinessPermission> permissions,
    required Map<String, dynamic> compatibilityPayload,
  }) : menus = List.unmodifiable(menus),
       permissions = Set.unmodifiable(permissions),
       compatibilityPayload = Map.unmodifiable(compatibilityPayload);

  final int? id;
  final String username;
  final String name;
  final String? deviceId;
  final EmployeeIdentity? employee;
  final List<BusinessMenu> menus;
  final Set<BusinessPermission> permissions;

  /// TRANSITION[LEGACY-BUSINESS-CONTEXT]: the compatibility adapter needs the
  /// complete user graph while Home still constructs EPC models. Remove this
  /// snapshot after migrated consumers use [menus] and [permissions] directly.
  final Map<String, dynamic> compatibilityPayload;

  bool hasPermission(String entity, String action) =>
      permissions.contains(BusinessPermission(entity: entity, action: action));
}
