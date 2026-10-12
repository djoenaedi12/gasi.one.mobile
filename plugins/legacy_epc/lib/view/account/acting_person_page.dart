import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_acting_person.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/employee/employee_acting_person_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/employee_picker.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ActingPersonPage extends StatefulWidget {
  const ActingPersonPage({super.key});

  @override
  State<StatefulWidget> createState() => _ActingPersonPageState();
}

class _ActingPersonPageState extends State<ActingPersonPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<EmployeeActingPerson> _employeeActingPersons = Pagination();
  final EmployeeActingPersonRepository _employeeActingPersonRepository = Repository().getEmployeeActingPersonRepository();
  Map<String, dynamic> parameters = HashMap();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if(Config.user!.employee != null) {
      parameters['employee'] = Config.user!.employee!.id;
    }
    _initData(_currentPage);
  }

  _initData(int page) {
    _employeeActingPersonRepository.listPagination(page: page, parameters: parameters).then((value) {
      setState(() {
        _employeeActingPersons = value;
        _isLoading = false;
      });
    });
  }

  void _onRefresh() async {
    setState(() {
      _currentPage = 0;
    });
    await _initData(_currentPage);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    setState(() {
      _currentPage = _currentPage + 1;
    });
    await _employeeActingPersonRepository.listPagination(page: _currentPage, parameters: parameters).then((value) {
      for (var item in value.content) {
        setState(() {
          _employeeActingPersons.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  _delete(int index) {
    AlertProvider.showConfirmationDialog(
      message: "${"Are you sure want to delete data".tr()}?",
    ).then((value) {
      if(value == false) return;

      EasyLoading.show(status: "Please Wait".tr());
      _employeeActingPersonRepository.delete(id: _employeeActingPersons.content[index].id ?? 0).then((onError){
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Data has been deleted".tr(),
            ),
          ),
        ).then((value) {
          _initData(0);
        });
      }).catchError((onError){
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: onError.toString(),
            ),
          ),
        );
      });
    });
  }

  _save(Employee? actingPerson) {
    if(actingPerson == null) return;

    EasyLoading.show(status: "Please Wait".tr());
    EmployeeActingPerson employeeActingPerson = EmployeeActingPerson(
      null, 
      null, 
      null, 
      null, 
      null,
      null,
      BaseModel.getCustomValue(null),
      BaseModel.getMedia(null),
      Config.user!.employee,
      actingPerson
    );

    _employeeActingPersonRepository.save(entity: employeeActingPerson).then((onError){
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success".tr(),
            subTitle: "Data has been saved".tr(),
          ),
        ),
      ).then((value) {
        _initData(0);
      });
    }).catchError((onError){
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.error, size: 100, color: Colors.red),
            title: "Error".tr(),
            subTitle: onError.toString(),
          ),
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Acting Person".tr(),
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeePicker(
                      needConfirm: true,
                      paramaters: {"recordRule": "0"},
                    )
                  ),
                ).then((value) => _save(value));
              },
              child: Icon(
                Icons.add_box,
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            )
          ],
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: _employeeActingPersons.totalPages - _currentPage > 1,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: const ClassicHeader(),
        footer: CustomFooter(
          builder: (context, mode) {
            Widget? body;
            if (mode == LoadStatus.loading) {
              body = const CircularProgressIndicator();
            }
            return SizedBox(
              height: body != null ? 50.0 : 0.0,
              child: Center(child: body),
            );
          },
        ),
        child: buildData(),
      ),
    );
  }

  Widget buildData() {
    if(_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Platform.isAndroid
          ? CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR))
          : const CupertinoActivityIndicator(),
          const SizedBox(height: 15.0),
          Text(
            "Please Wait".tr(),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
      
    if(_employeeActingPersons.content.isEmpty) {
      return Center(
        child: Text(
          "No Data Found".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _employeeActingPersons.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.zero,
          child: Divider(height: 1, color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        Employee? employee = _employeeActingPersons.content[index].actingPerson;
        return Slidable(
          key: const ValueKey(1),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                flex: 1,
                autoClose: true,
                onPressed: (context) {
                  _delete(index);
                },
                label: "Delete".tr(),
                backgroundColor: Colors.red,
                icon: Icons.delete,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0, 
              horizontal: 15.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Text(StringProvider.getInitials(employee != null ? employee.name : "")),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Text(
                    "${employee!.name} (${employee.code})",
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}