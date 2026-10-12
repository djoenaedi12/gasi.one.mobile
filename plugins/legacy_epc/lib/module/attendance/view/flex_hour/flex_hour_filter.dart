import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/company/shift.dart';
import 'package:epeoplecare/view/shared/employee_picker.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/shift_picker.dart';
import 'package:flutter/material.dart';

class FlexHourFilter extends StatefulWidget {
  final Employee? employee;
  final Shift? shift;
  const FlexHourFilter({Key? key, this.shift, this.employee}): super(key: key);

  @override
  State<StatefulWidget> createState() => _FlexHourFilterState();
}

class _FlexHourFilterState extends State<FlexHourFilter> {
  Employee? _employee;
  Shift? _shift;
  final _employeeController = TextEditingController();
  final _shiftController = TextEditingController();

  @override
  void initState() {
    _employee = widget.employee;
    _shift = widget.shift;
    if(_employee != null) {
      _employeeController.text = "${_employee!.code} ${_employee!.name}";
    }
    if(_shift != null) {
      _shiftController.text = _shift!.name;
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
            Visibility(
              visible: true,
              child: Column(
                children: [
                  const SizedBox(height: 25.0),
                  InputForm().renderCustomField(
                    fieldName: "Employee".tr(),
                    controller: _employeeController,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeePicker(
                            employee: _employee,
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
                ],
              )
            ),
            const SizedBox(height: 25.0),
            InputForm().renderCustomField(
              fieldName: "Shift".tr(),
              controller: _shiftController,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShiftPicker(
                      shift: _shift,
                    )
                  ),
                ).then((value) {
                  if(value == null) return;

                  setState(() {
                    _shift = value;
                    _shiftController.text = _shift!.name;
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

  SizedBox buildButtonApply() {
    var mediaQuery = MediaQuery.of(context);
    return SizedBox(
      width: mediaQuery.size.width,
      height: 40.0,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(
            context,
            {
              'shift': _shift,
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
              _employee = null;
              _shift = null;
              _employeeController.text = "";
              _shiftController.text = "";
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