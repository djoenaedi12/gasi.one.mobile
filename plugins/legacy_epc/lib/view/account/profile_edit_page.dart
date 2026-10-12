import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/company/gender.dart';
import 'package:epeoplecare/model/company/marital.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ProfileEditPage extends StatefulWidget {
  final Employee? employee;
  const ProfileEditPage({Key? key, this.employee}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {

  final form = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  Employee? _employee;
  final List<Dropdown> _gender = [
    Dropdown(value: Gender.MALE, label: Gender.MALE.toString().tr()),
    Dropdown(value: Gender.FEMALE, label: Gender.FEMALE.toString().tr()),
  ];
  Gender? _valGender;
  final List<Dropdown> _marital = [
    Dropdown(value: Marital.SINGLE, label: Marital.SINGLE.toString().tr()),
    Dropdown(value: Marital.MARRIED, label: Marital.MARRIED.toString().tr()),
  ];
  Marital? _valMarital;
  final EmployeeRepository _employeeRepository = Repository().getEmployeeRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];

  @override
  void initState() {
    super.initState();
    if(widget.employee != null) {
      _employee = widget.employee;
      _codeController.text = _employee!.code;
      _nameController.text = _employee!.name;
      _birthDateController.text = _employee!.birthDate!;
      _emailController.text = _employee!.email ?? "";
      _phoneNumberController.text = _employee!.phoneNumber ?? "";
      _valGender = _employee!.gender;
      _valMarital = _employee!.marital;
      _customValues = widget.employee!.customValues;
    } else {
      _initCustomField();
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("Employee").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            item, 
            item.type, 
            null, 
            null,
          );

          _customValues.add(customValue);
        });
      }
    });
  }

  void _submitForm() async {
    if (form.currentState!.validate()) {
      _employee!.name = _nameController.text;
      _employee!.birthDate = _birthDateController.text;
      _employee!.email = _emailController.text;
      _employee!.phoneNumber = _phoneNumberController.text;
      _employee!.gender = _valGender;
      _employee!.marital = _valMarital;
      _employee!.customValues = _customValues;

      EasyLoading.show(status: "Please Wait".tr());
      _employeeRepository.update(id: _employee!.id!, entity: _employee!).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Data has been saved".tr(),
            ),
          ),
        ).then((value) {
          Navigator.pop(context, true);
        });
      }).catchError((onError){
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: onError.toString(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Edit Profile".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputForm().renderTextField(
                  fieldName: "Employee ID".tr(),
                  controller: _codeController,
                  enabled: false,
                ),
                InputForm().renderTextField(
                  fieldName: "Employee Name".tr(),
                  controller: _nameController,
                  validator: Validation.validateField,
                  enabled: false,
                ),
                InputForm().renderDateField(
                  fieldName: "DOB".tr(),
                  controller: _birthDateController,
                  validator: Validation.validateField,
                  initialDate: _birthDateController.text.isNotEmpty
                          ? DateFormat("yyyy-MM-dd").parse(_birthDateController.text)
                          : DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2050),
                  onChanged: (value) {
                    if (value == null) return;

                      _birthDateController.text = DateFormat("yyyy-MM-dd").format(value);
                  },
                  enabled: false,
                ),
                InputForm().renderTextField(
                  fieldName: "Email".tr(),
                  controller: _emailController,
                  enabled: false,
                ),
                InputForm().renderTextField(
                  fieldName: "Phone Number".tr(),
                  controller: _phoneNumberController,
                  enabled: false,
                ),
                InputForm().renderDropdownField(
                  fieldName: "Gender.".tr(),
                  listItem: _gender,
                  value: _valGender,
                  validator: (val) {
                    if(val == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _valGender = value as Gender?;
                    });
                  },
                  enabled: false,
                  disabledHint: (value) {
                    return Text(value.toString().tr());
                  }
                ),
                InputForm().renderDropdownField(
                  fieldName: "Marital Status".tr(),
                  listItem: _marital,
                  value: _valMarital,
                  validator: (val) {
                    if(val == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _valMarital = value as Marital?;
                    });
                  },
                  enabled: false,
                  disabledHint: (value) {
                    return Text(value.toString().tr());
                  }
                ),
                CustomValuesPage(
                  customValues: widget.employee!.customValues,
                  editMode: widget.employee != null ? true : false,
                ),
                InputForm().renderButton(
                  text: "Save".tr(),
                  onPressed: () {
                    _submitForm();
                  }                  
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
