import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class WorkingLocationRepository extends BaseRepository<WorkingLocation> {

  WorkingLocationRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/working-location");
  }

  @override
  WorkingLocation? fromJson(Map<String, dynamic>? json) {
    return WorkingLocation.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WorkingLocation entity) {
    return entity.toJson();
  }

}