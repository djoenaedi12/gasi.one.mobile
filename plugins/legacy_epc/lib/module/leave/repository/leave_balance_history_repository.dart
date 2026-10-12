import 'package:epeoplecare/module/leave/model/leave_balance_history.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LeaveBalanceHistoryRepository extends BaseRepository<LeaveBalanceHistory> {
  
  LeaveBalanceHistoryRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave/balance/history");
  }

  @override
  LeaveBalanceHistory? fromJson(Map<String, dynamic>? json) {
    return LeaveBalanceHistory.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LeaveBalanceHistory entity) {
    return entity.toJson();
  }

}