import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/benefit/model/benefit_balance.dart';
import 'package:epeoplecare/module/benefit/model/benefit_balance_history.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_balance_history_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/card_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BenefitBalanceHistoryPage extends StatefulWidget {
  final BenefitBalance? benefitBalance;
  const BenefitBalanceHistoryPage({Key? key, this.benefitBalance}): super(key: key);

  @override
  State<StatefulWidget> createState() => _BenefitBalanceHistoryPageState();
}

class _BenefitBalanceHistoryPageState extends State<BenefitBalanceHistoryPage> {

  Pagination<BenefitBalanceHistory> _benefitBalanceHistories = Pagination();
  final BenefitBalanceHistoryRepository _benefitBalanceHistoryRepository = Repository().getBenefitBalanceHistoryRepository();
  bool _isLoading = true;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initData(); 
  }

  _initData() {
    Map<String, dynamic> parameters = HashMap();
    parameters["benefitBalance.id"] = widget.benefitBalance!.id;
    parameters["column.neq"] = "workflow";
    List<Sort> sorts = [];
    sorts.add(Sort("id", SortDirection.DESC));
    _benefitBalanceHistoryRepository.listPagination(page: _currentPage, sorts: sorts, parameters: parameters).then((value) {
      EasyLoading.dismiss();
      setState(() {
        _benefitBalanceHistories = value;
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
    Map<String, dynamic> parameters = HashMap();
    parameters["benefitBalance.id"] = widget.benefitBalance!.id;
    parameters["column.neq"] = "workflow";
    List<Sort> sorts = [];
    sorts.add(Sort("id", SortDirection.DESC));
    await _benefitBalanceHistoryRepository.listPagination(page: _currentPage, sorts: sorts, parameters: parameters).then((value) {
      for (var item in value.content) {
        setState(() {
          _benefitBalanceHistories.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
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
          "History".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SmartRefresher(
        controller: _refreshController,
        enablePullUp: _benefitBalanceHistories.totalPages - _currentPage > 1,
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

    if(_benefitBalanceHistories.content.isEmpty) {
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

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: CardPage(
        physics: const NeverScrollableScrollPhysics(),
        list: _benefitBalanceHistories.content,
        renderTitle: (data, index) {
          BenefitBalanceHistory history = data;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${DateProvider.convertDateStrFormat(history.updateTime, "yyyy-MM-dd HH:mm:ss", "dd-MM-yyyy HH:mm")} ${NumberProvider.decimalFormatDouble(history.amount)} ${history.benefitTransaction != null ? "(${history.benefitTransaction!.requestNo ?? ""})" : ""}",
                style: TextStyle(
                  color: history.amount < 0 ? Colors.red : Colors.black,
                ),
              ),
            ],
          );
        },
        renderBody: (data, index) {
          BenefitBalanceHistory history = data;
          return Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${"Date".tr()}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(DateProvider.convertDateStrFormat(history.updateTime, "yyyy-MM-dd HH:mm:ss", "dd-MM-yyyy HH:mm")),
                  ],
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: [
                    Text(
                      "${"Amount".tr()}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(NumberProvider.decimalFormatDouble(history.amount)),
                  ],
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: [
                    Text(
                      "${"Request".tr()}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(history.benefitTransaction != null ? history.benefitTransaction!.requestNo ?? "" : ""),
                  ],
                ),
                const SizedBox(height: 5.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${"Remark".tr()}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child:Text(history.remark ?? ""),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),        
    );
  }
}