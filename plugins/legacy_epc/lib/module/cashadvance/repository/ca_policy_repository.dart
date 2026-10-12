import 'package:epeoplecare/module/cashadvance/model/ca_policy.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CAPolicyRepository extends BaseRepository<CAPolicy> {
  
  CAPolicyRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/cashadvance/policy");
  }

  @override
  CAPolicy? fromJson(Map<String, dynamic>? json) {
    return CAPolicy.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CAPolicy entity) {
    return entity.toJson();  
  }

}