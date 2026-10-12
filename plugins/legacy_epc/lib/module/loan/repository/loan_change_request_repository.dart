import 'package:epeoplecare/module/loan/model/loan_change_request.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class LoanChangeRequestRepository extends AppWorkflowRepository<LoanChangeRequest> {

  LoanChangeRequestRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan/change");
  }

  @override
  LoanChangeRequest? fromJson(Map<String, dynamic>? json) {
    return LoanChangeRequest.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LoanChangeRequest entity) {
    return entity.toJson();
  }

}