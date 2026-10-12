import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AnnouncementPage extends StatefulWidget {

  final Announcement announcement;
  const AnnouncementPage({Key? key, required this.announcement}): super(key: key);

  @override
  State<StatefulWidget> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          widget.announcement.subject,
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Html(
            data: widget.announcement.content,
          )
        ),
      ),
    );
  }
}
