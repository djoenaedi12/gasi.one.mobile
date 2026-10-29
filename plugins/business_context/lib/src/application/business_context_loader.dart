import '../domain/entities/business_context.dart';
import '../domain/repositories/business_context_repository.dart';
import '../domain/services/device_policy_service.dart';

final class BusinessContextLoader {
  BusinessContextLoader(this._repository, this._devicePolicy);

  final BusinessContextRepository _repository;
  final DevicePolicyService _devicePolicy;

  Future<BusinessContext> load({
    required String username,
    required bool validateDevice,
  }) async {
    final user = await _repository.findUser(username);
    await _devicePolicy.validateAndBind(user, enforcePolicy: validateDevice);
    return _repository.buildContext(user);
  }
}
