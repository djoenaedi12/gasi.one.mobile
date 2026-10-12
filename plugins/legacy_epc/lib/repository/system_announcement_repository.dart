import 'package:epeoplecare/model/system_announcement.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class SystemAnnouncementRepository extends BaseRepository<SystemAnnouncement> {
  
  SystemAnnouncementRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/system/announcement");
  }

  @override
  SystemAnnouncement? fromJson(Map<String, dynamic>? json) {
    return SystemAnnouncement.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(SystemAnnouncement entity) {
    return entity.toJson();
  }

}