import 'package:epeoplecare/model/company/attribute.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AttributeRepository extends BaseRepository<Attribute> {
  
  AttributeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attribute");
  }

  @override
  Attribute? fromJson(Map<String, dynamic>? json) {
    return Attribute.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Attribute entity) {
    return entity.toJson();  
  }

}