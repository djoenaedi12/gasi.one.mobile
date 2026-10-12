import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/payroll/model/document_type.dart';
import 'package:epeoplecare/module/payroll/model/employee_salary_slip.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/payroll/view/payroll/payroll_filter.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/module/payroll/repository/employee_salary_slip_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class PayrollPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const PayrollPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {

  Map<String, dynamic> filters = HashMap();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<EmployeeSalarySlip> _salarySlips = Pagination();
  final EmployeeSalarySlipRepository _employeeSalarySlipRepository = Repository().getEmployeeSalarySlipRepository();
  List<Sort> sorts = [
    Sort("year", SortDirection.DESC),
    Sort("month", SortDirection.DESC),
    Sort("documentType", SortDirection.ASC),
  ];
  String? _year, _month;
  DocumentType? _documentType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _year = DateProvider.convertDate2Str(DateProvider.getCurrentDateMidnight(), "yyyy");
    filters.putIfAbsent("year", () => _year);
    _initData();
  }
  
  _initData() {
    filters.putIfAbsent("employee", () => Config.user!.employee!.id);
    _employeeSalarySlipRepository.listPagination(page: _currentPage, sorts: sorts, parameters: filters).then((value) {
      EasyLoading.dismiss();
      setState(() {
        _salarySlips = value;
        _isLoading = false;
      });
    }).catchError((onError) {
        setState(() {
          _isLoading = false;
        });
    });
  }

  void _onRefresh() async {
    setState(() {
      _currentPage = 0;
    });
    _initData();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    setState(() {
      _currentPage = _currentPage + 1;
    });
    filters.putIfAbsent("employee", () => Config.user!.employee!.id);
    await _employeeSalarySlipRepository.listPagination(page: _currentPage, sorts: sorts, parameters: filters).then((value) {
      for (var item in value.content) {
        setState(() {
          _salarySlips.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  _onTapItem(int index) {
    EmployeeSalarySlip? empSalarySlip = _salarySlips.content[index];
    urlFileShare(empSalarySlip);
  }

  _filterRecord() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return PayrollFilter(
          year: _year,
          month: _month,
          documentType: _documentType,
        );
      }
    ).then((value) {
      if (value == null) return;

      setState(() {
        filters.clear();
        _currentPage = 0;
        if(value['year'] != null && value['year'] != "") {
          _year = value['year'];
          filters.putIfAbsent("year", () => _year);
        } else {
          _year = null;
        }

        if(value['month'] != null && value['month'] != "") {
          _month = value['month'];
          filters.putIfAbsent("month", () => _month);
        } else {
          _month = null;
        }

        if(value['documentType'] != null) {
          _documentType = value['documentType'];
          filters.putIfAbsent("documentType", () => EnumProvider.convertToString(_documentType));
        } else {
          _documentType = null;
        }
      });
      

      EasyLoading.show(status: "Please Wait".tr());
      _initData();
    });
  }

  urlFileShare(EmployeeSalarySlip? empSalarySlip) {
    if(empSalarySlip == null || empSalarySlip.filePath == null || empSalarySlip.filePath == "") return;

    EasyLoading.show(status: "Please Wait".tr());
    List<int> ids = [empSalarySlip.id ?? 0];
    _employeeSalarySlipRepository.print(ids).then((value) async {
      EasyLoading.dismiss();
      if(value != null) {
        String fileName = "SalarySlip";
        if(empSalarySlip.documentType == DocumentType.BUKTI_POTONG_1721A1) {
          fileName = "BuktiPotong1721A1";
        }
        String dir = await StorageProvider().getExternalStorage();
        String ext = p.extension(empSalarySlip.filePath ?? "");
        fileName += '-${empSalarySlip.salaryPeriod}-${empSalarySlip.year}${empSalarySlip.month.toString().padLeft(2, '0')}-${empSalarySlip.employee!.code}$ext';
        File file = File('$dir/$fileName');
        await file.writeAsBytes(value);
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: "No Data Found".tr(),
            ),
          ),
        );
      }
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
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SmartRefresher(
            controller: _refreshController,
            enablePullUp: _salarySlips.totalPages - _currentPage > 1,
            enablePullDown: true,
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
          Positioned(
            bottom: 30.0,
            left: (size.width / 2) - 50,
            child: GestureDetector(
              onTap: _filterRecord,
              child: Container(
                padding: const EdgeInsets.all(5.0),
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      30.0,
                    )
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Icon(
                          Icons.filter_list_alt,
                          color: Config.DEFAULT_COLOR,
                        ),
                        Visibility(
                          visible: _year != null || _month != null || _documentType != null,
                          child: Positioned(
                            top: 2.0,
                            right: 0.0,
                            child: Container(
                              width: 9.0,
                              height: 9.0,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      "Filter".tr(),
                    )
                  ],
                ),
              ),
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

    if(_salarySlips.content.isEmpty) {
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
      itemCount: _salarySlips.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        var salarySlip = _salarySlips.content[index];
        DateTime period = DateTime(salarySlip.year!, salarySlip.month!, 1);
        return GestureDetector(
          onTap: () {
            _onTapItem(index);
          },
          child: Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: index == 0 ? 10.0 : 5.0,
              left: 10.0,
              right: 10.0,
              bottom: 10.0,
            ),
            padding: const EdgeInsets.all(
              7.0,
            ),
            child: Row(
              children: [
                Text(
                  EnumProvider.convertToString(salarySlip.documentType ?? '', capitalEachWord: true) ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  DateProvider.convertDate2Str(period, "yyyy MMMM"),
                ),
                const SizedBox(width: 5.0),
                Expanded(
                  child: Text(
                    salarySlip.description ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.grey,
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