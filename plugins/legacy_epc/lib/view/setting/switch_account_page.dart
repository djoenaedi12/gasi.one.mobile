// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/session.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/view/auth/client_page.dart';
import 'package:flutter/material.dart';
import 'package:epeoplecare/model/client.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchAccountPage extends StatefulWidget {
  const SwitchAccountPage({super.key});
  @override
  State<StatefulWidget> createState() => _SwitchAccountPageState();
}

class _SwitchAccountPageState extends State<SwitchAccountPage> {
  
  Future<SharedPreferences> prefInstance = SharedPreferences.getInstance();
  List<String> accounts = [];
  String currentAccount = "";
  
  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() async {
    final SharedPreferences pref = await prefInstance;
    List<String>? accountsTmp = pref.getStringList("accounts");
    if(accountsTmp != null) {
      setState(() {
        accounts = accountsTmp;
      });
    }
    setState(() {
      currentAccount = "${Config.client!.code};${Config.session!.username}";
      if(accounts.isEmpty) {
        accounts.add(currentAccount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            color: Colors.grey[100],
            height: 45.0,
            width: mediaQuery.size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Accounts".tr(),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    List<String> account = accounts[index].split(";");
                    return InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {            
                        Client? client = await ClientProvider().getClient(account[0]);
                        if(client != null) {
                          Session? session = await SessionProvider().getSession(accounts[index]);
                          if(session != null) {
                            ClientProvider().setClient(client, "");
                            SessionProvider().setSession(session, "");
                          }
                        }

                        Phoenix.rebirth(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(StringProvider.getInitials(account[1])),
                          ),
                          const SizedBox(width: 15.0),
                          Expanded(
                            child: Text("${account[0].toUpperCase()} - ${account[1]}")
                          ),
                          Icon(
                            Icons.check,
                            color: accounts[index] == currentAccount ? Config.DEFAULT_COLOR : Colors.white,
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Divider(color: Colors.grey.shade300),
                    );
                  },
                  itemCount: accounts.length
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: mediaQuery.size.width,
                  height: 40.0,
                  child: ElevatedButton(
                    onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientPage(),
                          ),
                        );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Config.DEFAULT_ACCENT_COLOR,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Add Account".tr(),
                          style: TextStyle(
                            color: Config.DEFAULT_ACCENT_COLOR,
                          ),
                        ),
                      ],
                    )
                  ),
                ),
              ]
            )
          ),
        ],
      )
    );
  }
}