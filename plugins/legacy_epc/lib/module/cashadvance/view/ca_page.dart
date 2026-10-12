import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/shared/menu.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_application_page.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_approval_page.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_submission_page.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_page.dart';
import 'package:flutter/material.dart';

class CAPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const CAPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _CAPageState();
}

class _CAPageState extends State<CAPage> {
  List<Menu> menuHeader = [
    Menu("My Submission".tr(), Icons.format_indent_increase),
    Menu("My Approval".tr(), Icons.format_indent_increase),
  ];

  List<Menu> menuCreateNew = [];

  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();

  @override
  void initState() {
    super.initState();
    _getCount();
    menuCreateNew.add(Menu(widget.title, widget.icon ?? Icons.monetization_on));
  }

  _getCount() {
    Map<String, dynamic> parameters = HashMap();
    List<String> status = [
      EnumProvider.convertToString(WorkflowStatus.DRAFTED)!,
      EnumProvider.convertToString(WorkflowStatus.SUBMITTED)!,
      EnumProvider.convertToString(WorkflowStatus.SENDBACKED)!,
      EnumProvider.convertToString(WorkflowStatus.APPROVAL_PROCESS)!,
      EnumProvider.convertToString(WorkflowStatus.PULLBACKED)!,
    ];
    parameters['workflowStatus.in'] = status;
    parameters['employee'] = Config.user!.employee!.id;
    _caRequestRepository.listPagination(parameters: parameters).then((value) {
      setState(() {
        if(value.totalElements > 0 && value.totalElements < 100) {
          menuHeader[0].title = "${"My Submission".tr()} (${value.totalElements})";
        } else if(value.totalElements >= 100) {
            menuHeader[0].title = "${"My Submission".tr()} (99+)";
        } else {
          menuHeader[0].title = "My Submission".tr();
        }
      });
    });

    parameters.clear();
    parameters["executor"] = Config.user!.employee!.id;
    _caRequestRepository.listPaginationPendingApproval(parameters: parameters).then((value) {
      setState(() {
        if(value.totalElements > 0 && value.totalElements < 100) {
          menuHeader[1].title = "${"My Approval".tr()} (${value.totalElements})";
        } else if(value.totalElements >= 100) {
          menuHeader[1].title = "${"My Approval".tr()} (99+)";
        } else {
          menuHeader[1].title = "My Approval".tr();
        }
      });
    });
  }

  _onHeaderMenuPress(val) {
    if (val == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CASubmissionPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
      });
    } else if (val == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CAApprovalPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
      });
    }
  }

  _onCreateNewMenuPress(val) {
    if (val == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CAApplicationPage(),
        ),
      ).then((value) {
        _getCount();
      });
    }
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
          widget.title,
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
        elevation: 0.0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TransactionPage(
              headerMenu: menuHeader,
              createNewMenu: menuCreateNew,
              onHeaderMenuPress: _onHeaderMenuPress,
              onCreateNewMenuPress: _onCreateNewMenuPress,
              menuModules: Config.getMenuOthers("/module/cashadvance", context),
            ),
          ],
        ),
      ),
    );
  }
}
