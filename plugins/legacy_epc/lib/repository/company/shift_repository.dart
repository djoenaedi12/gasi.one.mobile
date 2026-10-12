import 'package:epeoplecare/model/company/shift.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class ShiftRepository extends BaseRepository<Shift> {

  ShiftRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/shift");
  }

  @override
  Shift? fromJson(Map<String, dynamic>? json) {
    return Shift.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Shift entity) {
    return entity.toJson();
  }

}