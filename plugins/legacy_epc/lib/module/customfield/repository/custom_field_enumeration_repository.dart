import 'package:epeoplecare/module/customfield/model/custom_field_enumeration.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CustomFieldEnumerationRepository extends BaseRepository<CustomFieldEnumeration> {
  
  CustomFieldEnumerationRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/customfield/enumeration");
  }

  @override
  CustomFieldEnumeration? fromJson(Map<String, dynamic>? json) {
    return CustomFieldEnumeration.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CustomFieldEnumeration entity) {
    return entity.toJson();  
  }

}