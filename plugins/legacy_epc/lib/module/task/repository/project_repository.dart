import 'package:epeoplecare/module/task/model/project.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class ProjectRepository extends BaseRepository<Project> {
  ProjectRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/task/project");
  }

  @override
  Project? fromJson(Map<String, dynamic>? json) {
    return Project.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Project entity) {
    return entity.toJson();
  }
}
