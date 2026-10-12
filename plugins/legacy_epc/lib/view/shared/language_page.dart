import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/language.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<StatefulWidget> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {

  final List<Language> _languages = [
    Language("en", "English"),
    Language("id", "Bahasa Indonesia"),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _changeLanguage(Language language) {
    EasyLoading.show(status: "Please Wait".tr());
    PreferencesProvider().setSharedPref("language", language.code).then((value) {
      setState(() {
        Config.language = language.code;
      });
      context.setLocale(Locale(Config.language));
      Repository().setLanguange(Config.language);
      EasyLoading.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Language".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: SizedBox(
        height: mediaQuery.size.height,
        child: ListView.separated(
          itemCount: _languages.length,
          separatorBuilder: (BuildContext bc, int index){
            return Divider(color: Colors.grey.shade300);
          },
          itemBuilder: (BuildContext bc, int index){
            Language language = _languages[index];
            return ListTile(
              title: Text(language.name),
              trailing: Icon(
                Icons.check,
                color: Config.language == language.code ? Config.DEFAULT_COLOR : Colors.white,
              ),
              onTap: () {
                _changeLanguage(language);
              },
            );
          },
        ),
      ),
    );
  }
}