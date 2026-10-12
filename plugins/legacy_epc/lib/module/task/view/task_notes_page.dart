import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_value_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/task/model/task_notes.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class TaskNotesPage extends StatefulWidget {
  final TaskNotes? taskNotes;
  const TaskNotesPage({Key? key, this.taskNotes}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskNotesPageState();
}

class _TaskNotesPageState extends State<TaskNotesPage> {
  final form = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  final CustomValuesRepository _customValueRepository = Repository().getCustomValueRepository();
  List<CustomValue> _customValues = [];

  @override
  void initState() {
    super.initState();
    if (widget.taskNotes != null) {
      _notesController.text = widget.taskNotes!.notes;
      if (widget.taskNotes!.id != null) {
        _getCustomField(widget.taskNotes!.id!).then((value) {
          setState(() {
            _customValues = value;
          });
        });
      } else {
        _customValues = widget.taskNotes!.customValues;
      }
    } else {
      _initCustomField();
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("TaskNotes").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(null, null, null, null, null, null, null, null, item, item.type, null, null);

          _customValues.add(customValue);
        });
      }
    });
  }

  Future<List<CustomValue>> _getCustomField(int refId) async {
    List<CustomField> customFields = await _customFieldRepository.listByType("TaskNotes");
    List<int> customFieldIds = [];
    for (CustomField customField in customFields) {
      customFieldIds.add(customField.id!);
    }

    List<CustomValue> customValuesTmp = await _customValueRepository.listByTypeAndRefId("TaskNotes", refId, customFieldIds);

    bool isExist = false;
    for (CustomField customField in customFields) {
      isExist = false;
      for (CustomValue customValue in customValuesTmp) {
        if (customValue.customField!.id == customField.id) {
          isExist = true;
          break;
        }
      }

      if (!isExist) {
        setState(() {
          CustomValue customValue = CustomValue(null, null, null, null, null, null, null, null, customField, customField.type, null, null);

          _customValues.add(customValue);
        });
      }
    }

    return _customValues;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(color: Config.DEFAULT_ACCENT_COLOR),
        title: Text("Notes".tr(), style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Notes".tr(),
                  controller: _notesController,
                  maxLines: 5,
                  maxLength: 5000,
                  textInputType: TextInputType.multiline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomValuesPage(customValues: _customValues, editMode: widget.taskNotes != null ? true : false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.taskNotes != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      TaskNotes detail = TaskNotes(
                        widget.taskNotes?.id,
                        widget.taskNotes?.creator,
                        widget.taskNotes?.creationTime,
                        widget.taskNotes?.updater,
                        widget.taskNotes?.updateTime,
                        widget.taskNotes?.version,
                        widget.taskNotes?.customValues,
                        widget.taskNotes?.medias,
                        null,
                        _notesController.text,
                      );

                      Navigator.of(context).pop(detail);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
