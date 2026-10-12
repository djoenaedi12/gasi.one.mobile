import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/letter/model/letter_type.dart';
import 'package:epeoplecare/module/letter/view/letter_type_picker.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class LetterFilter extends StatefulWidget {

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final LetterType? letterType;
  const LetterFilter({Key? key, this.dateFrom, this.dateTo, this.letterType}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LetterFilterState();
}

class _LetterFilterState extends State<LetterFilter> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  LetterType? _letterType;
  final _letterTypeController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  @override
  void initState() {
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _letterType = widget.letterType;
    _dateFromController.text = DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd");
    _dateToController.text = DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd");
    if(_letterType != null) {
      _letterTypeController.text = _letterType!.name;
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
              fieldName: "Letter Type".tr(),
              controller: _letterTypeController,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LetterTypePicker(
                      letterType: _letterType,
                    )
                  ),
                ).then((value) {
                  if(value == null) return;

                  setState(() {
                    _letterType = value;
                    _letterTypeController.text = _letterType!.name;
                  });
                });
              }
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10.0, 
                top: 20.0,
              ),
              child: buildDate(),
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
          Navigator.pop(
            context,
            {
              'dateFrom': _dateFrom,
              'dateTo': _dateTo,
              'letterType': _letterType,
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

  Widget buildDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(
          width: MediaQuery.of(context).size.width / 2 - 30,
          height: 45.0,
          child: TextFormField(
            controller: _dateFromController,
            cursorColor: Colors.blue,
            readOnly: true,
            keyboardType: TextInputType.text,
            onTap: () async {
              DateTime initialDate = DateTime.now();
              if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
                if(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!) > 0) {
                    initialDate = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
                } else {
                  initialDate = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
                }
              } else if(_dateToController.text.isNotEmpty) {
                if(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!.compareTo(DateTime.now()) < 0) {
                    initialDate = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
                }
              } else if (_dateFromController.text.isNotEmpty) {
                initialDate = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
              }

              var result = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1990),
                lastDate: _dateToController.text.isNotEmpty
                          ? DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!
                          : DateTime(2050),
              );

              if (result == null) return;
              setState(() {
                _dateFromController.text = DateProvider.convertDate2Str(result, "yyyy-MM-dd");
                _dateFrom = result;
              });
            },
            decoration: InputDecoration(
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(0.0),
                child: Icon(
                  Icons.date_range,
                ),
              ),
              hintText: "From".tr(),
              hintStyle: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const Text("-"),
        SizedBox(
          width: MediaQuery.of(context).size.width / 2 - 30,
          height: 45.0,
          child: TextFormField(
            controller: _dateToController,
            cursorColor: Colors.blue,
            readOnly: true,
            keyboardType: TextInputType.text,
            onTap: () async {
              DateTime initialDate = DateTime.now();
              if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
                if(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!) > 0) {
                    initialDate = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
                } else {
                  initialDate = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
                }
              } else if(_dateFromController.text.isNotEmpty) {
                if(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateTime.now()) > 0) {
                    initialDate = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
                }
              } else if (_dateToController.text.isNotEmpty) {
                initialDate = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
              }
              var result = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: _dateFromController.text.isNotEmpty 
                            ? DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!
                            : DateTime(1990),
                lastDate: DateTime(2050),
              );

              if (result == null) return;
              setState(() {
                _dateToController.text = DateProvider.convertDate2Str(result, "yyyy-MM-dd");
                _dateTo = result;
              });
            },
            decoration: InputDecoration(
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(0.0),
                child: Icon(
                  Icons.date_range,
                ),
              ),
              hintText: "To".tr(),
              hintStyle: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
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
              _dateFrom = null;
              _dateTo = null;
              _letterType = null;
              _dateFromController.text = "";
              _dateToController.text = "";
              _letterTypeController.text = "";
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