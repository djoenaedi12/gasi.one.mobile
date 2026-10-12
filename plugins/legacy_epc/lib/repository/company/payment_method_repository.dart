import 'package:epeoplecare/model/company/payment_method.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class PaymentMethodRepository extends BaseRepository<PaymentMethod> {
  
  PaymentMethodRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/paymentMethod");
  }

  @override
  PaymentMethod? fromJson(Map<String, dynamic>? json) {
    return PaymentMethod.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(PaymentMethod entity) {
    return entity.toJson();  
  }

}