import 'package:epeoplecare/model/company/schedule.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class ScheduleRepository extends BaseRepository<Schedule> {

  ScheduleRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/schedule");
  }

  @override
  Schedule? fromJson(Map<String, dynamic>? json) {
    return Schedule.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Schedule entity) {
    return entity.toJson();
  }

}