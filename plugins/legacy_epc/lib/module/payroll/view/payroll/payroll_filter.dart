import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/module/payroll/model/document_type.dart';
import 'package:flutter/material.dart';
import 'package:epeoplecare/view/shared/input_form.dart';

class PayrollFilter extends StatefulWidget {
  final String? year;
  final String? month;
  final DocumentType? documentType;
  const PayrollFilter({Key? key, this.year, this.month, this.documentType}):super(key: key);

  @override
  State<StatefulWidget> createState() => _PayrollFilterState();
}

class _PayrollFilterState extends State<PayrollFilter> {
  
  final _yearContoller = TextEditingController();
  final _monthContoller = TextEditingController();
  DocumentType? _valDocumentType;
  final List<Dropdown> _documentTypes = [
    Dropdown(value: null, label: "All".tr()),
    Dropdown(value: DocumentType.SALARY_SLIP, label: DocumentType.SALARY_SLIP.toString().tr()),
    Dropdown(value: DocumentType.BUKTI_POTONG_1721A1, label: DocumentType.BUKTI_POTONG_1721A1.toString().tr()),
  ];

  @override
  void initState() {
    super.initState();
    if(widget.year != null) {
      _yearContoller.text = widget.year ?? "";
    }
    if(widget.month != null) {
      _monthContoller.text = widget.month ?? "";
    }
    _valDocumentType = widget.documentType;
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
            InputForm().renderDropdownField(
              fieldName: "Document Type".tr(),
              listItem: _documentTypes,
              value: _valDocumentType,
              onChanged: (value) {
                setState(() {
                  _valDocumentType = value as DocumentType?;
                });
              },
            ),
            InputForm().renderTextField(
              controller: _yearContoller,
              fieldName: "Year".tr(),
              textInputType: TextInputType.number,
            ),
            InputForm().renderTextField(
              controller: _monthContoller,
              fieldName: "Month".tr(),
              textInputType: TextInputType.number,
            ),
            buildButtonApply(),
          ],
        ),
      ),
    );
  }

  Container buildButtonApply() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      width: mediaQuery.size.width,
      height: 40.0,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(
            context,
            {
              "year": _yearContoller.text,
              "month": _monthContoller.text,
              "documentType": _valDocumentType,
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
              _yearContoller.text = "";
              _monthContoller.text = "";
              _valDocumentType = null;
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