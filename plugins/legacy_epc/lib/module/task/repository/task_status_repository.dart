import 'package:epeoplecare/module/task/model/task_status.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class TaskStatusRepository extends BaseRepository<TaskStatus> {
  TaskStatusRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/task/status");
  }

  @override
  TaskStatus? fromJson(Map<String, dynamic>? json) {
    return TaskStatus.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TaskStatus entity) {
    return entity.toJson();
  }
}
