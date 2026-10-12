import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class WhereaboutReason extends StatefulWidget {
  const WhereaboutReason({super.key});

  @override
  State<StatefulWidget> createState() => _WhereaboutReasonState();
}

class _WhereaboutReasonState extends State<WhereaboutReason> {

  final _reasonController = TextEditingController();
  final form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Form(
        key: form,
        child: Wrap(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.grey[200],
              height: 45.0,
              width: mediaQuery.size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Process".tr(),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Close".tr(),
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10.0,
              ),
              child: Text(
                "Please fill the reason for your lateness".tr(),
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderTextField(
                controller: _reasonController,
                fieldName: "Reason".tr(),
                maxLines: 3,
                maxLength: 100,
                textInputType: TextInputType.multiline,
                validator: Validation.validateField,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0, 
                vertical: 10.0,
              ),
              child: InputForm().renderButton(
                text: "Process".tr(),
                onPressed: () {
                  if(form.currentState!.validate()) {
                    Map<String, dynamic> result = HashMap();
                    result.putIfAbsent("reason", () => _reasonController.text);
                    Navigator.of(context).pop(result);
                  }
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}