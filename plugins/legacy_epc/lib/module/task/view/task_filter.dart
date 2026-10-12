import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/task/model/task_priority.dart';
import 'package:epeoplecare/module/task/model/task_status.dart';
import 'package:epeoplecare/view/shared/employee_picker.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class TaskFilter extends StatefulWidget {
  final Employee? assignee;
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? subject;
  const TaskFilter({Key? key, this.assignee, this.status, this.priority, this.subject}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskFilterState();
}

class _TaskFilterState extends State<TaskFilter> {
  Employee? _assignee;
  TaskStatus? _status;
  String? _subject;
  final _assigneeController = TextEditingController();
  final _statusController = TextEditingController();
  final _subjectController = TextEditingController();

  @override
  void initState() {
    _assignee = widget.assignee;
    _status = widget.status;
    _subject = widget.subject;
    if (_assignee != null) {
      _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
    }
    if (_status != null) {
      _statusController.text = _status!.name;
    }
    if (_subject != null) {
      _subjectController.text = _subject!;
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
            InputForm().renderCustomField(
              fieldName: "Assignee".tr(),
              controller: _assigneeController,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeePicker(employee: _assignee, paramaters: const {"recordRule": "0"}))).then((
                  value,
                ) {
                  if (value == null) return;

                  setState(() {
                    _assignee = value;
                    _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
                  });
                });
              },
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
          Navigator.pop(context, {'assignee': _assignee});
        },
        child: Text('Apply'.tr(), style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR)),
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
              child: const Icon(Icons.close, size: 20.0),
            ),
            const SizedBox(width: 5.0),
            Text("Filter".tr(), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500)),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _assignee = null;
              _assigneeController.text = "";
            });
          },
          child: Text("Reset".tr(), style: const TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
