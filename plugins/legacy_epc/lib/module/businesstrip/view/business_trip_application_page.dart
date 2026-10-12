// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_repository.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_application_detail_page.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_detail_allowance_page.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BusinessTripApplicationPage extends StatefulWidget {
  final BusinessTripRequest? businessTripRequest;
  const BusinessTripApplicationPage({Key? key, this.businessTripRequest}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _BusinessTripApplicationPageState();
}

class _BusinessTripApplicationPageState extends State<BusinessTripApplicationPage> {
  final form = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final BusinessTripRequestRepository _businessTripRequestRepository = Repository().getBusinessTripRequestRepository();
  List<BusinessTripRequestDetail> businessTripRequestDetails = [];
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  bool deductionVisibility = false;
  List<Media> _medias = [];
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  bool _assignment = false;
  Employee? _assignee;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    if(widget.businessTripRequest != null) {
      _remarkController.text = widget.businessTripRequest!.description ?? "";
      _alternateAttachment = widget.businessTripRequest!.attachment;
      for (BusinessTripRequestDetail detail in widget.businessTripRequest!.businessTripRequestDetails) {
       businessTripRequestDetails.add(detail) ;
      }
      renderHistory(widget.businessTripRequest!.workflow!.workflowDetails);
      _customValues = widget.businessTripRequest!.customValues;
      _initWorkflowExecutor(widget.businessTripRequest!.workflow!.workflowExecutors);
      _medias = widget.businessTripRequest!.medias;
      _assignment = widget.businessTripRequest!.assignment!;
      _assignee = widget.businessTripRequest!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }

    _businessTripRequestRepository.isDeductionVisible().then((value) {
      setState(() {
        deductionVisibility = value;
      });
    });
  }

  _initCustomField() {
    _customFieldRepository.listByType("BusinessTripRequest").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            item, 
            item.type, 
            null, 
            null,
          );

          _customValues.add(customValue);
        });
      }
    });
  }

  // set data workflow executors jika terdapat node override
  _initWorkflowExecutor(List<WorkflowExecutor>? workflowExecutors) {
    if(Config.user!.employee == null) return;

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.BUSINESS_TRIP).then((value) {
      setState(() {
        for (Node node in value) {
          WorkflowExecutor? workflowExecutorTmp;
          if(workflowExecutors != null) {
            for(WorkflowExecutor workflowExecutor in workflowExecutors) {
              if(workflowExecutor.node!.id == node.id) {
                workflowExecutorTmp = workflowExecutor;
                break;
              }
            }
          }

          workflowExecutorTmp ??= WorkflowExecutor(
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              node,
              null,
            );

          _workflowExecutors.add(workflowExecutorTmp);
        }
      });
    });
  }

  renderHistory(List<WorkflowDetail> histories) {
    setState(() {
      Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
      for (WorkflowDetail history in histories) {
        DateTime? executedDate = DateProvider.convertStr2Date(history.executedDate, "yyyy-MM-dd HH:mm:ss");
        history.executedDate = DateProvider.convertDate2Str(DateProvider.convertToLocal(executedDate, duration), "yyyy-MM-dd HH:mm:ss");
      }
      
      histories.sort((a,b) {
        if(a.executedDate == null || b.executedDate == null) return 1;
        return b.executedDate!.compareTo(a.executedDate!);
      });
      approvalHistories.clear();
      for (var item in histories) {
        if(item.executedDate != null && item.workflowStatus != null && item.executor != null) {
          approvalHistories.add(item);
        }
      }
    });
  }

  _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      if(businessTripRequestDetails.isEmpty) {
        AlertProvider.showAlertDialog(
          message: "Business Trip Detail is required".tr(),
        );
        return;
      }

      EasyLoading.show(status: "Please Wait".tr());

      DateTime? dateFrom;
      DateTime? dateTo;
      for (BusinessTripRequestDetail detail in businessTripRequestDetails) {
        DateTime dateFromDetail = DateProvider.convertStr2Date(detail.dateFrom, "yyyy-MM-dd")!;
        DateTime dateToDetail = DateProvider.convertStr2Date(detail.dateTo, "yyyy-MM-dd")!;
        if(dateFrom == null || dateFrom.isAfter(dateFromDetail)) {
          dateFrom = dateFromDetail;
        }
        if(dateTo == null || dateTo.isBefore(dateToDetail)) {
          dateTo = dateToDetail;
        }
      }

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;

      BusinessTripRequest businessTripRequest = BusinessTripRequest(
        widget.businessTripRequest != null ? widget.businessTripRequest!.id : null, 
        widget.businessTripRequest != null ? widget.businessTripRequest!.creator : null, 
        widget.businessTripRequest != null ? widget.businessTripRequest!.creationTime : null, 
        widget.businessTripRequest != null ? widget.businessTripRequest!.updater : null, 
        widget.businessTripRequest != null ? widget.businessTripRequest!.updateTime : null, 
        widget.businessTripRequest != null ? widget.businessTripRequest!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.businessTripRequest != null ? widget.businessTripRequest!.workflow : null,
        widget.businessTripRequest != null ? widget.businessTripRequest!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        DateProvider.convertDate2Str(dateFrom!, "yyyy-MM-dd"),
        DateProvider.convertDate2Str(dateTo!, "yyyy-MM-dd"),
        widget.businessTripRequest != null ? widget.businessTripRequest!.settlementDate : null,
        businessTripRequestDetails,
      );

      if(widget.businessTripRequest != null) {
        _businessTripRequestRepository.update(id: widget.businessTripRequest!.id!, entity: businessTripRequest).then((value) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: workflowStatus == WorkflowStatus.DRAFTED 
                        ? "Data has been saved".tr()
                        : "Data has been".tr(namedArgs: {"status": workflowStatus.toString().tr()}),
              ),
            ),
          ).then((value) {
            Navigator.pop(context, true);
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
      } else {
        _businessTripRequestRepository.save(entity: businessTripRequest).then((value) {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: workflowStatus == WorkflowStatus.DRAFTED 
                        ? "Data has been saved".tr()
                        : "Data has been".tr(namedArgs: {"status": workflowStatus.toString().tr()}),
              ),
            ),
          ).then((value) {
            Navigator.pop(context, true);
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
          "Application Form".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Visibility(
                      visible: Config.hasPermission("BusinessTripRequest", "RequestForOther") || Config.isManager,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderBooleanField(
                          value: _assignment,
                          controller: _assignmentController,
                          fieldName: "Assignment".tr(),
                          validator: Validation.validateField,
                          onChanged: (val) {
                            setState(() {
                              _assignment = val;
                              if(_assignment == false) {
                                _assignee = null;
                                _assigneeController.text = "";
                              }
                            });
                          }
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _assignment == true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderCustomField(
                          controller: _assigneeController,
                          fieldName: "Assignee".tr(),
                          validator: Validation.validateField,
                          onTap: () {
                            Map<String, dynamic> parameters = HashMap();
                            if(Config.user!.employee != null) {
                              parameters.putIfAbsent("subordinate", () => Config.user!.employee!.id);
                            }
                            parameters.putIfAbsent("entity", () => "BusinessTripRequest");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubordinatePicker(
                                  paramaters: parameters,
                                  employee: _assignee,
                                )
                              ),
                            ).then((value) {
                              if(value == null) return;

                              setState(() {
                                _assignee = value;
                                _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
                              });
                            });
                          }
                        ),
                      ),
                    ),
                    DetailPage(
                      itemList: businessTripRequestDetails,
                      title: "Application Detail".tr(),
                      onDelete: (index) {
                        setState(() {
                          businessTripRequestDetails.removeAt(index);
                        });
                      },
                      onEdit: (val, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessTripApplicationDetailPage(
                              businessTripRequestDetail: val,
                              deductionVisibility: deductionVisibility,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            businessTripRequestDetails[index] = value;
                          });
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessTripApplicationDetailPage(
                              deductionVisibility: deductionVisibility,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            businessTripRequestDetails.add(value);
                          });
                        });
                      },
                      renderTitle: (val, index) {
                        BusinessTripRequestDetail detail = val;
                        return Text(
                          "${DateProvider.convertDateStrFormat(detail.dateFrom, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(detail.dateTo, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy")}"
                        );
                      },
                      renderBody: (data, index) {
                        BusinessTripRequestDetail detail = data;
                        Currency? currency;
                        double totalAllowanceAmount = 0.0;
                        for (BusinessTripRequestAllowance allowance in detail.businessTripRequestAllowances) {
                          currency = allowance.currency!;
                          totalAllowanceAmount += allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0);
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${"Purpose".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(detail.purpose!.name),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Destination".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(detail.destination!.name),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Date From".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(DateProvider.convertDateStrFormat(detail.dateFrom, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Date To".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(DateProvider.convertDateStrFormat(detail.dateTo, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BusinessTripDetailAllowancePage(
                                      businessTripRequestAllowances: detail.businessTripRequestAllowances,
                                      deductionVisibility: deductionVisibility,
                                      editable: true,
                                    ),
                                  ),
                                ).then((value) {
                                    totalAllowanceAmount = 0;
                                    for (BusinessTripRequestAllowance allowance in detail.businessTripRequestAllowances) {
                                      setState(() {
                                        totalAllowanceAmount += allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0);                                        
                                      });
                                    }
                                });
                              },
                              child: Row(
                                children: [
                                  Text(
                                    "${"Total Allowance".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${currency != null ? currency.symbol : ""} ${NumberProvider.decimalFormatDouble(totalAllowanceAmount)}",
                                  ),
                                  Text(
                                    " (${"View Detail".tr()})",
                                    style: TextStyle(
                                      color: Config.DEFAULT_COLOR,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Description".tr(),
                        controller: _remarkController,
                        maxLines: 5,
                        maxLength: 100,
                        textInputType: TextInputType.multiline,
                      ),
                    ),
                    MultipleAttachmentPage(
                      medias: _medias,
                      attachment: _alternateAttachment,
                      editable: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomValuesPage(
                        customValues: _customValues,
                        editMode: widget.businessTripRequest != null ? true : false,
                      ),
                    ),
                    ApprovalHistoryPage(
                      approvalHistory: approvalHistories,
                      workflowExecutors: _workflowExecutors,
                      editable: true,
                      isExpand: _isExpand,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Process".tr(),
                onPressed: () async {
                  setState(() {
                    _isExpand = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (form.currentState!.validate()) {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext bc){
                        return ApprovalProcess(
                          workflowStatus: widget.businessTripRequest != null ? widget.businessTripRequest!.workflowStatus : null,
                          workflow: widget.businessTripRequest != null ? widget.businessTripRequest!.workflow : null,
                        );
                      },
                    ).then((value) {
                      if(value == null) return;

                      _submitForm(value['workflowStatus'], value['remark']);
                    });
                  }
                }
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
