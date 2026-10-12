import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/module/customfield/model/custom_field_enumeration.dart';
import 'package:epeoplecare/module/customfield/model/custom_field_type.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/cupertino.dart';

class CustomValuesPage extends StatefulWidget {
  final List<CustomValue> customValues;
  final bool editMode;
  final bool viewMode;
  const CustomValuesPage({Key? key, this.customValues = const [], this.editMode= false, this.viewMode= false}) : super(key: key);
  
  @override
  State<StatefulWidget>  createState() => _CustomValuesPageState();
}

class _CustomValuesPageState extends State<CustomValuesPage> {

  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.customValues.length,
      itemBuilder: (BuildContext bc, int index) {
        CustomValue customValue = widget.customValues[index];
        var controller = TextEditingController();
        controller.text = customValue.value ?? "";
        _controllers.add(controller);

        if(customValue.customField!.customFieldType == CustomFieldType.STRING) {
          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value ?? "",
            );
          }

          return InputForm().renderTextField(
            controller: _controllers[index],
            enabled: widget.editMode ? customValue.customField!.editable : true,
            fieldName: customValue.customField!.name,
            maxLength: customValue.customField!.maxLength,
            validator: (value) {
              if ((value == null || value.isEmpty) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            onChanged: (val) {
              setState(() {
                customValue.value = val;
              });
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.INT || customValue.customField!.customFieldType == CustomFieldType.DOUBLE) {
          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value ?? "",
            );
          }

          return InputForm().renderTextField(
            controller: _controllers[index],
            enabled: widget.editMode ? customValue.customField!.editable : true,
            textInputType: TextInputType.number,
            fieldName: customValue.customField!.name,
            maxLength: customValue.customField!.maxLength,
            validator: (value) {
              if ((value == null || value.isEmpty) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            onChanged: (val) {
              setState(() {
                customValue.value = val;
              });
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.DATE) {
          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value != null ? DateProvider.convertDateStrFormat(customValue.value, "yyyy-MM-dd", "dd MMMM yyyy") : "",
            );
          }
          
          return InputForm().renderDateField(
            controller: _controllers[index],
            enabled: widget.editMode ? customValue.customField!.editable : true,
            initialDate: DateTime.now(),
            firstDate: DateTime(1990),
            lastDate: DateTime(2050),
            fieldName: customValue.customField!.name,
            validator: (value) {
              if ((value == null || value.isEmpty) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            onChanged: (value) {
              if(value == null) return;

              _controllers[index].text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
              setState(() {
                customValue.value = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
              });
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.ENUMERATION) {
          List<Dropdown> dropdowns = [];
          Map<String, String> enumerations = HashMap();
          dropdowns.add(Dropdown(value: null, label: "${"Select".tr()} ${customValue.customField!.name}"));
          for (CustomFieldEnumeration customFieldEnumeration in customValue.customField?.customFieldEnumerations ?? []) {
            dropdowns.add(Dropdown(value: customFieldEnumeration.enumeration.toString(), label: customFieldEnumeration.name));
            enumerations.putIfAbsent(customFieldEnumeration.enumeration.toString(), () => customFieldEnumeration.name);
          }

          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value != null && enumerations.containsKey(customValue.value) ? enumerations[customValue.value] : "",
            );
          }

          return InputForm().renderDropdownField(
            fieldName: customValue.customField!.name,
            enabled: widget.editMode ? customValue.customField!.editable : true,
            value: customValue.value,
            listItem: dropdowns,
            onChanged: (val) {
              setState(() {
                customValue.value = val.toString();
              });
            },
            validator: (value) {
              if((value == null) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            disabledHint: (val) {
              if(enumerations.containsKey(customValue.value)) {
                return Text("${enumerations[customValue.value]}");
              }

              return const Text("");
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.LIST) {
          List<Dropdown> dropdowns = [];
          List<String> possibleValues = customValue.customField!.possibleValues!.split("\r\n");
          dropdowns.add(Dropdown(value: null, label: "${"Select".tr()} ${customValue.customField!.name}"));
          for (String possibleValue in possibleValues) {
            dropdowns.add(Dropdown(value: possibleValue, label: possibleValue));
          }

          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value ?? "",
            );
          }

          return InputForm().renderDropdownField(
            fieldName: customValue.customField!.name,
            enabled: widget.editMode ? customValue.customField!.editable : true,
            value: customValue.value,
            listItem: dropdowns,
            onChanged: (val) {
              setState(() {
                customValue.value = val.toString();
              });
            },
            validator: (value) {
              if((value == null) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            disabledHint: (val) {
              return Text("${customValue.value}");
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.BOOL) {
          List<Dropdown> dropdowns = [];
          dropdowns.add(Dropdown(value: "1", label: "Yes".tr()));
          dropdowns.add(Dropdown(value: "0", label: "No".tr()));

          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value != null && customValue.value == "1" ? "Yes".tr() : "No".tr(),
            );
          }

          return InputForm().renderDropdownField(
            fieldName: customValue.customField!.name,
            enabled: widget.editMode ? customValue.customField!.editable : true,
            value: customValue.value,
            listItem: dropdowns,
            onChanged: (val) {
              setState(() {
                customValue.value = val.toString();
              });
            },
            validator: (value) {
              if((value == null) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            disabledHint: (val) {
              return Text(customValue.value != null && customValue.value == "1" ? "Yes".tr() : "No".tr());
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.TEXT_AREA) {
          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value ?? "",
            );
          }

          return InputForm().renderTextField(
            controller: _controllers[index],
            enabled: widget.editMode ? customValue.customField!.editable : true,
            fieldName: customValue.customField!.name,
            maxLength: customValue.customField!.maxLength,
            maxLines: 5,
            textInputType: TextInputType.multiline,
            validator: (value) {
              if ((value == null || value.isEmpty) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            onChanged: (val) {
              setState(() {
                customValue.value = val;
              });
            }
          );
        } else if(customValue.customField!.customFieldType == CustomFieldType.TIME) {
          if(widget.viewMode) {
            return InputForm().renderDetailField(
              title: customValue.customField!.name,
              content: customValue.value != null ? customValue.value : "",
            );
          }
          
          return InputForm().renderTimeField(
            controller: _controllers[index],
            enabled: widget.editMode ? customValue.customField!.editable : true,
            fieldName: customValue.customField!.name,
            time: DateProvider.convertStr2TimeOfDay(customValue.value),
            validator: (value) {
              if ((value == null || value.isEmpty) && customValue.customField!.required == true) {
                return "This field is required".tr();
              }

              return null;
            },
            onChanged: (value) {
              if(value == null) return;

              _controllers[index].text = DateProvider.convertTimeOfDay2Str(value);
              setState(() {
                customValue.value = DateProvider.convertTimeOfDay2Str(value);
              });
            }
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}