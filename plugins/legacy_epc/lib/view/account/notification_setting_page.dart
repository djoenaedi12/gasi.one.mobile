import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee_notification_type.dart';
import 'package:epeoplecare/model/notification_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/employee/employee_notification_type_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';

class NotificationSettingPage extends StatefulWidget {
  const NotificationSettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  
  final Map<NotificationType, bool> _empNotificationTypes = {
    NotificationType.APP: false,
    NotificationType.EMAIL: false,
  };
  final EmployeeNotificationTypeRepository _employeeNotificationTypeRepository = Repository().getEmployeeNotificationTypeRepository();
  
  @override
  void initState() {
    super.initState();
    initData();
  }

  initData() {
    _employeeNotificationTypeRepository.listByEmployee(Config.user!.employee!).then((value) {
        for (EmployeeNotificationType item in value) {
          if(_empNotificationTypes.containsKey(item.notificationType)) {
            setState(() {
              _empNotificationTypes[item.notificationType ?? NotificationType.APP] = true;              
            });
          }
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Notification Setting".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ListView(
            shrinkWrap: true,
            children: _empNotificationTypes.keys.map((NotificationType key) {
              return CheckboxListTile(
                title: Text(key.toString().tr()),
                value: _empNotificationTypes[key],
                activeColor: Config.DEFAULT_COLOR,
                onChanged: (bool? value) {
                  setState(() {
                    _empNotificationTypes[key] = value ?? false;
                  });
                  
                  List<String> notificationTypes = [];
                  _empNotificationTypes.keys.map((NotificationType key) {
                    if(_empNotificationTypes[key] == true) {
                      notificationTypes.add(EnumProvider.convertToString(key) ?? "");
                    }
                  }).toList();
                  _employeeNotificationTypeRepository.saveAll(employee: Config.user!.employee!, notificationTypes: notificationTypes);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}