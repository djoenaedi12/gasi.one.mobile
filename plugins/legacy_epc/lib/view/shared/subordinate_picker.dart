import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/subordinate_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SubordinatePicker extends StatefulWidget {
  final Employee? employee;
  final Map<String, dynamic>? paramaters;
  const SubordinatePicker({Key? key, this.employee, this.paramaters}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SubordinatePickerState();
}

class _SubordinatePickerState extends State<SubordinatePicker> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<Employee> _employees = Pagination();
  final EmployeeRepository _employeeRepository = Repository().getEmployeeRepository();
  List<Sort> sorts = [Sort("name", SortDirection.ASC)];
  Map<String, dynamic> paramaters = HashMap();
  bool _isLoading = true;
  int _level = 1;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initData(_currentPage);
  }

  _initData(int page) {
    paramaters["subordinateLevel"] = _level;
    paramaters["active"] = _isActive ? "1" : "0";
    if(widget.paramaters != null) {
      widget.paramaters!.forEach((key, value) { 
        paramaters.putIfAbsent(key, () => value);
      });
    }
    _employeeRepository.listPaginationSubordinate(page: page,sorts: sorts, parameters: paramaters).then((value) {
      setState(() {
        _employees = value;
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
    if(widget.paramaters != null) {
      widget.paramaters!.forEach((key, value) { 
        paramaters.putIfAbsent(key, () => value);
      });
    }
    
    await _employeeRepository.listPaginationSubordinate(page: _currentPage, sorts: sorts, parameters: paramaters).then((value) {
      for (var item in value.content) {
        setState(() {
          _employees.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
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
        title: Text(
          "Employee".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.search,
                      color: Config.DEFAULT_COLOR,
                    ),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (BuildContext bc) {
                          return SubordinateFilter(
                            level: _level,
                            isActive: _isActive,
                          );
                        }
                      ).then((value) {
                        if(value == null) return;
                        setState(() {
                          _level = value["level"];
                          _isActive = value["active"];
                          _currentPage = 0;
                          _isLoading = true;
                        });

                        _initData(_currentPage);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.filter_list_alt,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  hintText: "Search".tr(),
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onFieldSubmitted: (val) {
                  setState(() {
                    if(val != "") {
                      paramaters['name.like'] = val;
                    } else {
                      paramaters.clear();
                    }
                    _currentPage = 0;
                  });

                  _initData(_currentPage);
                },
              ),
            ),
          ),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: _employees.totalPages - _currentPage > 1,
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
          ),
        ],
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
      
    if(_employees.content.isEmpty) {
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
      itemCount: _employees.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        Employee employee = _employees.content[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(employee);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0, 
              horizontal: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Text(StringProvider.getInitials(employee.name)),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Text(
                    "${employee.name} (${employee.code})",
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.check,
                  color: widget.employee != null && widget.employee!.id == employee.id ? Config.DEFAULT_COLOR : Colors.white,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}