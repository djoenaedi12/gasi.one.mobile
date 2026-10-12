import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BooleanPickerPage extends StatefulWidget {
  final bool? value;
  final String? title;
  const BooleanPickerPage({Key? key, this.value, this.title}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _BooleanPickerPageState();
}

class _BooleanPickerPageState extends State<BooleanPickerPage> {

  bool _value = false;

  @override
  void initState() {
    _value = widget.value ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: RadioGroup<bool>(
            groupValue: _value,
            onChanged: (bool? value) {
              if (value == null) return;

              setState(() {
                _value = value;
              });
            },
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 15.0,
                    left: 15.0,
                    right: 15.0,
                    bottom: 10.0,
                  ),
                  child: Text(
                    widget.title ?? "",
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Divider(color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 10.0,
                  ),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() {
                        _value = true;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Yes".tr()),
                        const Radio<bool>(
                          visualDensity: VisualDensity.compact,
                          value: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 10.0,
                  ),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() {
                        _value = false;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("No".tr()),
                        const Radio<bool>(
                          visualDensity: VisualDensity.compact,
                          value: false,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10.0,
                    top: 10.0,
                    right: 5.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel".tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, _value);
                        },
                        child: Text(
                          "Ok".tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}