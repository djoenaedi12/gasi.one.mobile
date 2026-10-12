import 'dart:collection';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/module/attendance/repository/flex_hour_repository.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_balance_history_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_balance_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_transaction_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/allowance_mapping_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/allowance_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_allowance_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_detail_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/destination_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/purpose_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_category_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_policy_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_settlement_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_value_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_balance_history_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_balance_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_category_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_group_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
import 'package:epeoplecare/module/leave/repository/whereabout_transaction_repository.dart';
import 'package:epeoplecare/module/letter/repository/letter_repository.dart';
import 'package:epeoplecare/module/letter/repository/letter_type_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_change_request_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_type_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_validation_interest_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_validation_repository.dart';
import 'package:epeoplecare/module/overtime/repository/overtime_transaction_repository.dart';
import 'package:epeoplecare/module/payroll/repository/employee_salary_slip_repository.dart';
import 'package:epeoplecare/module/task/repository/task_status_repository.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/module/workflow/repository/workflow_detail_repository.dart';
import 'package:epeoplecare/module/task/repository/task_repository.dart';
import 'package:epeoplecare/module/task/repository/project_repository.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/repository/appearance_setting_repository.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/client_repository.dart';
import 'package:epeoplecare/repository/company/announcement_repository.dart';
import 'package:epeoplecare/repository/company/attribute_repository.dart';
import 'package:epeoplecare/repository/company/attribute_type_repository.dart';
import 'package:epeoplecare/repository/company/currency_rate_repository.dart';
import 'package:epeoplecare/repository/company/currency_repository.dart';
import 'package:epeoplecare/repository/company/organization_unit_repository.dart';
import 'package:epeoplecare/repository/company/payment_method_repository.dart';
import 'package:epeoplecare/repository/company/public_holiday_repository.dart';
import 'package:epeoplecare/repository/company/schedule_repository.dart';
import 'package:epeoplecare/repository/company/shift_repository.dart';
import 'package:epeoplecare/repository/company/working_location_repository.dart';
import 'package:epeoplecare/repository/employee/employee_acting_person_repository.dart';
import 'package:epeoplecare/repository/employee/employee_dependent_repository.dart';
import 'package:epeoplecare/repository/employee/employee_notification_type_repository.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/repository/employee/employee_schedule_repository.dart';
import 'package:epeoplecare/repository/employee/employee_working_location_repository.dart';
import 'package:epeoplecare/repository/file_repository.dart';
import 'package:epeoplecare/repository/license_repository.dart';
import 'package:epeoplecare/repository/media_repository.dart';
import 'package:epeoplecare/repository/notification_repository.dart';
import 'package:epeoplecare/repository/parameter_repository.dart';
import 'package:epeoplecare/repository/system_announcement_repository.dart';
import 'package:epeoplecare/repository/user_repository.dart';

class Repository {
  static String _baseUrl = "";
  static String _accessToken = "";
  static String _refreshToken = "";
  static String _language = "en";

  Future<bool> initData() async {
    _baseUrl = await ClientProvider().getUrl();
    _accessToken = await SessionProvider().getAccessToken();
    _refreshToken = await SessionProvider().getRefreshToken();
    _language = Config.language;
    return true;
  }

  Map<String, String> generateHeader() {
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Bearer $_accessToken";
    headers["Content-Type"] = "application/json";
    headers["Accept-Language"] = _language;
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["DeviceId"] = Config.deviceId;
    headers["Version"] = Config.packageInfo.version;
    return headers;
  }

  String? getBaseUrl() {
    return _baseUrl;
  }

  String? getAccessToken() {
    return _accessToken;
  }

  String? getRefreshToken() {
    return _refreshToken;
  }

  String getLanguange() {
    return _language;
  }

  setLanguange(String language) {
    _language = language;
  }

  // ==================== Client ============================
  getClientRepository() {
    return ClientRepository(_baseUrl, _language);
  }

  // ==================== Common ============================
  getSystemAnnouncementRepository() {
    return SystemAnnouncementRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getAppearanceSettingRepository() {
    return AppearanceSettingRepository(_baseUrl, _language);
  }

  getAuthRepository() {
    return AuthRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getFileRepository() {
    return FileRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLicenseRepository() {
    return LicenseRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getUserRepository() {
    return UserRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getParameterRepository() {
    return ParameterRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getNotificationRepository() {
    return NotificationRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getMediaRepository() {
    return MediaRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ====================== Company ===========================
  getAnnouncementRepository() {
    return AnnouncementRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getAttributeTypeRepository() {
    return AttributeTypeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getAttributeRepository() {
    return AttributeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCurrencyRateRepository() {
    return CurrencyRateRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCurrencyRepository() {
    return CurrencyRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getOrganizationUnitRepository() {
    return OrganizationUnitRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getPaymentMethodRepository() {
    return PaymentMethodRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getPublicHolidayRepository() {
    return PublicHolidayRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getScheduleRepository() {
    return ScheduleRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getShiftRepository() {
    return ShiftRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getWorkingLocationRepository() {
    return WorkingLocationRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =============================== Employee ==============================
  getEmployeeRepository() {
    return EmployeeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getEmployeeNotificationTypeRepository() {
    return EmployeeNotificationTypeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getEmployeeActingPersonRepository() {
    return EmployeeActingPersonRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getEmployeeDependentRepository() {
    return EmployeeDependentRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getEmployeeScheduleRepository() {
    return EmployeeScheduleRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getEmployeeWorkingLocationRepository() {
    return EmployeeWorkingLocationRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ============================== Custom Field =============================
  getCustomFieldRepository() {
    return CustomFieldRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCustomValueRepository() {
    return CustomValuesRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ============================= Workflow ===================================
  getWorkflowDetailRepository() {
    return WorkflowDetailRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getNodeRepository() {
    return NodeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ============================ Letter =======================================
  getLetterRepository() {
    return LetterRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLetterTypeRepository() {
    return LetterTypeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ============================ Payroll =====================================
  getEmployeeSalarySlipRepository() {
    return EmployeeSalarySlipRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ============================= Attendance ==================================
  getAttendanceCorrectionRepository() {
    return AttendanceCorrectionRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getWorkFromHomeRepository() {
    return WorkFromHomeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getFlexHourRepository() {
    return FlexHourRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getAttendanceTransactionRepository() {
    return AttendanceTransactionRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ==================================== Benefit ===================================
  getBenefitRepository() {
    return BenefitRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBenefitBalanceRepository() {
    return BenefitBalanceRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBenefitTransactionRepository() {
    return BenefitTransactionRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBenefitBalanceHistoryRepository() {
    return BenefitBalanceHistoryRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // ================================== BTrip =========================================
  getAllowanceRepository() {
    return AllowanceRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getAllowanceMappingRepository() {
    return AllowanceMappingRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getDestinationRepository() {
    return DestinationRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getPurposeRepository() {
    return PurposeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBusinessTripRequestRepository() {
    return BusinessTripRequestRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBusinessTripRequestDetailRepository() {
    return BusinessTripRequestDetailRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getBusinessTripRequestAllowanceRepository() {
    return BusinessTripRequestAllowanceRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =============================== Cash Advance ======================================
  getCAPolicyRepository() {
    return CAPolicyRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCACategoryRepository() {
    return CACategoryRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCARequestRepository() {
    return CARequestRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getCASettlementRepository() {
    return CASettlementRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =============================== Leave ==========================================
  getLeaveBalanceRepository() {
    return LeaveBalanceRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLeaveCategoryRepository() {
    return LeaveCategoryRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLeaveGroupRepository() {
    return LeaveGroupRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLeaveTransactionRepository() {
    return LeaveTransactionRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getWhereaboutRepository() {
    return WhereaboutRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLeaveBalanceHistoryRepository() {
    return LeaveBalanceHistoryRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =============================== Loan ============================================
  getLoanTypeRepository() {
    return LoanTypeRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLoanValidationRepository() {
    return LoanValidationRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLoanValidationInterestRepository() {
    return LoanValidationInterestRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLoanRequestRepository() {
    return LoanRequestRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLoanRequestInstallmentRepository() {
    return LoanRequestInstallmentRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getLoanChangeRequestRepository() {
    return LoanChangeRequestRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =========================== Overtime ===============================================
  getOvertimeTransactionRepository() {
    return OvertimeTransactionRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  // =========================== Task ===============================================
  getTaskRepository() {
    return TaskRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getProjectRepository() {
    return ProjectRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }

  getTaskStatusRepository() {
    return TaskStatusRepository(_baseUrl, _accessToken, _refreshToken, _language);
  }
}
