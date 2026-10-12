import 'package:epeoplecare/module/cashadvance/model/ca_settlement.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class CASettlementRepository extends AppWorkflowRepository<CASettlement> {

  CASettlementRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/cashadvance/settlement");
  }

  @override
  CASettlement? fromJson(Map<String, dynamic>? json) {
    return CASettlement.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CASettlement entity) {
    return entity.toJson();
  }

}