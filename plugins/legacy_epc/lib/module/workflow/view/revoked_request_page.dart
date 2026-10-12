import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/repository/workflow_detail_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class RevokedRequestPage extends StatefulWidget {
  final Workflow? workflow;
  const RevokedRequestPage({Key? key, this.workflow}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _RevokedRequestPageState();
}

class _RevokedRequestPageState extends State<RevokedRequestPage> {

  final form = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  List<Dropdown> employees = [];
  Employee? _employee;
  final WorkflowDetailRepository _workflowDetailRepository = Repository().getWorkflowDetailRepository();
  
  @override
  void initState() {
    super.initState();
    if(widget.workflow != null) {
      _workflowDetailRepository.listApproval(workflowId: widget.workflow!.id ?? 0).then((value) {
        for (Employee item in value) {
          setState(() {
            employees.add(Dropdown(
              value: item,
              label: "${item.code} - ${item.name}"
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
                    "Revoked Request".tr(),
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
                fieldName: "Employee".tr(),
                listItem: employees,
                value: _employee,
                onChanged: (val) {
                  setState(() {
                    _employee = val as Employee?;
                  });
                }
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderTextField(
                controller: _remarkController,
                maxLength: 255,
                fieldName: "Remark".tr(),
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
                    Map<String, dynamic> result = HashMap();
                    result.putIfAbsent("remark", () => _remarkController.text);
                    result.putIfAbsent("employee", () => _employee);
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