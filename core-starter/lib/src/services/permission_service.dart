import 'package:permission_handler/permission_handler.dart' as permissions;

enum AppPermission { locationWhenInUse }

enum AppPermissionStatus { granted, denied, permanentlyDenied, restricted }

abstract interface class PermissionService {
  Future<AppPermissionStatus> check(AppPermission permission);

  Future<AppPermissionStatus> request(AppPermission permission);

  Future<bool> openSettings();
}

final class DevicePermissionService implements PermissionService {
  const DevicePermissionService();

  @override
  Future<AppPermissionStatus> check(AppPermission permission) async {
    final status = await _toPluginPermission(permission).status;
    return _fromPluginStatus(status);
  }

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    final status = await _toPluginPermission(permission).request();
    return _fromPluginStatus(status);
  }

  @override
  Future<bool> openSettings() => permissions.openAppSettings();

  permissions.Permission _toPluginPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.locationWhenInUse =>
        permissions.Permission.locationWhenInUse,
    };
  }

  AppPermissionStatus _fromPluginStatus(permissions.PermissionStatus status) {
    return switch (status) {
      permissions.PermissionStatus.granted ||
      permissions.PermissionStatus.limited ||
      permissions.PermissionStatus.provisional => AppPermissionStatus.granted,
      permissions.PermissionStatus.denied => AppPermissionStatus.denied,
      permissions.PermissionStatus.permanentlyDenied =>
        AppPermissionStatus.permanentlyDenied,
      permissions.PermissionStatus.restricted => AppPermissionStatus.restricted,
    };
  }
}
