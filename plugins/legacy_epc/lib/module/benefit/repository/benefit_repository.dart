import 'package:epeoplecare/module/benefit/model/benefit.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class BenefitRepository extends BaseRepository<Benefit> {
  
  BenefitRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/benefit");
  }

  @override
  Benefit? fromJson(Map<String, dynamic>? json) {
    return Benefit.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Benefit entity) {
    return entity.toJson();  
  }

}