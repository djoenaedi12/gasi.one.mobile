import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/workflow/model/node_owner_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/employee_picker.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class ApprovalHistoryPage extends StatefulWidget {
  
  final List<WorkflowDetail> approvalHistory;
  final List<WorkflowExecutor> workflowExecutors;
  final bool editable;
  final bool isExpand;
  const ApprovalHistoryPage({Key? key, this.approvalHistory = const [], this.workflowExecutors = const [], this.editable= false, this.isExpand=true}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _ApprovalHistoryPageState();
}

class _ApprovalHistoryPageState extends State<ApprovalHistoryPage> {
  
  bool _isExpand = true;
  List<WorkflowDetail> _approvalHistory = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _approvalHistory = widget.approvalHistory;
    _isExpand = widget.isExpand;
  }

  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 15.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    _isExpand = !_isExpand;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Approval History".tr(),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Icon(
                      !_isExpand ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 25.0, 
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15.0,
              ),
              Divider(height: 1, color: Colors.grey.shade300),
            ],
          ),
        ),
        Visibility(
          visible: _isExpand,
          child: Container(
            color: Colors.grey[200],
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: widget.workflowExecutors.isEmpty
                              ? 0.0
                              : widget.editable == false
                                ? 5.0
                                : 15,
                    horizontal: widget.editable ? 10.0 : 0.0,
                  ),
                  color: Colors.white,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.workflowExecutors.length,
                    itemBuilder: (BuildContext bc, int index) {
                      WorkflowExecutor workflowExecutor = widget.workflowExecutors[index];

                      if(!widget.editable) {
                        return InputForm().renderDetailField(
                          title: workflowExecutor.node!.name ?? "",
                          content: workflowExecutor.executor != null ? "${workflowExecutor.executor!.code} ${workflowExecutor.executor!.name}" : "",
                        );
                      }

                      var controller = TextEditingController();
                      if(workflowExecutor.executor != null) {
                        controller.text = "${workflowExecutor.executor!.code} ${workflowExecutor.executor!.name}";
                      }
                      controllers.add(controller);

                      return InputForm().renderCustomField(
                        fieldName: workflowExecutor.node!.name ?? "",
                        controller: controllers[index],
                        validator: Validation.validateField,
                        onTap: () {
                          Map<String, dynamic> parameters = HashMap();
                          parameters["recordRule"] = 0;
                          
                          List<int> ids = [];
                          for (var element in workflowExecutor.node!.nodeOwners) { 
                            ids.add(element.ownerId);
                          }

                          String key = "";
                          if(workflowExecutor.node!.nodeOwnerType == NodeOwnerType.EMPLOYEE) {
                            key = "id";
                          }
                          else if(workflowExecutor.node!.nodeOwnerType == NodeOwnerType.ATTRIBUTE) {
                            key = "attribute";
                          }
                          else if(workflowExecutor.node!.nodeOwnerType == NodeOwnerType.ATTRIBUTE_ORGANIZATION_OF_APPLICANT) {
                            key = "attributeDept";
                          }
                          parameters[key] = ids;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmployeePicker(
                                paramaters: parameters,
                                employee: workflowExecutor.executor,
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              workflowExecutor.executor = value;
                              controllers[index].text = "${workflowExecutor.executor!.code} ${workflowExecutor.executor!.name}";
                            });
                          });
                        }
                      );
                    },
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 100,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 15.0,
                  ),
                  child: _approvalHistory.isNotEmpty 
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _approvalHistory.length,
                        itemBuilder: (BuildContext bc, int index){
                          WorkflowDetail approvalHistory = _approvalHistory[index];
                          return timelineRow(
                            title: "${approvalHistory.workflowStatus.toString().tr()} ${approvalHistory.executor != null ? "${"By".tr()} ${approvalHistory.executor!.name}" : ""}",
                            subTitle: DateProvider.convertDateStrFormat(approvalHistory.executedDate, "yyyy-MM-dd HH:mm:ss", "dd MMM yyyy HH:mm:ss"),
                            comment: approvalHistory.remark ?? "",
                            indicatorColor: approvalHistory.workflowStatus == WorkflowStatus.APPROVED
                                            ? Config.DEFAULT_COLOR
                                            : approvalHistory.workflowStatus == WorkflowStatus.REJECTED || approvalHistory.workflowStatus == WorkflowStatus.CANCELLED
                                              ? Colors.red
                                              : Colors.grey,
                            isLast: index + 1 == _approvalHistory.length,
                          );
                        },
                      )
                    : Center(
                      child: Text(
                        "No Data Found".tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget timelineRow({
    required String title, 
    required String subTitle, 
    String? comment,
    bool isLast = false,
    Color indicatorColor= Colors.grey,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            !isLast
            ? Container(
                width: 2,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.rectangle,
                ),
              )
            : Container(),
          ],
        ),
        const SizedBox(width: 15.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                )
              ),
              const SizedBox(height: 3.0),
              Text(
                subTitle,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                comment ?? "",
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}