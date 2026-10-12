import 'package:epeoplecare/module/attendance/model/attendance_correction.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class AttendanceCorrectionRepository extends AppWorkflowRepository<AttendanceCorrection> {

  AttendanceCorrectionRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attendance/correction");
  }

  @override
  AttendanceCorrection? fromJson(Map<String, dynamic>? json) {
    return AttendanceCorrection.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(AttendanceCorrection entity) {
    return entity.toJson();
  }

}