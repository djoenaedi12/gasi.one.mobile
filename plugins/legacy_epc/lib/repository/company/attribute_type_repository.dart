import 'package:epeoplecare/model/company/attribute_type.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AttributeTypeRepository extends BaseRepository<AttributeType> {
  
  AttributeTypeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attribute/type");
  }

  @override
  AttributeType? fromJson(Map<String, dynamic>? json) {
    return AttributeType.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(AttributeType entity) {
    return entity.toJson();  
  }

}