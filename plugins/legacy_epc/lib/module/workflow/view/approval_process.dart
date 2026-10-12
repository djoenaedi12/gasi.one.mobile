// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/workflow_detail_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class ApprovalProcess extends StatefulWidget {
  final bool isApplicant;
  final WorkflowStatus? workflowStatus;
  final Workflow? workflow;
  final bool isPullBack;
  const ApprovalProcess({Key? key, this.isApplicant= true, this.workflowStatus, this.workflow, this.isPullBack= false}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ApprovalProcessState();
}

class _ApprovalProcessState extends State<ApprovalProcess> {

  final _remarkController = TextEditingController();
  final form = GlobalKey<FormState>();

  List<Dropdown> _statuses = [];
  List<Dropdown> workflowDetails = [];
  WorkflowStatus? _status;
  int? _workflowDetail;
  final WorkflowDetailRepository _workflowDetailRepository = Repository().getWorkflowDetailRepository();

  @override
  void initState() {
    super.initState();
    if(widget.isPullBack) {
      _statuses = [
          Dropdown(
            value: WorkflowStatus.PULLBACKED,
            label: "Pull Back".tr(),
          ),
        ];
        _status = WorkflowStatus.PULLBACKED;
    } else {
      if(widget.isApplicant) {
        _statuses = [
          Dropdown(
            value: WorkflowStatus.SUBMITTED,
            label: "Submit".tr(),
          ),
          Dropdown(
            value: WorkflowStatus.DRAFTED,
            label: "Draft".tr(),
          ),
        ];

        if(widget.workflowStatus != null) {
          _statuses.add(
            Dropdown(
              value: WorkflowStatus.CANCELLED,
              label: "Cancel".tr(),
            )
          );
        }

        _status = WorkflowStatus.SUBMITTED;
      } else if(widget.workflowStatus == WorkflowStatus.APPROVED) {
        _statuses = [
          Dropdown(
            value: WorkflowStatus.REVOKED,
            label: "Revoke".tr(),
          ),
        ];
        _status = WorkflowStatus.REVOKED;
      } else {
        _statuses = [
          Dropdown(
            value: WorkflowStatus.APPROVED,
            label: "Approve".tr(),
          ),
          Dropdown(
            value: WorkflowStatus.REJECTED,
            label: "Reject".tr(),
          ),
          Dropdown(
            value: WorkflowStatus.SENDBACKED,
            label: "Send Back".tr(),
          ),
        ];
        _status = WorkflowStatus.APPROVED;
      }
    }

    if(widget.workflow != null) {
      _workflowDetailRepository.listSendBack(workflowId: widget.workflow!.id ?? 0).then((value) {
        for (WorkflowDetail item in value) {
          setState(() {
            workflowDetails.add(Dropdown(
              value: item.id,
              label: "${item.executor!.code} - ${item.executor!.name}"
            ));
          });  
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Form(
        key: form,
        child: Wrap(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.grey[200],
              height: 45.0,
              width: mediaQuery.size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Process".tr(),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Close".tr(),
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderDropdownField(
                fieldName: "Status".tr(),
                listItem: _statuses,
                value: _status,
                validator: (val) {
                  if(val == null) {
                    return "This field is required".tr();
                  }
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    _status = val as WorkflowStatus?;
                  });
                }
              ),
            ),
            Visibility(
              visible: _status == WorkflowStatus.SENDBACKED,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDropdownField(
                  fieldName: "Send Back".tr(),
                  listItem: workflowDetails,
                  value: _workflowDetail,
                  validator: (val) {
                    if(_status == WorkflowStatus.SENDBACKED && val == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _workflowDetail = val as int?;
                    });
                  }
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderTextField(
                controller: _remarkController,
                maxLength: 255,
                fieldName: "Remark".tr(),
                // mandatory remark workflow status revoked, rejected, sent back, pullbacked
                validator: (val) {
                  if (widget.workflow != null && 
                      widget.workflow!.route!.requiredRemarks.contains(_status) &&
                      (val == null || val.trim() == "")) {
                      return "This field is required".tr();
                  }
                  return null;
                }
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0, 
                vertical: 10.0,
              ),
              child: InputForm().renderButton(
                text: "Process".tr(),
                onPressed: () async {
                  if(form.currentState!.validate()) {
                    WorkflowDetail? workflowDetail = await _workflowDetailRepository.findById(id: _workflowDetail);
                    Map<String, dynamic> result = HashMap();
                    result.putIfAbsent("workflowStatus", () => _status);
                    result.putIfAbsent("remark", () => _remarkController.text);
                    result.putIfAbsent("workflowDetail", () => workflowDetail);
                    Navigator.of(context).pop(result);
                  }
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}