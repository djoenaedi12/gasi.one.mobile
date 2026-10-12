import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/task/model/task.dart';
import 'package:epeoplecare/module/task/repository/task_repository.dart';
import 'package:epeoplecare/module/task/view/task_application_page.dart';
import 'package:epeoplecare/module/task/view/task_detail_page.dart';
import 'package:epeoplecare/module/task/view/task_filter.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TaskPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const TaskPage({super.key, this.title = "", this.icon});

  @override
  State<StatefulWidget> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with SingleTickerProviderStateMixin {
  final TaskRepository _taskRepository = Repository().getTaskRepository();
  List<List<dynamic>> data = [[], []];
  List<int> currentPage = [0, 0];
  List<bool> enabledPullUp = [false, false];
  List<bool> status = [false, true];
  List<String> tabs = ["Opened".tr(), "Closed".tr()];

  Employee? _assignee;
  TabController? _tabController;
  Map<String, dynamic> filters = HashMap();
  List<Sort> sorts = [Sort("priority", SortDirection.DESC), Sort("updateTime", SortDirection.DESC)];
  List<bool> isLoading = [true, true, true, true];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: data.length, vsync: this);
    _initData();
  }

  _initData() {
    for (var i = 0; i < currentPage.length; i++) {
      Map<String, dynamic> parameters = HashMap();
      filters.forEach((key, value) {
        parameters[key] = value;
      });
      // parameters['assignee.id'] = Config.user!.employee!.id;
      parameters['status.closed'] = status[i];
      // if (_subject != null) {
      //   parameters['subject.like'] = _subject;
      // }

      _taskRepository.listPagination(page: currentPage[i], parameters: parameters, sorts: sorts).then((value) {
        setState(() {
          if (value.totalPages - currentPage[i] > 1) {
            enabledPullUp[i] = true;
          } else {
            enabledPullUp[i] = false;
          }
          data[i] = value.content;
          isLoading[i] = false;
        });
        EasyLoading.dismiss();
      }).catchError((onError) {
          setState(() {
            isLoading[i] = false;
          });
      });
    }
  }

  _onRefresh(int index) async {
    setState(() {
      currentPage[0] = 0;
      currentPage[1] = 0;
    });
    await _initData();
  }

  _onLoading(int index) async {
    setState(() {
      currentPage[index] = currentPage[index] + 1;
    });
    Map<String, dynamic> parameters = HashMap();
    filters.forEach((key, value) {
      parameters[key] = value;
    });
    // parameters['assignee.id'] = Config.user!.employee!.id;
    parameters['status.closed'] = status[index];
    // if (_subject != null) {
    //   parameters['subject.like'] = _subject;
    // }

    await _taskRepository.listPagination(page: currentPage[index], parameters: parameters, sorts: sorts).then((value) {
      setState(() {
        if (value.totalPages - currentPage[index] > 1) {
          enabledPullUp[index] = true;
        } else {
          enabledPullUp[index] = false;
        }
        for (var item in value.content) {
          data[index].add(item);
        }
      });
    }).catchError((onError) {
        setState(() {
          isLoading[index] = false;
        });
    });
  }

  Widget _renderItem(dynamic param, int index) {
    Task taskRequest = param;
    List<Icon> icon = [
      const Icon(Icons.arrow_circle_down, size: 40, color: Color.fromARGB(255, 117, 117, 117)),
      const Icon(Icons.remove_circle_outline, size: 40, color: Color.fromARGB(255, 11, 190, 116), semanticLabel: "Normal"),
      const Icon(Icons.arrow_circle_up, size: 40, color: Color.fromARGB(255, 230, 36, 36), semanticLabel: "High"),
    ];

    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon[taskRequest.priority!.index],
                const SizedBox(width: 5.0),
                Text(
                  EnumProvider.convertToString(taskRequest.priority) ?? "",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: icon[taskRequest.priority!.index].color!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(taskRequest.subject, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5.0),
              Text(taskRequest.project!.name, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 5.0),
              Text(taskRequest.dueDate ?? "-", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  _onTapItem(dynamic param, int index) async {
    Task taskRequest = param;
    if (await _isEditAble(taskRequest)) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TaskApplicationPage(taskRequest: param))).then((value) {
        if (value == null) return;

        _initData();
      });
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailPage(title: "Application Detail".tr(), taskRequest: param))).then((value) {
        if (value == null) return;

        _initData();
      });
    }
  }

  Future<bool> _isEditAble(Task taskRequest) async {
    if (taskRequest.assignee!.id == Config.user!.employee!.id) {
      return true;
    }

    if (Config.user!.employee!.parent != null) {
      if (taskRequest.assignee!.id == Config.user!.employee!.parent!.id) {
        return true;
      }
    }

    if (taskRequest.status!.closed == false) {
      return true;
    }

    return false;
  }

  _filter() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return TaskFilter(assignee: _assignee);
      },
    ).then((value) {
      if (value == null) return;
      setState(() {
        // _dateFrom = value['dateFrom'];
        // _dateTo = value['dateTo'];
        _assignee = value['assignee'];

        // filters.clear();
        // if(_dateFrom != null) {
        //   filters.putIfAbsent("date.gte", () => DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd"));
        // }
        // if(_dateTo != null) {
        //   filters.putIfAbsent("date.lte", () => DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd"));
        // }
        if (_assignee != null) {
          filters.putIfAbsent("assignee.id", () => _assignee!.id);
        } else {
          filters.remove("assignee.id");
        }
      });

      EasyLoading.show(status: "Please Wait".tr());
      _initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TransactionTabPage(
      title: widget.title,
      titleWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR)),
          GestureDetector(
            child: const Icon(Icons.add_box),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskApplicationPage())).then((value) {
                if (value == null) return;

                _initData();
              });
            },
          ),
        ],
      ),
      onLoading: _onLoading,
      onRefresh: _onRefresh,
      data: data,
      enabledPullUp: enabledPullUp,
      renderItem: _renderItem,
      onTapItem: _onTapItem,
      tabs: tabs,
      isScrollable: false,
      tabController: _tabController,
      isLoading: isLoading,
      isFilter: true,
      onTapFilter: _filter,
      filtered: filters.isNotEmpty,
    );
  }
}
