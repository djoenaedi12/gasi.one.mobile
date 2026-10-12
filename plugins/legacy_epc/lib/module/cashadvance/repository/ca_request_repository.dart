import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class CARequestRepository extends AppWorkflowRepository<CARequest> {

  CARequestRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/cashadvance/request");
  }

  @override
  CARequest? fromJson(Map<String, dynamic>? json) {
    return CARequest.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CARequest entity) {
    return entity.toJson();
  }

}