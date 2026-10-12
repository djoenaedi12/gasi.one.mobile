import 'package:epeoplecare/model/company/currency_rate.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CurrencyRateRepository extends BaseRepository<CurrencyRate> {
  
  CurrencyRateRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/currency/rate");
  }

  @override
  CurrencyRate? fromJson(Map<String, dynamic>? json) {
    return CurrencyRate.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CurrencyRate entity) {
    return entity.toJson();  
  }

}