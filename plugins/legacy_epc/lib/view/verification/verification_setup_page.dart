import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/local_auth_provider.dart';
import 'package:epeoplecare/view/verification/verification_create_page.dart';
import 'package:flutter/material.dart';

class VerificationSetupPage extends StatefulWidget {
  final bool isTwoFactorAuthentication;
  const VerificationSetupPage({Key? key, required this.isTwoFactorAuthentication}): super(key: key);
  
  @override
  State<StatefulWidget> createState() => _VerificationSetupPageState();
}

class _VerificationSetupPageState extends State<VerificationSetupPage> {

  bool _isBiometricAvailable = false;
  bool _isFaceAvailable = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Icon(
                Icons.lock_outline,
                color: Config.DEFAULT_COLOR,
                size: 100.0,
              ),
            ),
            const SizedBox(height: 5.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Setup Verification Code".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "${"You have not set up the verification code".tr()}. ${"A verification code protect your data and is used to unlock application".tr()}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Setup Now".tr(),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationCreatePage(
                              verificationType: VerificationType.PIN,
                              isTwoFactorAuthentication: widget.isTwoFactorAuthentication,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("PIN".tr()),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _isBiometricAvailable,
                      child: Column(
                        children: [
                          Divider(color: Colors.grey.shade300),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VerificationCreatePage(
                                    verificationType: VerificationType.FINGERPRINT,
                                    isTwoFactorAuthentication: widget.isTwoFactorAuthentication,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_isFaceAvailable ? "Fingerprint / Face ID".tr() : "Fingerprint".tr()),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Visibility(
                    //   visible: _isFaceAvailable,
                    //   child: Column(
                    //     children: [
                    //       Divider(color: Colors.grey.shade300),
                    //       InkWell(
                    //         splashColor: Colors.transparent,
                    //         highlightColor: Colors.transparent,
                    //         onTap: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //               builder: (context) => VerificationCreatePage(
                    //                 verificationType: VerificationType.FACE,
                    //                 isTwoFactorAuthentication: widget.isTwoFactorAuthentication,
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text("Face".tr()),
                    //             const Icon(
                    //               Icons.chevron_right,
                    //               color: Colors.grey,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }
}