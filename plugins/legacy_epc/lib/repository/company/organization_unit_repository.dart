import 'package:epeoplecare/model/company/organization_unit.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class OrganizationUnitRepository extends BaseRepository<OrganizationUnit> {
  
  OrganizationUnitRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/organization-unit");
  }

  @override
  OrganizationUnit? fromJson(Map<String, dynamic>? json) {
    return OrganizationUnit.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(OrganizationUnit entity) {
    return entity.toJson();  
  }

}