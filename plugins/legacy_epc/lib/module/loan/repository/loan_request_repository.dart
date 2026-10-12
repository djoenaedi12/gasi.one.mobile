import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class LoanRequestRepository extends AppWorkflowRepository<LoanRequest> {

  LoanRequestRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan");
  }

  @override
  LoanRequest? fromJson(Map<String, dynamic>? json) {
    return LoanRequest.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LoanRequest entity) {
    return entity.toJson();
  }

}