import 'package:epeoplecare/module/businesstrip/model/allowance_mapping.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AllowanceMappingRepository extends BaseRepository<AllowanceMapping> {
  
  AllowanceMappingRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/allowance/mapping");
  }

  @override
  AllowanceMapping? fromJson(Map<String, dynamic>? json) {
    return AllowanceMapping.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(AllowanceMapping entity) {
    return entity.toJson();  
  }

}