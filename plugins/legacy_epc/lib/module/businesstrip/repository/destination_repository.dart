import 'package:epeoplecare/module/businesstrip/model/destination.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class DestinationRepository extends BaseRepository<Destination> {
  
  DestinationRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/destination");
  }

  @override
  Destination? fromJson(Map<String, dynamic>? json) {
    return Destination.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Destination entity) {
    return entity.toJson();  
  }

}