import 'package:epeoplecare/module/cashadvance/model/ca_category.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CACategoryRepository extends BaseRepository<CACategory> {
  
  CACategoryRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/cashadvance/category");
  }

  @override
  CACategory? fromJson(Map<String, dynamic>? json) {
    return CACategory.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CACategory entity) {
    return entity.toJson();  
  }

}