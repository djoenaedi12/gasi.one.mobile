import 'package:epeoplecare/module/loan/model/loan_type.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LoanTypeRepository extends BaseRepository<LoanType> {
  
  LoanTypeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan/type");
  }

  @override
  LoanType? fromJson(Map<String, dynamic>? json) {
    return LoanType.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LoanType entity) {
    return entity.toJson();  
  }

}