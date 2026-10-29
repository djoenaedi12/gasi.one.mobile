import '../entities/business_user.dart';

abstract interface class DevicePolicyService {
  Future<void> validateAndBind(
    BusinessUser user, {
    required bool enforcePolicy,
  });
}
