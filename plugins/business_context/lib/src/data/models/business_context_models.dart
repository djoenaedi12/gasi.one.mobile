import 'package:gasione_core_api/gasione_core_api.dart';

import '../../domain/entities/business_license.dart';
import '../../domain/entities/business_menu.dart';
import '../../domain/entities/business_permission.dart';
import '../../domain/entities/business_user.dart';

abstract final class BusinessContextModels {
  static BusinessUser user(Map<String, dynamic> json) {
    final username = json['username'];
    final name = json['name'];
    final roles = json['roles'];
    if (username is! String ||
        username.isEmpty ||
        name is! String ||
        roles is! List) {
      throw const FormatException('Invalid business user.');
    }
    final menus = <BusinessMenu>[];
    final permissions = <BusinessPermission>{};
    for (final role in roles) {
      if (role is! Map) throw const FormatException('Invalid user role.');
      final roleMenus = role['menus'];
      if (roleMenus is List) {
        for (final menu in roleMenus) {
          if (menu is! Map) throw const FormatException('Invalid menu.');
          menus.add(_menu(Map<String, dynamic>.from(menu)));
        }
      }
      final rights = role['access_rights'];
      if (rights is List) {
        for (final right in rights) {
          if (right is! Map) {
            throw const FormatException('Invalid access right.');
          }
          final entity = right['entity'];
          final action = right['action'];
          final entityName = entity is Map ? entity['name'] : null;
          final actionName = action is Map ? action['name'] : null;
          if (entityName is String && actionName is String) {
            permissions.add(
              BusinessPermission(entity: entityName, action: actionName),
            );
          }
        }
      }
    }
    final id = json['id'];
    if (id != null && id is! int) {
      throw const FormatException('Invalid user id.');
    }
    final deviceId = json['device_id'];
    if (deviceId != null && deviceId is! String) {
      throw const FormatException('Invalid user device id.');
    }
    return BusinessUser(
      id: id as int?,
      username: username,
      name: name,
      deviceId: deviceId as String?,
      employee: _employee(json['employee']),
      menus: menus,
      permissions: permissions,
      compatibilityPayload: json,
    );
  }

  static EmployeeIdentity? _employee(Object? value) {
    if (value == null) return null;
    if (value is! Map ||
        value['id'] is! int ||
        value['name'] is! String ||
        (value['code'] != null && value['code'] is! String)) {
      throw const FormatException('Invalid active employee.');
    }
    return EmployeeIdentity(
      id: value['id'] as int,
      name: value['name'] as String,
      number: value['code'] as String?,
    );
  }

  static BusinessLicense license(Map<String, dynamic> json) {
    final value = json['license'];
    final expiryDate = json['expiry_date'];
    final modules = json['modules'];
    final companyCode = json['company_code'];
    final hostName = json['host_name'];
    if (value is! String ||
        expiryDate is! String ||
        modules is! List ||
        companyCode is! String ||
        hostName is! String) {
      throw const FormatException('Invalid business license.');
    }
    return BusinessLicense(
      value: value,
      expiryDate: expiryDate,
      modules: [
        for (final item in modules)
          if (item is String && item.isNotEmpty) item,
      ],
      companyCode: companyCode,
      hostName: hostName,
    );
  }

  static BusinessMenu _menu(Map<String, dynamic> json) {
    final children = json['childs'];
    final id = json['id'];
    final name = json['name'];
    final title = json['title'];
    final path = json['url'];
    final sequence = json['sequence'];
    final visible = json['visible'];
    final module = json['module'];
    if ((id != null && id is! int) ||
        name is! String ||
        title is! String ||
        path is! String ||
        sequence is! int ||
        visible is! bool ||
        (module != null && module is! String) ||
        (children != null && children is! List)) {
      throw const FormatException('Invalid business menu.');
    }
    return BusinessMenu(
      id: id as int?,
      name: name,
      title: title,
      path: path,
      sequence: sequence,
      visible: visible,
      module: module as String?,
      children: [
        for (final child in children as List? ?? const [])
          if (child is Map) _menu(Map<String, dynamic>.from(child)),
      ],
    );
  }
}
