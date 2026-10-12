import 'package:epeoplecare/module/businesstrip/model/allowance.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AllowanceRepository extends BaseRepository<Allowance> {
  
  AllowanceRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/allowance");
  }

  @override
  Allowance? fromJson(Map<String, dynamic>? json) {
    return Allowance.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Allowance entity) {
    return entity.toJson();  
  }

}