import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/module/task/repository/project_repository.dart';
import 'package:epeoplecare/module/task/repository/task_status_repository.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/view/shared/employee_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ModelPicker extends StatefulWidget {
  final dynamic data;
  final dynamic repository;
  final List<Sort> sorts;
  final String title;
  final Function(Map<String, dynamic>, String)? onFieldSubmitted;
  final Function(dynamic, dynamic)? itemBuilder;
  final Map<String, dynamic>? paramaters;
  const ModelPicker({Key? key, this.data, this.repository, this.sorts = const [], this.title = "", this.onFieldSubmitted, this.itemBuilder, this.paramaters}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<ModelPicker> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<dynamic> _datas = Pagination();
  Map<String, dynamic> paramaters = HashMap();
  bool _isLoading = true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if(widget.paramaters != null) {
      widget.paramaters!.forEach((key, value) { 
        paramaters[key] = value;
      });
    }
    _initData(_currentPage);
  }

  _initData(int page) {
    if(widget.repository is EmployeeRepository) {
      paramaters["active"] = _isActive ? "1" : "0";
    }

    // Nantinya untuk semua data reference akan menggunakan listPaginationReference
    // Karena baru yang diimplementasikan baru Project & TaskStatus (yang digunakan di mobile)
    // Maka baru 2 itu saja
    if(widget.repository is ProjectRepository || widget.repository is TaskStatusRepository) {
      widget.repository.listPaginationReference(page: page,sorts: widget.sorts, parameters: paramaters).then((value) {
        setState(() {
          _datas = value;
          _isLoading = false;
        });
      });
    } else {
      widget.repository.listPagination(page: page,sorts: widget.sorts, parameters: paramaters).then((value) {
        setState(() {
          _datas = value;
          _isLoading = false;
        });
      });
    }
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
    await widget.repository.listPagination(page: _currentPage, sorts: widget.sorts, parameters: paramaters).then((value) {
      for (var item in value.content) {
        setState(() {
          _datas.add(item);          
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
          widget.title,
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
                  suffixIcon: widget.repository is EmployeeRepository ? 
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (BuildContext bc) {
                            return EmployeeFilter(
                              isActive: _isActive,
                            );
                          }
                        ).then((value) {
                          if(value == null) return;
                          setState(() {
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
                    )
                  : SizedBox(),
                  border: InputBorder.none,
                  hintText: "Search".tr(),
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onFieldSubmitted: (val) {
                  setState(() {
                    if(val != "") {
                      if(widget.onFieldSubmitted != null) {
                        widget.onFieldSubmitted!(paramaters, val);
                      } else {
                        paramaters['name.like'] = val;
                      }
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
              enablePullUp: _datas.totalPages - _currentPage > 1,
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
      
    if(_datas.content.isEmpty) {
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
      itemCount: _datas.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        dynamic data = _datas.content[index];
        return GestureDetector(
          onTap: () {            
            Navigator.of(context).pop(data);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0, 
              horizontal: 10.0,
            ),
            child: widget.itemBuilder != null 
            ? widget.itemBuilder!(widget.data, data)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(StringProvider.getInitials(data != null ? data.name : "")),
                  ),
                  const SizedBox(width: 15.0),
                  Expanded(
                    child: Text(
                      "${data.name}",
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.check,
                    color: widget.data != null && widget.data.id == data.id ? Config.DEFAULT_COLOR : Colors.white,
                  )
                ],
              )
          ),
        );
      },
    );
  }
}