import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class MessageUnsafePage extends StatefulWidget {
  MessageUnsafePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessageUnsafePageState();
}

class _MessageUnsafePageState extends State<MessageUnsafePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,          
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_outlined,
                          color: Colors.yellow[800],
                          size: 65.0,
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            "Device Does Not Meet Security Standard".tr(), 
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold
                            )
                          )
                        ),
                      ],
                    ),
                    Text("\n${"As part of our latest security update, GASI e-PeopleCare can only run on devices that meet these requirements".tr()}:"),
                    Text("1. ${"Not rooted/jailbroken/emulator".tr()}"),
                    Text("2. ${"Developer mode disabled".tr()}"),
                    Text("3. ${"Installed in internal storage".tr()}"),
                    Text("\n${"Your device does not meet these requirements".tr()}."),
                    Text("\n${"Please".tr()}:"),
                    Text("1. ${"Use another device if rooted/jailbroken/emulator".tr()}"),
                    Text("2. ${"Disable developer mode if active".tr()}"),
                    Text("3. ${"Reinstall in internal storage if installed on SD card".tr()}"),
                    Text("\n${"Or contact Administrator if needed".tr()}."),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: InputForm().renderButton(
                text: "Exit".tr(),
                onPressed: () {
                  exit(0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}