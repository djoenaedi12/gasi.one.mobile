import 'dart:collection';

import 'package:epeoplecare/module/leave/model/leave_category.dart';
import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LeaveCategoryRepository extends BaseRepository<LeaveCategory> {
  
  LeaveCategoryRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave/category");
  }

  Future<List<LeaveCategory>> listByLeaveGroup(LeaveGroup leaveGroup) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['leaveGroup'] = leaveGroup.id;
    return await list(parameters: parameters);
  }

  @override
  LeaveCategory? fromJson(Map<String, dynamic>? json) {
    return LeaveCategory.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LeaveCategory entity) {
    return entity.toJson();
  }

}