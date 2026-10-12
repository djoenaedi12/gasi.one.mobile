import 'package:epeoplecare/module/benefit/model/benefit_balance_history.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class BenefitBalanceHistoryRepository extends BaseRepository<BenefitBalanceHistory> {
  
  BenefitBalanceHistoryRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/benefit/balance/history");
  }

  @override
  BenefitBalanceHistory? fromJson(Map<String, dynamic>? json) {
    return BenefitBalanceHistory.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BenefitBalanceHistory entity) {
    return entity.toJson();
  }

}