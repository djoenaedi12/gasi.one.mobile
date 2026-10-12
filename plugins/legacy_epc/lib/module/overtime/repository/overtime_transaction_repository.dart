import 'package:epeoplecare/module/overtime/model/overtime_transaction.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class OvertimeTransactionRepository extends AppWorkflowRepository<OvertimeTransaction> {

  OvertimeTransactionRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/overtime");
  }

  @override
  OvertimeTransaction? fromJson(Map<String, dynamic>? json) {
    return OvertimeTransaction.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(OvertimeTransaction entity) {
    return entity.toJson();
  }

}