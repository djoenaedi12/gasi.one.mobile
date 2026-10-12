import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class SubordinateFilter extends StatefulWidget {

  final int level;
  final bool isActive;
  const SubordinateFilter({Key? key, this.level = 1, this.isActive = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubordinateFilterState();
}

class _SubordinateFilterState extends State<SubordinateFilter> {
  int _level = 1;
  final List<Dropdown> _levels = [
    const Dropdown(value: 1, label: "1"),
    const Dropdown(value: 2, label: "2"),
    const Dropdown(value: 3, label: "3"),
    const Dropdown(value: 4, label: "4"),
    const Dropdown(value: 5, label: "5"),
  ];
  bool _isActive = true;
  @override
  void initState() {
    _level = widget.level;
    _isActive = widget.isActive;
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
            InputForm().renderDropdownField(
              fieldName: "Level".tr(),
              listItem: _levels,
              value: _level,
              onChanged: (value) {
                setState(() {
                  _level = value as int;
                });
              },
            ),
            CheckboxListTile(
              title: Text("Active Only".tr()),
              value: _isActive, 
              contentPadding: EdgeInsets.zero,
              onChanged: (bool? val) {
                setState(() {
                  _isActive = val!;
                });
              }
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
              "level": _level,
              "active": _isActive
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
              _level = 1;
              _isActive = widget.isActive;
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