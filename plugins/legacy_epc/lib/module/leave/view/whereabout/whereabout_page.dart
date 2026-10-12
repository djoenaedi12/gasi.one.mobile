import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/leave/model/whereabout_status.dart';
import 'package:epeoplecare/module/leave/model/whereabout_transaction.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_application_page.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_detail_page.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_filter.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/leave/repository/whereabout_transaction_repository.dart';
import 'package:epeoplecare/view/shared/transaction_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class WhereaboutPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const WhereaboutPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _WhereaboutPageState();
}

class _WhereaboutPageState extends State<WhereaboutPage> with SingleTickerProviderStateMixin {
  
  final WhereaboutRepository _whereaboutRepository = Repository().getWhereaboutRepository();
  List<List<dynamic>> data = [
    [],
    [],
  ];
  List<int> currentPage = [0, 0];
  List<bool> enabledPullUp = [false, false];
  List<List<String>> status = [
    [
      EnumProvider.convertToString(WhereaboutStatus.OPEN)!,
      EnumProvider.convertToString(WhereaboutStatus.OVERDUE)!,
    ], 
    [
      EnumProvider.convertToString(WhereaboutStatus.CLOSED)!,
      EnumProvider.convertToString(WhereaboutStatus.CLOSED_OVERDUE)!,
      EnumProvider.convertToString(WhereaboutStatus.CANCEL)!,
    ], 
  ];
  List<String> tabs = [
    "Opened".tr(),
    "Closed".tr(),
  ];

  DateTime? _dateFrom = DateProvider.getCurrentDateMidnight();
  DateTime? _dateTo = DateProvider.getCurrentDateMidnight();
  Employee? _employee;
  TabController? _tabController;
  Map<String, dynamic> filters = HashMap();
  List<Sort> sorts = [Sort("updateTime", SortDirection.DESC)];
  List<bool> isLoading = [true, true, true, true];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: data.length, vsync: this);
    filters.putIfAbsent("date.gte", () => DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd"));
    filters.putIfAbsent("date.lte", () => DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd"));
    _initData();
  }

  _initData() {
    Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
    for (var i = 0; i < currentPage.length; i++) {
      Map<String, dynamic> parameters = HashMap();
      filters.forEach((key, value) { 
        parameters[key] = value;  
      });
      parameters['whereaboutStatus.in'] = status[i];
      
      _whereaboutRepository.listPagination(page: currentPage[i], parameters: parameters, sorts: sorts).then((value) {
        setState(() {
          if(value.totalPages - currentPage[i] > 1) {
            enabledPullUp[i] = true;
          } else {
            enabledPullUp[i] = false;
          }
          for (WhereaboutTransaction whereabout in value.content) {
            if(whereabout.actualDate == null || whereabout.actualDate == "" || whereabout.actualTime == null || whereabout.actualTime == "") continue;
            
            DateTime actualDate = DateProvider.convertStr2Date(whereabout.actualDate, "yyyy-MM-dd")!;
            DateTime actualTime = DateProvider.convertStr2Date(whereabout.actualTime, "HH:mm:ss")!;
            DateTime actualDateTime = DateTime(actualDate.year, actualDate.month, actualDate.day, actualTime.hour, actualTime.minute, actualTime.second);
            whereabout.actualDate = DateProvider.convertDate2Str(DateProvider.convertToLocal(actualDateTime, duration), "yyyy-MM-dd");
            whereabout.actualTime = DateProvider.convertDate2Str(DateProvider.convertToLocal(actualDateTime, duration), "HH:mm:ss");
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
    parameters['whereaboutStatus.in'] = status[index];
    _whereaboutRepository.listPagination(page: currentPage[index], parameters: parameters, sorts: sorts).then((value) {
      setState(() {
        if(value.totalPages - currentPage[index] > 1) {
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
    WhereaboutTransaction wat = param;
    WhereaboutStatus? status = wat.whereaboutStatus;
    Color statusColor;
    DateTime dateCurr = DateProvider.convertStr2Date(DateProvider.convertDate2Str(DateProvider.getCurrentDate(), "yyyy-MM-dd HH:mm"), "yyyy-MM-dd HH:mm")!;
    DateTime date = DateProvider.convertStr2Date(wat.date, "yyyy-MM-dd")!;
    DateTime timeTo = DateProvider.convertStr2Date(wat.timeTo, "HH:mm:ss")!;
    DateTime returnTime = DateTime(date.year, date.month, date.day, timeTo.hour, timeTo.minute);

    if((wat.whereaboutStatus == WhereaboutStatus.OPEN && dateCurr.compareTo(returnTime) > 0) || wat.whereaboutStatus == WhereaboutStatus.OVERDUE || wat.whereaboutStatus == WhereaboutStatus.CLOSED_OVERDUE) {
      statusColor = Colors.red;

      if(wat.whereaboutStatus == WhereaboutStatus.OPEN) {
        status = WhereaboutStatus.OVERDUE;
      }
    } else if(wat.whereaboutStatus == WhereaboutStatus.CLOSED || wat.whereaboutStatus == WhereaboutStatus.CANCEL) {
      statusColor = Colors.grey;
    } else {
      statusColor = Config.DEFAULT_COLOR;
    }

    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: Config.DEFAULT_COLOR,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wat.employee != null ? wat.employee!.name : "",
                  style: const TextStyle(
                    fontSize: 18.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 3.0),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        wat.destination ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        status.toString().tr(),
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Config.DEFAULT_ACCENT_COLOR,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5.0),
                Text(
                  "${DateProvider.convertDateStrFormat(wat.date, "yyyy-MM-dd", "EEEE, dd MMMM yyyy")} ${DateProvider.convertDateStrFormat(wat.timeFrom, "HH:mm:ss", "HH:mm")} - ${DateProvider.convertDateStrFormat(wat.timeTo, "HH:mm:ss", "HH:mm")}",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _onTapItem(dynamic param, int index) {
    WhereaboutTransaction wat = param;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhereaboutDetailPage(
          whereaboutTransaction: wat,
        ),
      ),
    ).then((value) {
      if(value == null) return;

      _initData();
    });
  }
  
  _filter() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return WhereaboutFilter(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          employee: _employee,
        );
      }
    ).then((value) {
      if (value == null) return;
      setState(() {
        _dateFrom = value['dateFrom'];
        _dateTo = value['dateTo'];
        _employee = value['employee'];

        filters.clear();
        if(_dateFrom != null) {
          filters.putIfAbsent("date.gte", () => DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd"));
        }
        if(_dateTo != null) {
          filters.putIfAbsent("date.lte", () => DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd"));
        }
        if(_employee != null) {
          filters.putIfAbsent("employee", () => _employee!.id);
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
          Text(
            widget.title,
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
            ),
          ),
          GestureDetector(
            child: const Icon(Icons.add_box),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WhereaboutApplicationPage(),
                ),
              ).then((value) {
                if(value == null) return;
                
                _initData();
              });
            }
          )
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