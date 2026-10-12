import 'dart:collection';
import 'dart:convert';
import 'dart:core';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/task/model/task.dart';
import 'package:epeoplecare/module/task/model/task_activity.dart';
import 'package:epeoplecare/module/task/model/task_notes.dart';
import 'package:epeoplecare/module/task/model/task_watcher.dart';
import 'package:epeoplecare/module/task/repository/task_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TaskDetailPage extends StatefulWidget {
  final String title;
  final Task? taskRequest;
  final int index;
  const TaskDetailPage({Key? key, this.title = "", this.taskRequest, this.index = 0}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final form = GlobalKey<FormState>();
  final TaskRepository taskRepository = Repository().getTaskRepository();
  List<Task> _relateds = [];
  Task? _parent;

  @override
  void initState() {
    super.initState();
    getTaskRelateds();
    getTaskParent();
  }

  getTaskRelateds() {
    Map<String, dynamic> parameters = HashMap();
    parameters["id"] = widget.taskRequest?.id;
    taskRepository.getListRelated(parameters).then((value) async {
      if (value.isEmpty) return;

      setState(() {
        _relateds = value;
      });
    });
  }

  getTaskParent() {
    if (widget.taskRequest?.parentId != null) {
      taskRepository.findById(id: widget.taskRequest?.parentId).then((value) async {
        if (value == null) return;

        setState(() {
          _parent = value;
        });
      });
    }
  }

  Widget getDataChange(String jsonString) {
    var data = jsonDecode(jsonString);
    if (data == null) return Column();
    Map<String, dynamic> oldData = data["old"] ?? HashMap();
    Map<String, dynamic> newData = data["new"] ?? HashMap();
    Iterable<String> keyList = newData.keys;
    List<Widget> result = [];

    if (getDataAction(jsonString) == "Updated") {
      for (String key in keyList) {
        String oldValue = oldData[key] != null ? oldData[key].toString() : "";
        String newValue = newData[key] != null ? newData[key].toString() : "";
        if (oldValue != newValue) {
          String value = "<b>${StringProvider.capitalEachWord(key)}</b>";
          value += oldValue == "" ? " set to <i>$newValue</i>" : " changed from <i>$oldValue</i> to <i>$newValue</i>";
          // result[key] = value;
          result.add(Html(data: value));
        }
      }
    }

    return Column(children: result);
  }

  getDataAction(String jsonString) {
    Map<String, dynamic> data = jsonDecode(jsonString);
    return data["action"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(color: Config.DEFAULT_ACCENT_COLOR),
        title: Text(widget.title, style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR)),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: form,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InputForm().renderDetailField(title: "Project".tr(), content: widget.taskRequest!.project!.name),
                    InputForm().renderDetailField(title: "Subject".tr(), content: widget.taskRequest!.subject),
                    InputForm().renderDetailField(title: "Description".tr(), content: widget.taskRequest!.description),
                    InputForm().renderDetailField(title: "Due Date".tr(), content: widget.taskRequest!.dueDate),
                    InputForm().renderDetailField(title: "Status".tr(), content: widget.taskRequest!.status!.name),
                    InputForm().renderDetailField(title: "Assignee".tr(), content: widget.taskRequest!.assignee != null ? widget.taskRequest!.assignee!.name : ""),
                    InputForm().renderDetailField(title: "Priority".tr(), content: EnumProvider.convertToString(widget.taskRequest!.priority)),
                    InputForm().renderDetailField(title: "Progress".tr(), content: NumberProvider.decimalFormatDouble(widget.taskRequest!.progress)),
                    InputForm().renderDetailField(title: "Parent".tr(), content: _parent != null ? _parent!.subject : ""),
                    MultipleAttachmentPage(medias: widget.taskRequest!.medias),
                    CustomValuesPage(customValues: widget.taskRequest!.customValues, viewMode: true),
                    DetailPage(
                      isEditable: false,
                      itemList: _relateds,
                      title: "Related".tr(),
                      renderTitle: (val, index) {
                        Task tr = val;
                        return Row(
                          children: [
                            Text("Related to ".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(tr.id.toString()),
                            const Text(" - "),
                            Text(tr.subject),
                          ],
                        );
                      },
                      renderBody: (data, index) {
                        Task detail = data;
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Text("${"Status".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(detail.status!.name)]),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text("${"Assignee".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(detail.assignee != null ? detail.assignee!.name : ""),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    DetailPage(
                      isEditable: false,
                      itemList: widget.taskRequest!.watchers,
                      title: "Watcher".tr(),
                      renderTitle: (val, index) {
                        TaskWatcher tw = val;
                        return Row(children: [Text(tw.employee != null ? tw.employee!.code : ""), const Text(" - "), Text(tw.employee != null ? tw.employee!.name : "")]);
                      },
                      renderBody: (data, index) {
                        TaskWatcher detail = data;
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("${"Code".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(detail.employee != null ? detail.employee!.code : ""),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text("${"Name".tr()}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(detail.employee != null ? detail.employee!.name : ""),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    DetailPage(
                      isEditable: false,
                      itemList: widget.taskRequest!.activities,
                      title: "Activity".tr(),
                      renderTitle: (val, index) {
                        TaskActivity ta = val;
                        return Row(
                          children: [
                            Text("${getDataAction(ta.activity ?? "")} by ".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(ta.updater!),
                            const Text(" on "),
                            Text(DateProvider.convertDateStrFormat(ta.updateTime, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss")),
                          ],
                        );
                      },
                      renderBody: (data, index) {
                        TaskActivity detail = data;
                        return Container(padding: const EdgeInsets.all(10.0), child: getDataChange(detail.activity ?? ""));
                      },
                    ),
                    DetailPage(
                      isEditable: false,
                      itemList: widget.taskRequest!.notes,
                      title: "Notes".tr(),
                      renderTitle: (val, index) {
                        TaskNotes tn = val;
                        return Row(
                          children: [
                            Text("Updated by ".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(tn.updater!),
                            const Text(" on "),
                            Text(DateProvider.convertDateStrFormat(tn.updateTime, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss")),
                          ],
                        );
                      },
                      renderBody: (data, index) {
                        TaskNotes detail = data;
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [Text(detail.notes)]),
                            ],
                          ),
                        );
                      },
                    ),
                    // MultipleAttachmentPage(
                    //   medias: widget.benefitRequest!.medias,
                    //   attachment: widget.benefitRequest!.attachment,
                    // ),
                    // CustomValuesPage(
                    //   customValues: widget.benefitRequest!.customValues,
                    //   viewMode: true,
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
