import '../../domain/services/push_registration_service.dart';
import '../datasources/business_context_remote_data_source.dart';

final class BackendPushRegistrationService implements PushRegistrationService {
  BackendPushRegistrationService(this._remote);

  final BusinessContextRemoteDataSource _remote;

  @override
  Future<void> register(String token) async {
    if (token.isEmpty) return;
    await _remote.setFcm(token);
  }
}
