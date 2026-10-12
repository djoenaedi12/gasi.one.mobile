import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_category.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_policy.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_category_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/model_picker.dart';
import 'package:flutter/material.dart';

class CAApplicationDetailPage extends StatefulWidget {

  final CARequestDetail? caRequestDetail;
  final CAPolicy? caPolicy;
  const CAApplicationDetailPage({Key? key, this.caRequestDetail, this.caPolicy}): super(key: key);

  @override
  State<StatefulWidget> createState() => _CAApplicationDetailPageState();
}

class _CAApplicationDetailPageState extends State<CAApplicationDetailPage> {
  
  final form = GlobalKey<FormState>();
  CACategory? _caCategory;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caCategoryController = TextEditingController();
  final _amountController = TextEditingController();
  final CACategoryRepository _caCategoryRepository = Repository().getCACategoryRepository();

  @override
  void initState() {
    super.initState();
    if(widget.caRequestDetail != null) {
      _nameController.text = widget.caRequestDetail!.name;
      _descriptionController.text = widget.caRequestDetail!.description ?? "";
      _caCategory = widget.caRequestDetail!.caCategory;
      _caCategoryController.text = _caCategory!.name;
      _amountController.text = widget.caRequestDetail!.amount.toString();
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
          "Application Form Detail".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
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
                  fieldName: "Name".tr(),
                  controller: _nameController,
                  validator: Validation.validateField
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Description".tr(),
                  controller: _descriptionController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderCustomField(
                  fieldName: "Category".tr(),
                  controller: _caCategoryController,
                  onTap: () {
                    Map<String, dynamic> parameters = HashMap();
                    parameters["caPolicy.id"] = widget.caPolicy != null ? widget.caPolicy!.id : 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModelPicker(
                          data: _caCategory,
                          repository: _caCategoryRepository,
                          title: "Category".tr(),
                          paramaters: parameters,
                        )
                      ),
                    ).then((value) {
                      if(value == null) return;

                      setState(() {
                        _caCategory = value;
                        _caCategoryController.text = _caCategory!.name;
                      });
                    });
                  },
                  validator: Validation.validateField,
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Amount".tr(),
                  controller: _amountController,
                  validator: Validation.validateField,
                  textInputType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.caRequestDetail != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      CARequestDetail detail = CARequestDetail(
                        widget.caRequestDetail != null ? widget.caRequestDetail!.id : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.creator : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.creationTime : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.updater : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.updateTime : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.version : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.customValues : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.medias : null,
                        widget.caRequestDetail != null ? widget.caRequestDetail!.caRequest : null,
                        _caCategory,
                        _nameController.text,
                        _descriptionController.text,
                        double.parse(_amountController.text),
                      );
                      
                      Navigator.of(context).pop(detail);
                    }
                  }
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