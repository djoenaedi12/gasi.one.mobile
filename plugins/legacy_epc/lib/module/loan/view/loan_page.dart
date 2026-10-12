import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/shared/menu.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/model/loan_request_installment.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_repository.dart';
import 'package:epeoplecare/module/loan/view/loan_application_page.dart';
import 'package:epeoplecare/module/loan/view/loan_approval_page.dart';
import 'package:epeoplecare/module/loan/view/loan_detail_page.dart';
import 'package:epeoplecare/module/loan/view/loan_submission_page.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_page.dart';
import 'package:flutter/material.dart';

class LoanPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const LoanPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  List<Menu> menuHeader = [
    Menu("My Submission".tr(), Icons.format_indent_increase),
    Menu("My Approval".tr(), Icons.format_indent_increase),
  ];

  List<Menu> menuCreateNew = [];

  final LoanRequestRepository _loanRequestRepository = Repository().getLoanRequestRepository();
  final LoanRequestInstallmentRepository _loanRequestInstallmentRepository = Repository().getLoanRequestInstallmentRepository();
  int current = 0;
  List<LoanRequest> loanRequests = [];
  bool loanInstallmentVisibility = true;

  @override
  void initState() {
    super.initState();
    _getCount();
    _getActiveLoan();
    menuCreateNew.add(Menu(widget.title, widget.icon ?? Icons.calculate));
  }

  _getActiveLoan() async {
    loanInstallmentVisibility = await _loanRequestInstallmentRepository.isVisible();
    if(loanInstallmentVisibility == false) return;

    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = Config.user!.employee!.id;
    parameters['workflowStatus'] = EnumProvider.convertToString(WorkflowStatus.APPROVED);
    _loanRequestRepository.list(parameters: parameters).then((value) async {
      loanRequests.clear();
      for (LoanRequest loanRequest in value) {
        List<LoanRequestInstallment> loanRequestInstallments = await _loanRequestInstallmentRepository.getInstallments(loanRequest);
        loanRequest.loanRequestInstallments = loanRequestInstallments;
        setState(() {
          if(loanRequestInstallments.isNotEmpty) {
            LoanRequestInstallment loanRequestInstallment = loanRequestInstallments[loanRequestInstallments.length - 1];
            if(loanRequestInstallment.paymentDate == null) {
              loanRequests.add(loanRequest);  
            }
          } else {
            loanRequests.add(loanRequest);
          }
        });
      }
    }).catchError((e) {
      setState(() {
        loanRequests.clear();        
      });
    });
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
    _loanRequestRepository.listPagination(parameters: parameters).then((value) {
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
    _loanRequestRepository.listPaginationPendingApproval(parameters: parameters).then((value) {
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
          builder: (context) => LoanSubmissionPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
        _getActiveLoan();
      });
    } else if (val == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoanApprovalPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
        _getActiveLoan();
      });
    }
  }

  _onCreateNewMenuPress(val) {
    if (val == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoanApplicationPage(),
        ),
      ).then((value) {
        _getCount();
        _getActiveLoan();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionPage(
              headerMenu: menuHeader,
              createNewMenu: menuCreateNew,
              onHeaderMenuPress: _onHeaderMenuPress,
              onCreateNewMenuPress: _onCreateNewMenuPress,
              menuModules: Config.getMenuOthers("/module/loan", context),
            ),
            Visibility(
              visible: loanInstallmentVisibility,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 20.0,
                  left: 15.0,
                  right: 15.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Loan".tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                      ),
                    ),
                    Divider(
                      color: Config.DEFAULT_COLOR.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: loanInstallmentVisibility,
              child: buildActiveLoan(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActiveLoan() {
    var mediaQuery = MediaQuery.of(context);
    if(loanRequests.isEmpty) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: 10.0,
              left: 10.0,
            ),
            padding: const EdgeInsets.all(10.0),
            width: mediaQuery.size.width - 20,
            height: 185.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
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
            child: Center(
              child: Text(
                "No Data Found".tr(),
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            height: 8,
            margin: const EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  width: current == index ? 16.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(50.0),
                    ),
                    color: current == index ? Config.DEFAULT_COLOR : Colors.grey[300],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 245.0,
          child: PageView.builder(
            onPageChanged: (int index) {
              setState(() {
                current = index;
              });
            },
            scrollDirection: Axis.horizontal,
            itemCount: loanRequests.length,
            itemBuilder: (context, index) {
              var loanRequestTmp = loanRequests[index];
              LoanRequestInstallment? installment;
              double approvedAmountTmp = loanRequestTmp.approvedAmount ?? 0;
              double balancedAmountTmp = approvedAmountTmp;
              for (var loanRequestInstallment in loanRequestTmp.loanRequestInstallments) {
                if(loanRequestInstallment.paymentDate != null)                 {
                  balancedAmountTmp = loanRequestInstallment.principalBalance;
                }

                if(loanRequestInstallment.paymentDate == null) {
                  installment = loanRequestInstallment;
                }
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoanDetailPage(
                        loanRequest: loanRequestTmp,
                        title: "Application Form".tr(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    width: mediaQuery.size.width - 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                          5.0,
                        ),
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 15.0,
                              right: 15.0,
                              top: 15.0,
                              bottom: 5.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "${loanRequestTmp.requestNo} - ${loanRequestTmp.loanType!.name}",
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Container(
                                  padding: const EdgeInsets.all(10.0),
                                  width: mediaQuery.size.width,
                                  color: Colors.grey[300],
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Loan Amount".tr(),
                                      ),
                                      const SizedBox(height: 5.0),
                                      Text(
                                        "Rp ${NumberProvider.decimalFormatDouble(loanRequestTmp.approvedAmount)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              right: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Next Installment".tr(),
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      "Rp ${NumberProvider.decimalFormatDouble((installment!.interestAmount + installment.principalAmount))}",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Config.DEFAULT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Due Date".tr(),
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      DateProvider.convertDateStrFormat(installment.dueDate, "yyyy-MM-dd", "dd MMMM yyyy"),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Config.DEFAULT_COLOR,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Stack(
                              children: [
                                Container(
                                  width: mediaQuery.size.width,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: (mediaQuery.size.width - 50) * (approvedAmountTmp != 0 ? balancedAmountTmp/approvedAmountTmp : 1),
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                    color: Config.DEFAULT_COLOR,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: loanRequests.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Container(
                width: current == index ? 16.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                  color: current == index ? Config.DEFAULT_COLOR : Colors.grey[300],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }
}
