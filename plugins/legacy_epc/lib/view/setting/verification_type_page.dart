// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/local_auth_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/view/verification/verification_create_page.dart';
import 'package:flutter/material.dart';

class VerificationTypePage extends StatefulWidget {
  final VerificationType verificationType;
  const VerificationTypePage({Key? key, required this.verificationType}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _VerificationTypePageState();
}

class _VerificationTypePageState extends State<VerificationTypePage> {
  
  late VerificationType _verificationType;
  bool _isBiometricAvailable = false;
  bool _isFaceAvailable = false;

  @override
  void initState() {
    super.initState();
    _verificationType = widget.verificationType;
    LocalAuthProvider().isBiometricAvailable().then((value) {
      setState(() {
        _isBiometricAvailable = value;
      });
    });

    LocalAuthProvider().isFaceAvailable().then((value) {
      setState(() {
        _isFaceAvailable = value;
      });
    });
  }

  setSelectedRadio(VerificationType val) {
    setState(() {
      _verificationType = val;
    });
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
          child: RadioGroup<VerificationType>(
            groupValue: _verificationType,
            onChanged: (VerificationType? value) {
              if (value == null) return;
              setSelectedRadio(value);
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
                    "Verification Type".tr(),
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
                      setSelectedRadio(VerificationType.PIN);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("PIN".tr()),
                        const Radio<VerificationType>(
                          visualDensity: VisualDensity.compact,
                          value: VerificationType.PIN,
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _isBiometricAvailable || _isFaceAvailable,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 10.0,
                    ),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        setSelectedRadio(
                          VerificationType.FINGERPRINT,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isFaceAvailable
                                ? "Fingerprint / Face ID".tr()
                                : "Fingerprint".tr(),
                          ),
                          const Radio<VerificationType>(
                            visualDensity: VisualDensity.compact,
                            value: VerificationType.FINGERPRINT,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 10.0,
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
                        onPressed: () async {
                          String pin = await PreferencesProvider()
                                  .getSharedPref("pin") ??
                              "";

                          if ((_verificationType ==
                                      VerificationType.PIN &&
                                  pin.isEmpty) ||
                              _verificationType ==
                                  VerificationType.FINGERPRINT ||
                              _verificationType ==
                                  VerificationType.FACE) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VerificationCreatePage(
                                  verificationType:
                                      _verificationType,
                                  isTwoFactorAuthentication: false,
                                  isRedirect: false,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                PreferencesProvider()
                                    .setSharedPref(
                                  "verificationType",
                                  EnumProvider.convertToString(
                                        _verificationType,
                                      ) ??
                                      "",
                                )
                                    .then((value) {
                                  Navigator.pop(
                                    context,
                                    _verificationType,
                                  );
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            });
                          } else {
                            PreferencesProvider()
                                .setSharedPref(
                              "verificationType",
                              EnumProvider.convertToString(
                                    _verificationType,
                                  ) ??
                                  "",
                            )
                                .then((value) {
                              Navigator.pop(
                                context,
                                _verificationType,
                              );
                            });
                          }
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