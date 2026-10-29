import '../entities/business_context.dart';
import '../entities/business_license.dart';
import '../entities/business_user.dart';

abstract interface class BusinessContextRepository {
  Future<BusinessUser> findUser(String username);

  Future<BusinessLicense?> loadLicense();

  Future<String?> findParameter(String name);

  Future<bool> isManager();

  Future<BusinessContext> buildContext(BusinessUser user);
}
