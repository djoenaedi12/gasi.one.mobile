import 'package:gasione_core_starter/gasione_core_starter.dart';

import '../../domain/entities/business_user.dart';
import '../../domain/services/device_policy_service.dart';
import '../datasources/business_context_remote_data_source.dart';

final class ApiDevicePolicyService implements DevicePolicyService {
  ApiDevicePolicyService(this._remote, this._runtime);

  final BusinessContextRemoteDataSource _remote;
  final AppRuntime _runtime;

  @override
  Future<void> validateAndBind(
    BusinessUser user, {
    required bool enforcePolicy,
  }) async {
    final deviceId = _runtime.deviceId;
    if (deviceId.isEmpty) return;
    if (enforcePolicy &&
        await _remote.parameter('SESSION_MOBILE_DEVICE') == 'SINGLE') {
      final users = await _remote.usersOnDevice(
        deviceId: deviceId,
        excludingUserId: user.id,
      );
      if ((user.deviceId != null && user.deviceId != deviceId) ||
          users.isNotEmpty) {
        throw const ApiException(
          ApiExceptionType.badResponse,
          statusCode: 422,
          code: 'DEVICE_NOT_SAME',
        );
      }
    }
    await _remote.setDeviceId(deviceId);
  }
}
