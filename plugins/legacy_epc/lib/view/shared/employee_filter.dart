import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/material.dart';

class EmployeeFilter extends StatefulWidget {

  final bool isActive;
  const EmployeeFilter({Key? key, this.isActive = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmployeeFilterState();
}

class _EmployeeFilterState extends State<EmployeeFilter> {
  bool _isActive = true;
  @override
  void initState() {
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