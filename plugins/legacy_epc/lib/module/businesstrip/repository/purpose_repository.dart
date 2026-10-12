import 'package:epeoplecare/module/businesstrip/model/purpose.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class PurposeRepository extends BaseRepository<Purpose> {
  
  PurposeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/purpose");
  }

  @override
  Purpose? fromJson(Map<String, dynamic>? json) {
    return Purpose.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Purpose entity) {
    return entity.toJson();  
  }

}