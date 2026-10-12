import 'package:epeoplecare/module/letter/model/letter_type.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LetterTypeRepository extends BaseRepository<LetterType> {
  
  LetterTypeRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/letter/type");
  }

  @override
  LetterType? fromJson(Map<String, dynamic>? json) {
    return LetterType.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LetterType entity) {
    return entity.toJson();
  }

}