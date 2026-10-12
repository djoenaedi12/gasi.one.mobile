import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_value_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction_detail.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class OvertimeDetailOvertimePage extends StatefulWidget {
  final OvertimeTransactionDetail? overtimeTransactionDetail;
  const OvertimeDetailOvertimePage({Key? key, this.overtimeTransactionDetail}): super(key: key);

  @override
  State<StatefulWidget> createState() => _OvertimeDetailOvertimePageState();
}

class _OvertimeDetailOvertimePageState extends State<OvertimeDetailOvertimePage> {

  List<CustomValue> _customValues = [];
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  final CustomValuesRepository _customValueRepository = Repository().getCustomValueRepository();
  
  @override
  void initState() {
    super.initState();
    _getCustomField(widget.overtimeTransactionDetail!.id!).then((value) {
      setState(() {
      _customValues = value;
      });
    });
  }

  Future<List<CustomValue>> _getCustomField(int refId) async {
    List<CustomField> customFields = await _customFieldRepository.listByType("OvertimeTransactionDetail");
    List<int> customFieldIds = [];
    for (CustomField customField in customFields) {
      customFieldIds.add(customField.id!);
    }

    List<CustomValue> customValuesTmp = await _customValueRepository.listByTypeAndRefId("OvertimeTransactionDetail", refId, customFieldIds);
    
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
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            customField, 
            customField.type, 
            null, 
            null,
          );

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
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Application Form Detail".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            InputForm().renderDetailField(
              title: "Date From".tr(),
              content: DateProvider.convertDateStrFormat(widget.overtimeTransactionDetail!.startDate, "yyyy-MM-dd HH:mm:ss", "EEEE, dd MMMM yyyy HH:mm"),
            ),
            InputForm().renderDetailField(
              title: "Date To".tr(),
              content: DateProvider.convertDateStrFormat(widget.overtimeTransactionDetail!.endDate, "yyyy-MM-dd HH:mm:ss", "EEEE, dd MMMM yyyy HH:mm"),
            ),
            InputForm().renderDetailField(
              title: "Duration".tr(),
              content: "${widget.overtimeTransactionDetail!.duration} ${"Hours".tr()}",
            ),
            InputForm().renderDetailField(
              title: "Break Duration".tr(),
              content: "${widget.overtimeTransactionDetail!.breakDuration} ${"Hours".tr()}",
            ),
            InputForm().renderDetailField(
              title: "Total Duration".tr(),
              content: "${widget.overtimeTransactionDetail!.duration - widget.overtimeTransactionDetail!.breakDuration!} ${"Hours".tr()}",
            ),
            CustomValuesPage(
              customValues: _customValues,
              viewMode: true,
            ),
          ],
        ),
      ),
    );
  }
}
