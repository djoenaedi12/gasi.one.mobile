import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/view/shared/transaction_tab_item_page.dart';
import 'package:epeoplecare/module/workflow/view/workflow_filter.dart';
import 'package:flutter/material.dart';

class TransactionTabPage extends StatelessWidget {

  const TransactionTabPage({
    Key? key,
    this.title= "",
    this.titleWidget,
    required this.onTapItem,
    required this.onRefresh,
    required this.onLoading,
    required this.renderItem,
    this.data= const [[],[],[],[]],
    this.enabledPullUp= const [false, false, false, false],
    this.tabs= const ["Pending", "Approved", "Rejected", "Revoked"],
    this.isScrollable= false,
    this.tabController,
    this.isLoading= const [false, false, false, false],
    this.requestNo,
    this.employee,
    this.onFilterChange,
    this.isFilter= false,
    this.isApplicant= true,
    this.onTapFilter,
    this.filtered= false,
  }): super(key: key);

  final List<String> tabs;
  final String title;
  final Widget? titleWidget;
  final Function(dynamic, int) onTapItem;
  final Function(int) onRefresh;
  final Function(int) onLoading;
  final List<List<dynamic>> data;
  final Widget Function(dynamic, int) renderItem;
  final List<bool> enabledPullUp;
  final bool isScrollable;
  final TabController? tabController;
  final List<bool> isLoading;
  final String? requestNo;
  final Employee? employee;
  final Function(dynamic)? onFilterChange;
  final bool isFilter;
  final bool isApplicant;
  final Function? onTapFilter;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    if(tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Config.DEFAULT_COLOR,
          iconTheme: IconThemeData(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
          title: titleWidget ?? Text(
              title,
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            TransactionTabItemPage(
              onRefresh: () async {
                await onRefresh(0);
              },
              onLoading: () async {
                await onLoading(0);
              },
              data: data[0],
              enabledPullUp: enabledPullUp[0],
              renderItem: renderItem,
              onTapItem: onTapItem,
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: tabs.length,      
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
          title: titleWidget ?? Text(
              title,
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
          bottom: TabBar(
            unselectedLabelColor: Config.DEFAULT_ACCENT_COLOR.withValues(alpha: 0.7),
            labelColor: Config.DEFAULT_ACCENT_COLOR,
            indicatorColor: Config.DEFAULT_ACCENT_COLOR,
            isScrollable: isScrollable,
            controller: tabController,
            tabs: List<Widget>.generate(
              tabs.length,
              (int index) {
                return Tab(text: tabs[index]);
              },
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            TabBarView(
              controller: tabController,
              children: List<Widget>.generate(tabs.length, (int index) {
                return TransactionTabItemPage(
                  onRefresh: () async {
                    await onRefresh(index);
                  },
                  onLoading: () async {
                    await onLoading(index);
                  },
                  data: data[index],
                  enabledPullUp: enabledPullUp[index],
                  renderItem: renderItem,
                  onTapItem: onTapItem,
                  index: index,
                  isLoading: isLoading[index],
                );
              }),
            ),
            buildFilter(context),
          ],
        ),
      ),
    );
  }

  Widget buildFilter(BuildContext context) {
    if(!isFilter) {
      return const SizedBox();
    }
    
    var size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 30.0,
      left: (size.width / 2) - 50,
      child: GestureDetector(
        onTap: () {
          if(onTapFilter != null) {
            onTapFilter!();
          } else {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext bc) {
                return WorkflowFilter(
                  requestNo: requestNo,
                  employee: employee,
                  isApplicant: isApplicant,
                );
              }
            ).then((value) {
              onFilterChange!(value);
            });
          }
        },
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
                    visible: filtered,
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
    );
  }
}
