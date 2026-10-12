import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement_detail.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class CASettlementApplicationDetailPage extends StatefulWidget {

  final CASettlementDetail? caSettlementDetail;
  const CASettlementApplicationDetailPage({Key? key, this.caSettlementDetail}):super(key: key);

  @override
  State<StatefulWidget> createState() => _CASettlementApplicationDetailPageState();
}

class _CASettlementApplicationDetailPageState extends State<CASettlementApplicationDetailPage> {
  
  final form = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if(widget.caSettlementDetail != null) {
      _amountController.text = widget.caSettlementDetail!.amount.toString();
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
          "Settlement Application".tr(),
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
              InputForm().renderDetailField(
                title: "Name".tr(),
                content: widget.caSettlementDetail!.caRequestDetail!.name,
              ),
              InputForm().renderDetailField(
                title: "Description".tr(),
                content: widget.caSettlementDetail!.caRequestDetail!.description,
              ),
              InputForm().renderDetailField(
                title: "Amount".tr(),
                content: NumberProvider.decimalFormatDouble(widget.caSettlementDetail!.caRequestDetail!.amount),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Settlement Amount".tr(),
                  controller: _amountController,
                  validator: Validation.validateField,
                  textInputType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.caSettlementDetail != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      CASettlementDetail detail = CASettlementDetail(
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.id : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.creator : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.creationTime : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.updater : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.updateTime : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.version : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.customValues : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.medias : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.caSettlement : null,
                        widget.caSettlementDetail != null ? widget.caSettlementDetail!.caRequestDetail : null,
                        "",
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