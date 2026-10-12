
import 'package:epeoplecare/model/employee/employee_acting_person.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class EmployeeActingPersonRepository extends BaseRepository<EmployeeActingPerson> {
  
  EmployeeActingPersonRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/employee/acting-person");
  }

  @override
  EmployeeActingPerson? fromJson(Map<String, dynamic>? json) {
    return EmployeeActingPerson.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(EmployeeActingPerson entity) {
    return entity.toJson();
  }

}