import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/view/shared/employee_picker.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class WorkflowFilter extends StatefulWidget {
  final Employee? employee;
  final String? requestNo;
  final bool isApplicant;
  const WorkflowFilter({Key? key, this.employee, this.requestNo, this.isApplicant = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkflowFilterState();
}

class _WorkflowFilterState extends State<WorkflowFilter> {
  
  final _requestNoContoller = TextEditingController();
  final _employeeController = TextEditingController();
  Employee? _employee;

  @override
  void initState() {
    _employee = widget.employee;
    _requestNoContoller.text = widget.requestNo ?? "";
    if(_employee != null) {
      _employeeController.text = "${_employee!.code} ${_employee!.name}";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        color: Colors.white,
        child: Wrap(
          children: <Widget>[
            buildHeader(),
            const SizedBox(height: 25.0),
            InputForm().renderTextField(
              controller: _requestNoContoller,
              fieldName: "Request No".tr(),
            ),
            widget.isApplicant 
            ? const SizedBox()
            : InputForm().renderCustomField(
                fieldName: "Employee".tr(),
                controller: _employeeController,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeePicker(
                        employee: _employee,
                        paramaters: const {"recordRule": "0"},
                      )
                    ),
                  ).then((value) {
                    if(value == null) return;

                    setState(() {
                      _employee = value;
                      _employeeController.text = "${_employee!.code} ${_employee!.name}";
                    });
                  });
                }
              ),
            buildButtonApply(),
          ],
        ),
      ),
    );
  }

  Container buildButtonApply() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      width: mediaQuery.size.width,
      height: 40.0,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(
            context,
            {
              "requestNo": _requestNoContoller.text == "" ? null : _requestNoContoller.text,
              'employee': _employee,
            },
          );
        },
        child: Text(
          'Apply'.tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                size: 20.0,
              ),
            ),
            const SizedBox(
              width: 5.0,
            ),
            Text(
              "Filter".tr(),
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _requestNoContoller.text = "";
              _employeeController.text = "";
              _employee = null;
            });
          },
          child: Text(
            "Reset".tr(),
            style: const TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}