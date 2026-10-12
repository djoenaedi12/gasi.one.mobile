import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CurrencyRepository extends BaseRepository<Currency> {
  
  CurrencyRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/currency");
  }

  @override
  Currency? fromJson(Map<String, dynamic>? json) {
    return Currency.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Currency entity) {
    return entity.toJson();  
  }

}