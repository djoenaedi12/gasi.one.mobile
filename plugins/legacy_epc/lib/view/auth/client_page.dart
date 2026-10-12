// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/appearance_setting_provider.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/encoder_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/appearance_setting_repository.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/client_repository.dart';
import 'package:epeoplecare/repository/file_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/format_txt.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});
  
  @override
  State<StatefulWidget> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {

  final _clientController = TextEditingController();
  final form = GlobalKey<FormState>();
  final ClientRepository _clientRepository = Repository().getClientRepository();
  final AuthRepository _authRepository = Repository().getAuthRepository();
  final FileRepository _fileRepository = Repository().getFileRepository();
  final AppearanceSettingRepository _appearanceRepository = Repository().getAppearanceSettingRepository();

  @override
  void initState() {
    super.initState();
    _authRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    _clientRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    // _authRepository.setBaseUrl("http://10.10.11.64:38000/ewf-base");
    // _clientRepository.setBaseUrl("http://10.10.11.64:38000/ewf-base");
    AlertProvider.showUpdateAvailableDialog();
    AlertProvider.showUnSafeDeviceDialog();
    AlertProvider.showSignatureDialog();
  }

  void _validateCLient() {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _authRepository.login(EncoderProvider().decode(Config.baseClientId), EncoderProvider().decode(Config.baseClientSecret), EncoderProvider().decode(Config.baseUsername), EncoderProvider().decode(Config.basePassword), "").then((val) {
        if(val != null) {
          _clientRepository.getClient(_clientController.text, val.accessToken).then((value) async {
            Config.client = value;
            if(Config.client != null) {
              Config.client!.url = ClientProvider().safeBase64Decode(Config.client!.url);
              Config.client!.clientId = ClientProvider().safeBase64Decode(Config.client!.clientId);
              Config.client!.clientSecret = ClientProvider().safeBase64Decode(Config.client!.clientSecret);
            }
            
            _appearanceRepository.setBaseUrl(Config.client!.url);
            _appearanceRepository.getAppearanceSetting().then((value) async {
              if(value != null) {
                Config.appearanceSetting = value;
                await AppearanceSettingProvider().setAppearanceSetting(value);

                if(value.appLogo != null) {
                  _fileRepository.setBaseUrl(Config.client!.url);
                  var bytes = await _appearanceRepository.getAppearanceSettingImage("appLogo");
                  if(bytes != null) {
                    String dir = await StorageProvider().getExternalStorage();
                    File file = File('$dir/logo.jpg');
                    await file.writeAsBytes(bytes);
                  }
                }
              }

              if(Config.appearanceSetting != null && Config.appearanceSetting!.colorMobile != null && Config.appearanceSetting!.colorMobile != "") {
                Config.DEFAULT_COLOR = StringProvider.hexToColor(Config.appearanceSetting!.colorMobile ?? "") ?? Config.DEFAULT_COLOR;
              } else {
                Config.DEFAULT_COLOR = const Color(0xFF1E88E5);
              }
              if(Config.appearanceSetting != null && Config.appearanceSetting!.accentColorMobile != null && Config.appearanceSetting!.accentColorMobile != "") {
                Config.DEFAULT_ACCENT_COLOR = StringProvider.hexToColor(Config.appearanceSetting!.accentColorMobile ?? "") ?? Config.DEFAULT_COLOR;
              } else {
                Config.DEFAULT_ACCENT_COLOR = Colors.white;
              }

              ClientProvider().setClient(Config.client, "").then((value) async {
                await Repository().initData();
                EasyLoading.dismiss();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              });
            }).catchError((onError){
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(
                    icon: const Icon(Icons.error, size: 100, color: Colors.red),
                    title: "Error".tr(),
                    subTitle: onError.toString(),
                  ),
                ),
              );
            });
          }).catchError((onError){
            EasyLoading.dismiss();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagePage(
                  icon: const Icon(Icons.error, size: 100, color: Colors.red),
                  title: "Error".tr(),
                  subTitle: onError.toString(),
                ),
              ),
            );
          });     
        }       
      }).catchError((onError){
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: onError.toString(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          height: mediaQuery.size.height,
          padding: const EdgeInsets.all(
            10.0,
          ),
          color: Colors.white,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 30.0, 
                      top: 5.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/img/logo.png",
                              width: 40.0,
                              height: 40.0,
                            ),
                            const Text(
                              "e-PeopleCare",
                              style: TextStyle(
                                color: Color(0xFF015281),
                                fontWeight: FontWeight.w500,
                                fontSize: 20.0,
                              ),
                            ),
                          ],
                        ),
                        InputForm().renderToogleField(
                          option1: "en",
                          option2: "id",
                          value: Config.language,
                          onTap: () {
                            if(Config.language == "en") {
                              Config.language = "id";
                            } else {
                              Config.language = "en";
                            }

                            EasyLoading.show(status: "Please Wait".tr());
                            PreferencesProvider().setSharedPref("language", Config.language).then((value) {
                              context.setLocale(Locale(Config.language));
                              Repository().setLanguange(Config.language);
                              EasyLoading.dismiss();
                            });
                          }
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      "Welcome to e-PeopleCare".tr(),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.white,
                    elevation: 1.5,
                    child: Container(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InputForm().renderTextField(
                            fieldName: "Please Sign In With Your Company Code".tr(),
                            controller: _clientController,
                            validator: Validation.validateField,
                            inputFormatters: [
                              UpperCaseTxt()
                            ]
                          ),
                          InputForm().renderButton(
                            text: "Sign In".tr(),
                            onPressed: () {
                              _validateCLient();
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
