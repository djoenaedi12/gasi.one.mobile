// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/task/model/project.dart';
import 'package:epeoplecare/module/task/model/task.dart';
import 'package:epeoplecare/module/task/model/task_related.dart';
import 'package:epeoplecare/module/task/model/task_notes.dart';
import 'package:epeoplecare/module/task/model/task_status.dart';
import 'package:epeoplecare/module/task/model/task_watcher.dart';
import 'package:epeoplecare/module/task/model/task_activity.dart';
import 'package:epeoplecare/module/task/model/task_priority.dart';
import 'package:epeoplecare/module/task/repository/task_status_repository.dart';
import 'package:epeoplecare/module/task/repository/task_repository.dart';
import 'package:epeoplecare/module/task/repository/project_repository.dart';
import 'package:epeoplecare/module/task/view/task_notes_page.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';

import 'package:epeoplecare/view/shared/model_picker.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/task_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TaskApplicationPage extends StatefulWidget {
  final Task? taskRequest;
  const TaskApplicationPage({Key? key, this.taskRequest}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _TaskApplicationPageState();
}

class _TaskApplicationPageState extends State<TaskApplicationPage> {
  final form = GlobalKey<FormState>();
  List<Dropdown> projects = [];
  List<Dropdown> statusList = [];
  List<Dropdown> parents = [];
  List<Dropdown> priorityList = [];
  final _subjectController = TextEditingController();
  final _remarkController = TextEditingController();
  final _progressController = TextEditingController();
  final _dueDateController = TextEditingController();
  TaskPriority? _priority;
  final TaskRepository taskRepository = Repository().getTaskRepository();
  final ProjectRepository projectRepository = Repository().getProjectRepository();
  final TaskStatusRepository statusRepository = Repository().getTaskStatusRepository();
  final EmployeeRepository employeeRepository = Repository().getEmployeeRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();

  List<CustomValue> _customValues = [];
  List<Media> _medias = [];
  List<TaskRelated> _relateds = [];
  List<TaskNotes> _notes = [];
  List<TaskWatcher> _watchers = [];
  List<TaskActivity> _activities = [];

  List<Task> _relatedList = [];

  final _assigneeController = TextEditingController();
  Employee? _assignee;
  final _parentController = TextEditingController();
  Task? _parent;
  final _projectController = TextEditingController();
  Project? _project;
  final _statusController = TextEditingController();
  TaskStatus? _status;

  @override
  void initState() {
    super.initState();
    _initData();
    getTaskRelateds();
    getTaskParent();
  }

  _initData() {
    priorityList = [
      Dropdown(value: TaskPriority.LOW, label: "Low".tr()),
      Dropdown(value: TaskPriority.NORMAL, label: "Normal".tr()),
      Dropdown(value: TaskPriority.HIGH, label: "High".tr()),
    ];
    _priority = TaskPriority.NORMAL;
    if (widget.taskRequest != null) {
      _project = widget.taskRequest!.project;
      if (_project != null) {
        _projectController.text = _project!.name;
      }
      _status = widget.taskRequest!.status;
      if (_status != null) {
        _statusController.text = _status!.name;
      }
      _subjectController.text = widget.taskRequest!.subject;
      _remarkController.text = widget.taskRequest!.description ?? "";
      _dueDateController.text = widget.taskRequest!.dueDate ?? "";
      _progressController.text = NumberProvider.decimalFormatDouble(widget.taskRequest!.progress!);
      _priority = widget.taskRequest!.priority;
      _assignee = widget.taskRequest!.assignee;
      if (_assignee != null) {
        _assigneeController.text = _assignee!.name;
      }
      _parent = widget.taskRequest!.parent;
      if (_parent != null) {
        _parentController.text = "${_parent!.id} ${_parent!.subject}";
      }
      _medias = widget.taskRequest!.medias;
      _customValues = widget.taskRequest!.customValues;
      _relateds = widget.taskRequest!.relateds;
      _watchers = widget.taskRequest!.watchers;
      _notes = widget.taskRequest!.notes;
      _activities = widget.taskRequest!.activities;
    } else {
      _initCustomField();
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("Task").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(null, null, null, null, null, null, null, null, item, item.type, null, null);
          _customValues.add(customValue);
        });
      }
    });
  }

  getTaskRelateds() {
    Map<String, dynamic> parameters = HashMap();
    parameters["id"] = widget.taskRequest?.id;
    taskRepository.getListRelated(parameters).then((value) async {
      if (value.isEmpty) return;

      setState(() {
        _relatedList = value;
      });
    });
  }

  getTaskParent() {
    if (widget.taskRequest?.parentId != null) {
      taskRepository.findById(id: widget.taskRequest?.parentId).then((value) async {
        if (value == null) return;

        setState(() {
          _parent = value;
          _parentController.text = value.subject;
        });
      });
    }
  }

  _submitForm() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      // Map<String, dynamic> parameters = HashMap();
      // parameters["remark"] = remark;

      Task taskRequest = Task(
        widget.taskRequest?.id,
        widget.taskRequest?.creator,
        widget.taskRequest?.creationTime,
        widget.taskRequest?.updater,
        widget.taskRequest?.updateTime,
        widget.taskRequest?.version,
        _customValues,
        _medias,
        _project,
        _subjectController.text,
        _remarkController.text,
        _dueDateController.text,
        _status,
        _assignee,
        _priority,
        double.parse(_progressController.text),
        _parent,
        null,
        _relateds,
        _watchers,
        _notes,
        _activities,
      );

      if (widget.taskRequest != null) {
        taskRepository
            .update(id: widget.taskRequest!.id!, entity: taskRequest)
            .then((value) {
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          MessagePage(icon: const Icon(Icons.check_circle, size: 100, color: Colors.green), title: "Success".tr(), subTitle: "Data has been saved".tr()),
                ),
              ).then((value) {
                Navigator.pop(context, true);
              });
            })
            .catchError((onError) {
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(icon: const Icon(Icons.error, size: 100, color: Colors.red), title: "Error".tr(), subTitle: onError.toString()),
                ),
              );
            });
      } else {
        taskRepository
            .save(entity: taskRequest)
            .then((value) {
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          MessagePage(icon: const Icon(Icons.check_circle, size: 100, color: Colors.green), title: "Success".tr(), subTitle: "Data has been saved".tr()),
                ),
              ).then((value) {
                Navigator.pop(context, true);
              });
            })
            .catchError((onError) {
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(icon: const Icon(Icons.error, size: 100, color: Colors.red), title: "Error".tr(), subTitle: onError.toString()),
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
        iconTheme: IconThemeData(color: Config.DEFAULT_ACCENT_COLOR),
        title: Text("Application Form".tr(), style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR)),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        fieldName: "Project".tr(),
                        controller: _projectController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ModelPicker(data: _project, repository: projectRepository, title: "Project".tr())),
                          ).then((value) {
                            if (value == null) return;

                            setState(() {
                              _project = value;
                              _projectController.text = _project!.name;
                            });
                          });
                        },
                        validator: Validation.validateField,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(fieldName: "Subject".tr(), controller: _subjectController, validator: Validation.validateField),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Description".tr(),
                        controller: _remarkController,
                        maxLines: 5,
                        maxLength: 5000,
                        textInputType: TextInputType.multiline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        fieldName: "Status".tr(),
                        controller: _statusController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ModelPicker(data: _status, repository: statusRepository, title: "Status".tr())),
                          ).then((value) {
                            if (value == null) return;

                            setState(() {
                              _status = value;
                              _statusController.text = _status!.name;
                            });
                          });
                        },
                        validator: Validation.validateField,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDropdownField(
                        fieldName: "Priority".tr(),
                        value: _priority,
                        listItem: priorityList,
                        onChanged: (val) {
                          setState(() {
                            _priority = val as TaskPriority;
                          });
                        },
                        validator: (val) {
                          if (val == null) {
                            return "This field is required".tr();
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        controller: _assigneeController,
                        fieldName: "Assignee".tr(),
                        validator: Validation.validateField,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ModelPicker(data: _assignee, repository: employeeRepository, title: "Assignee".tr())),
                          ).then((value) {
                            if (value == null) return;

                            setState(() {
                              _assignee = value;
                              _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
                            });
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateField(
                        fieldName: "Due Date".tr(),
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2101),
                        controller: _dueDateController,
                        onChanged: (value) {
                          if (value == null) return;

                          _dueDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Progress".tr(),
                        controller: _progressController,
                        validator: Validation.validateField,
                        textInputType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        fieldName: "Parent".tr(),
                        controller: _parentController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TaskPicker(data: _parent, repository: taskRepository, title: "Parent".tr())),
                          ).then((value) {
                            if (value == null) return;

                            setState(() {
                              _parent = value;
                              _parentController.text = _parent!.subject;
                            });
                          });
                        },
                      ),
                    ),
                    MultipleAttachmentPage(medias: _medias, editable: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomValuesPage(customValues: _customValues, editMode: widget.taskRequest != null ? true : false),
                    ),
                    DetailPage(
                      itemList: _relatedList,
                      title: "Relateds".tr(),
                      onDelete: (index) {
                        setState(() {
                          _relatedList.removeAt(index);
                          _relateds.removeAt(index);
                        });
                      },
                      onEdit: (val, index) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskPicker(data: null, repository: taskRepository, title: "Related".tr()))).then((
                          value,
                        ) {
                          if (value == null) return;

                          TaskRelated detail = TaskRelated(null, null, null, null, null, null, null, null, null, value);

                          setState(() {
                            _relateds[index] = TaskRelated.fromJson(detail)!;
                            _relatedList[index] = value;
                          });
                        });
                      },
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskPicker(data: null, repository: taskRepository, title: "Related".tr()))).then((
                          value,
                        ) {
                          if (value == null) return;

                          TaskRelated detail = TaskRelated(null, null, null, null, null, null, null, null, null, value);

                          if (!_relateds.contains(detail)) {
                            setState(() {
                              _relateds.add(detail);
                              _relatedList.add(value);
                            });
                          }
                        });
                      },
                      renderTitle: (val, index) {
                        Task detail = val;
                        return Text("${detail.id} - ${detail.subject}");
                      },
                    ),
                    DetailPage(
                      itemList: _watchers,
                      title: "Watcher".tr(),
                      onDelete: (index) {
                        setState(() {
                          _watchers.removeAt(index);
                        });
                      },
                      onEdit: (val, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ModelPicker(data: null, repository: employeeRepository, title: "Watcher".tr())),
                        ).then((value) {
                          if (value == null) return;

                          TaskWatcher detail = TaskWatcher(null, null, null, null, null, null, null, null, null, value);

                          setState(() {
                            _watchers[index] = detail;
                          });
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ModelPicker(data: null, repository: employeeRepository, title: "Watcher".tr())),
                        ).then((value) {
                          if (value == null) return;

                          TaskWatcher detail = TaskWatcher(null, null, null, null, null, null, null, null, null, value);
                          if (!_watchers.contains(detail)) {
                            setState(() {
                              _watchers.add(detail);
                            });
                          }
                        });
                      },
                      renderTitle: (val, index) {
                        TaskWatcher detail = val;
                        return Text("${detail.employee?.code} - ${detail.employee?.name}");
                      },
                    ),
                    DetailPage(
                      itemList: _notes,
                      title: "Notes".tr(),
                      onDelete: (index) {
                        setState(() {
                          _notes.removeAt(index);
                        });
                      },
                      onEdit: (val, index) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskNotesPage(taskNotes: val))).then((value) {
                          if (value == null) return;

                          setState(() {
                            _notes[index] = value;
                          });
                        });
                      },
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskNotesPage())).then((value) {
                          if (value == null) return;

                          setState(() {
                            _notes.add(value);
                          });
                        });
                      },
                      renderTitle: (val, index) {
                        TaskNotes detail = val;
                        return Text(detail.notes);
                      },
                      renderBody: (data, index) {
                        TaskNotes detail = data;
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("${"Update On".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(DateProvider.convertDateStrFormat(detail.updateTime, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(children: [Text("${"Update by".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(detail.updater ?? "")]),
                              const SizedBox(height: 5.0),
                              Row(children: [Text("${"Note".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(detail.notes)]),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Submit".tr(),
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (form.currentState!.validate()) {
                    _submitForm();
                  }
                },
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
