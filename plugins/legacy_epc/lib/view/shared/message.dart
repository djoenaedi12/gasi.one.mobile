import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  Widget icon;
  String title;
  String subTitle;
  final void Function()? onPressed;

  MessagePage({Key? key, required this.icon, required this.title, required this.subTitle, this.onPressed}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    if(widget.subTitle.startsWith("TimeoutException")) {
      widget.title = "Connection Timed Out".tr();
      widget.subTitle = "The server is taking too long to respond. Please check your internet connection and try again.".tr();
      widget.icon = Icon(
        Icons.signal_wifi_connected_no_internet_4,
        color: Config.DEFAULT_COLOR,
        size: 100.0,
      );
    } else if(widget.subTitle.startsWith("ClientException")) {
      widget.title = "Can't connect to the server".tr();
      widget.subTitle = "The app failed to connect to the server. Please check your internet connection and try again.".tr();
      widget.icon = Icon(
        Icons.wifi_off,
        color: Config.DEFAULT_COLOR,
        size: 100.0,
      );
    } else if(widget.subTitle.contains("429: ")) {
      // Handle untuk error 429
      // Ambil pesan dari properties dengan key TooManyRequestMessage
      widget.title = "";
      widget.subTitle = "TooManyRequestMessage".tr();
    }

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.subTitle.startsWith("Exception: 200") ? 
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.yellow[800],
                      size: 100.0,
                    ) : widget.icon,
                    const SizedBox(height: 20.0),
                    Text(
                      widget.subTitle.startsWith("Exception: 200") ? "" : widget.title,
                      style: const TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      widget.subTitle.startsWith("Exception: 200") ? widget.subTitle.replaceAll("Exception: 200", "") : widget.subTitle.replaceAll("Exception: ", ""),
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: InputForm().renderButton(
                // Set label button
                // Jika 429 caption nya Try Again / Coba Lagi
                // Selain itu OK
                text: widget.subTitle == "TooManyRequestMessage".tr() ? "Try Again".tr() : "OK".tr(),
                onPressed: () {
                  if(widget.onPressed == null) {
                    Navigator.pop(context);
                  } else {
                    widget.onPressed;
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