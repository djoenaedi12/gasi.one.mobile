import 'package:gasione_core_starter/gasione_core_starter.dart';

import '../../domain/entities/business_context.dart';
import '../../domain/entities/business_license.dart';
import '../../domain/entities/business_user.dart';
import '../../domain/repositories/business_context_repository.dart';
import '../datasources/business_context_remote_data_source.dart';
import '../models/business_context_models.dart';
import '../storage/installed_business_context_storage.dart';

final class BusinessContextRepositoryImpl implements BusinessContextRepository {
  BusinessContextRepositoryImpl(this._remote, this._storage);

  final BusinessContextRemoteDataSource _remote;
  final InstalledBusinessContextStorage _storage;

  @override
  Future<BusinessUser> findUser(String username) async {
    try {
      return BusinessContextModels.user(await _remote.findUser(username));
    } on FormatException {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
  }

  @override
  Future<BusinessLicense?> loadLicense() async {
    final installed = _storage.readLicense();
    if (installed != null) return installed;
    final remote = await _remote.license();
    if (remote == null) return null;
    try {
      return BusinessContextModels.license(remote);
    } on FormatException {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
  }

  @override
  Future<String?> findParameter(String name) => _remote.parameter(name);

  @override
  Future<bool> isManager() => _remote.isManager();

  @override
  Future<BusinessContext> buildContext(BusinessUser user) async {
    final values = await Future.wait<Object?>([
      loadLicense(),
      findParameter('TIMEZONE'),
      findParameter('SHOW_DISABLED_MENU'),
      findParameter('SWITCH_ACCOUNT'),
      isManager(),
    ]);
    return BusinessContext(
      user: user,
      license: values[0] as BusinessLicense?,
      serverTimezone: values[1] as String? ?? '+07:00',
      showDisabledMenu: values[2] == null || values[2] != '0',
      switchAccountEnabled: values[3] == '1',
      isManager: values[4] as bool,
    );
  }
}
