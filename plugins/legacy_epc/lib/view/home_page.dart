import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/announcement.dart';
import 'package:epeoplecare/model/menu.dart';
import 'package:epeoplecare/model/menu_type.dart';
import 'package:epeoplecare/model/module.dart';
import 'package:epeoplecare/model/role.dart';
import 'package:epeoplecare/model/screen_argument.dart';
import 'package:epeoplecare/model/system_announcement.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_checkinout.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/company/announcement_repository.dart';
import 'package:epeoplecare/repository/notification_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/repository/system_announcement_repository.dart';
import 'package:epeoplecare/view/notification/notification_page.dart';
import 'package:epeoplecare/view/setting/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<String?>? imageName;
  AttendanceTransaction? attendanceTransaction;
  final AttendanceTransactionRepository _attendanceTransactionRepository = Repository().getAttendanceTransactionRepository();
  final NotificationRepository _notificationRepository = Repository().getNotificationRepository();
  final SystemAnnouncementRepository _systemAnnouncementRepository = Repository().getSystemAnnouncementRepository();
  final AnnouncementRepository _announcementRepository = Repository().getAnnouncementRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasNotificationUnread = false;
  final PanelController _pc = PanelController();
  List<Module> menuModules = [];
  SystemAnnouncement? _systemAnnouncement;
  int _current = 0;
  List<Announcement> _announcements = [];
  bool _canPop = false;

  @override
  void initState() {
    super.initState();

    _getLastAttendance();
    _getAnnouncement();
    _setImage();
    _checkHasNotificationUnread();
    _initMenuModule();
    AlertProvider.showUpdateAvailableDialog();
    AlertProvider.showUnSafeDeviceDialog();
    AlertProvider.showSignatureDialog();
    _getSystemAnnouncement();
  }

  _getSystemAnnouncement() {
    _systemAnnouncementRepository.list().then((value) async {
      List<SystemAnnouncement> systemAnnouncements = value;
      if (systemAnnouncements.isNotEmpty && await PreferencesProvider().getSharedPref("sa${systemAnnouncements[0].id}${systemAnnouncements[0].version}") != "0") {
        setState(() {
          _systemAnnouncement = systemAnnouncements[0];
        });
      }
    });
  }

  _setImage() {
    imageName = getImageFilePath();
  }

  _getLastAttendance() {
    if (Config.user!.employee == null) return;

    _attendanceTransactionRepository.getLastByEmployee(Config.user!.employee!, DateProvider.getCurrentDateMidnight()).then((value) {
      setState(() {
        attendanceTransaction = value;
      });
    });
  }

  _checkHasNotificationUnread() {
    String fcmToken = "-1";
    if(Config.fcmToken != "") {
      fcmToken = Config.fcmToken;
    }

    _notificationRepository.listByReceiverAndUnread(fcmToken).then((value) {
      setState(() {
        if (value.isNotEmpty) {
          _hasNotificationUnread = true;
        } else {
          _hasNotificationUnread = false;
        }
      });
    });
  }

  Future<String?> getImageFilePath() async {
    String path = await StorageProvider().getExternalStorage();
    String fileName = await PreferencesProvider().getSharedPref("image") ?? "";
    if (await File("$path/$fileName").exists()) {
      return "$path/$fileName";
    } else {
      return null;
    }
  }

  _checkInOut() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return  SingleChildScrollView(
          child: AttendanceCheckInOut(
            attendanceTransaction: attendanceTransaction,
            attendanceDate: attendanceTransaction != null && attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_IN
              ? DateProvider.convertStr2Date(attendanceTransaction!.attendanceDate, "yyyy-MM-dd")
              : DateTime.now(),
            isCurrentDate: true,
          )
        );
      },
    ).then((value) => _getLastAttendance());
  }

  _getAnnouncement() {
    _announcementRepository.listByEmployee().then((value) {
      _announcements.clear();
      setState(() {
        _announcements = value;
      });
    }).catchError((e) {
      setState(() {
        _announcements.clear();
      });
    });
  }

  _initMenuModule() {
    List<Module> menuModulesTmp = [];
    for (Role role in Config.user!.roles) {
      for (Menu menu in role.menus) {
        if(menu.menuType == MenuType.MOBILE && menu.child == false && menu.visible == true) {
          bool isDuplicate = false;
          String module = menu.module ?? "";
          var title = menu.title.startsWith("tr(") ? menu.title.substring(3, menu.title.length - 1).tr() : menu.title;
          for (Module md in menuModulesTmp) {
            if(md.module == module && md.title == title) {
              isDuplicate = true;
              break;
            }
          }

          if(!isDuplicate) {
            var icon = IconData(int.parse("${menu.classStr}"), fontFamily: "MaterialIcons");
            menuModulesTmp.add(Module(
              title,
              false,
              icon,
              () {
                Navigator.pushNamed(
                  context,
                  menu.url,
                  arguments: ScreenArgument(title, icon, attendanceTransaction),
                ).then((val) {
                  if(menu.url == "/module/attendance") {
                    _getLastAttendance();
                  }
                });
              },
              module,
              menu.sequence,
            ));
          }
        }
      }
    }

    for (Module module in menuModulesTmp) {
      if (Config.license != null && (module.module == "" || Config.license!.modules.contains(module.module))) {
        module.isActive = true;
      }

      if (module.isActive || (!module.isActive && Config.showDisabledMenu)) {
        menuModules.add(module);
      }
    }

    menuModules.sort((a, b) {
      String aSort = "";
      String bSort = "";
      if (a.isActive == true) {
        aSort = "0${a.sequence.toString().padLeft(5, "0")}";
      } else {
        aSort = "1${a.sequence.toString().padLeft(5, "0")}";
      }
      if (b.isActive == true) {
        bSort = "0${b.sequence.toString().padLeft(5, "0")}";
      } else {
        bSort = "1${b.sequence.toString().padLeft(5, "0")}";
      }
      return aSort.compareTo(bSort);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult:(didPop, result) {
        if(!didPop) {
          setState(() {
            _canPop = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Press back again to exit".tr()), duration: Duration(seconds: 2)));
        }

        Timer(Duration(seconds: 2), (){
          setState(() {
            _canPop = false;
          });
        });
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: buildDrawer(),
        body: SlidingUpPanel(
          minHeight: 0.0,
          controller: _pc,
          backdropEnabled: true,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18.0),
            topRight: Radius.circular(18.0),
          ),
          panelBuilder: (sc) => buildPanel(sc),
          body: Scaffold(
            backgroundColor: Colors.white,
            appBar: buildAppBar(),
            body: buildBody(),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    var mediaQuery = MediaQuery.of(context);
    return SingleChildScrollView(
      physics: const ScrollPhysics(),
      child: Stack(
        children: [
          Container(
            color: Config.DEFAULT_COLOR,
            width: mediaQuery.size.width,
            height: _systemAnnouncement != null && Config.license != null && Config.license!.modules.contains("attendance") ? 375.0 : 300,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 5.0,
              ),
              Visibility(
                visible: _systemAnnouncement != null,
                child: buildSystemAnnouncement(),
              ),
              buildImage(),
              const SizedBox(height: 20.0),
              Visibility(
                visible: Config.license != null && Config.license!.modules.contains("attendance"),
                child: buildAttendance(),
              ),
              buildMenu(),
              Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          child: Text(
                            "Announcement".tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                      ],
                    ),
                    Divider(
                      color: Colors.grey.shade300,
                      height: 2,
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _announcements.isNotEmpty,
                child: buildAnnouncement(),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSystemAnnouncement() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      margin: const EdgeInsets.only(
        left: 10.0,
        right: 10.0,
        bottom: 10.0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
      ),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFfff3cd), border: Border.all(color: Colors.orange.shade300, width: 0.5), borderRadius: BorderRadius.circular(5.0)),
        width: mediaQuery.size.width,
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _systemAnnouncement != null ? _systemAnnouncement!.subject : "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Html(
                        data: _systemAnnouncement != null ? _systemAnnouncement!.content : "",
                        style: {
                          "body": Style(
                            fontSize: FontSize(11.0),
                            margin: Margins.zero,
                          )
                        },
                        onLinkTap: (url, attributes, element) {
                          if(url != null) {
                            launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              child: GestureDetector(
                child: const Icon(Icons.close, size: 12),
                onTap: () {
                  PreferencesProvider().setSharedPref("sa${_systemAnnouncement!.id}${_systemAnnouncement!.version}", "0").then((value) {
                    setState(() {
                      _systemAnnouncement = null;
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Config.DEFAULT_COLOR,
      elevation: 0.0,
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        icon: Icon(
          Icons.menu,
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Home'.tr(),
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
            ),
          ),
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  ).then((value) => _checkHasNotificationUnread());
                },
                child: Icon(
                  Icons.notifications,
                  color: Config.DEFAULT_ACCENT_COLOR,
                ),
              ),
              Visibility(
                visible: _hasNotificationUnread,
                child: Positioned(
                  top: 2.0,
                  right: 2.0,
                  child: Container(
                    width: 9.0,
                    height: 9.0,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(
                  20.0,
                ),
                child: Text(
                  Config.appearanceSetting != null && Config.appearanceSetting!.appName != null ? Config.appearanceSetting!.appName ?? "e-PeopleCare".tr() : "e-PeopleCare".tr(),
                  style: const TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              Divider(
                height: 1.0,
                color: Colors.grey.shade300
              ),
              buildDrawerItem(),
              Divider(
                height: 1.0,
                color: Colors.grey.shade300
              ),
              ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingPage(),
                    ),
                  ).then((value) {
                    setState(() {
                      _setImage();
                    });
                  });
                },
                leading: const Icon(
                  Icons.settings,
                  color: Colors.grey,
                ),
                title: Text("Setting".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDrawerItem() {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 10.0,
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: Colors.grey,
                ),
                title: Text("Home".tr()),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: menuModules.length > 8 ? 8 : menuModules.length,
                itemBuilder: (BuildContext context, int index) {
                  Module module = menuModules[index];
                  if (index == 7 && menuModules.length > 8) {
                    return ListTile(
                      leading: const Icon(
                        Icons.list,
                        color: Colors.grey,
                      ),
                      title: Text("Other".tr()),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pc.open();
                      },
                    );
                  }

                  return ListTile(
                    leading: Icon(
                      module.icon,
                      color: module.isActive ? Colors.grey : Colors.grey,
                    ),
                    title: Row(
                      children: [
                        Text(
                          module.title,
                          style: TextStyle(
                            color: module.isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Visibility(
                          visible: !module.isActive,
                          child: const Icon(
                            Icons.lock,
                            color: Colors.red,
                          )
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!module.isActive) return;

                      Navigator.of(context).pop();
                      module.onTap();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImage() {
    return Column(
      children: [
        FutureBuilder(
          future: imageName,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(100.0),
                ),
                child: Image(
                  height: 160.0,
                  width: 160.0,
                  fit: BoxFit.cover,
                  image: FileImage(File("${snapshot.data}")),
                ),
              );
            } else {
              return ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(100.0),
                ),
                child: Container(
                  height: 160.0,
                  width: 160.0,
                  color: Colors.grey,
                  child: Center(
                    child: Text(
                      StringProvider.getInitials(Config.user!.employee != null ? Config.user!.employee!.name : ""),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 40.0,
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(
          height: 10.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "${"Welcome".tr()} ${Config.user!.employee != null ? Config.user!.employee!.name : ""}",
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget buildAttendance() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      margin: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: 10.0,
      ),
      padding: const EdgeInsets.all(10.0),
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: buildAttendanceInOut(
        isCheckOut: attendanceTransaction != null && attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_IN,
      ),
    );
  }

  Widget buildAttendanceInOut({
    bool isCheckOut = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isCheckOut ? "Check Out" : "Check in").tr(),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      (isCheckOut ? "Don't forget to check out" : "You haven't check in yet").tr(),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Visibility(
                  visible: isCheckOut,
                  child: Text(
                    "Have a good day".tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: Config.license != null && Config.license!.modules.contains("attendance") ? _checkInOut : null,
          child: (isCheckOut ?
            Icon(
              Icons.logout_outlined,
              size: 90,
              color: Config.SEMANTIC_COLOR_DANGER,
            ) :
            Icon(
              Icons.login_outlined,
              size: 90,
              color: Config.SEMANTIC_COLOR_SUCCESS,
            )
          ),
        ),
      ],
    );
  }

  Widget buildMenu() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      margin: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: 10.0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 10.0,
      ),
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: buildMenuItem(),
    );
  }

  Widget buildMenuItem() {
    var mediaQuery = MediaQuery.of(context);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: (menuModules.length / 4).ceil() > 2 ? 2 : (menuModules.length / 4).ceil(),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 7.0,
            bottom: 7.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              menuModules.length > (4 * index + 0)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 0].isActive) return;

                        menuModules[4 * index + 0].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 70) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 0].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 0].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 0].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 0].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 0].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 70) / 4,
                    ),
              menuModules.length > (4 * index + 1)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 1].isActive) return;

                        menuModules[4 * index + 1].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 70) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 1].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 1].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 1].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 1].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 1].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 70) / 4,
                    ),
              menuModules.length > (4 * index + 2)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 2].isActive) return;

                        menuModules[4 * index + 2].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 70) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 2].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 2].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 2].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 2].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 2].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 70) / 4,
                    ),
              menuModules.length > 8 && (4 * index + 3) >= 7
                  ? GestureDetector(
                      onTap: () {
                        _pc.open();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 70) / 4,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.list,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              "Other".tr(),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                  : menuModules.length > (4 * index + 3)
                      ? GestureDetector(
                          onTap: () {
                            if (!menuModules[4 * index + 3].isActive) return;

                            menuModules[4 * index + 3].onTap();
                          },
                          child: SizedBox(
                            width: (mediaQuery.size.width - 70) / 4,
                            child: Column(
                              children: [
                                Center(
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 0.0),
                                        child: Icon(
                                          menuModules[4 * index + 3].icon,
                                          size: 50,
                                          color: menuModules[4 * index + 3].isActive ? Colors.grey : Colors.grey,
                                        ),
                                      ),
                                      Visibility(
                                        visible: !menuModules[4 * index + 3].isActive,
                                        child: const Positioned(
                                          right: 0.0,
                                          top: 0.0,
                                          child: Icon(
                                            Icons.lock,
                                            color: Colors.red,
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5.0),
                                Text(
                                  menuModules[4 * index + 3].title,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: menuModules[4 * index + 3].isActive ? Colors.black : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: (mediaQuery.size.width - 70) / 4,
                        ),
            ],
          ),
        );
      });
  }

  Widget buildPanel(ScrollController sc) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(
          controller: sc,
          children: [
            Container(
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5.0,
                    offset: const Offset(0.0, 0.3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Other".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _pc.close();
                        },
                        child: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: buildMenuItemOther(),
            ),
          ],
        ));
  }

  Widget buildMenuItemOther() {
    var mediaQuery = MediaQuery.of(context);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: ((menuModules.length + 1) / 4).ceil() - 2 < 0 ? 0 : ((menuModules.length + 1) / 4).ceil() - 2,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 7.0,
            bottom: 7.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              menuModules.length > (4 * index + 0 + 7)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 0 + 7].isActive) return;

                        menuModules[4 * index + 0 + 7].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 50) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 0 + 7].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 0 + 7].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 0 + 7].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 0 + 7].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 0 + 7].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 50) / 4,
                    ),
              menuModules.length > (4 * index + 1 + 7)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 1 + 7].isActive) return;

                        menuModules[4 * index + 1 + 7].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 50) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 1 + 7].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 1 + 7].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 1 + 7].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 1 + 7].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 1 + 7].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 50) / 4,
                    ),
              menuModules.length > (4 * index + 2 + 7)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 2 + 7].isActive) return;

                        menuModules[4 * index + 2 + 7].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 50) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 2 + 7].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 2 + 7].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 2 + 7].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 2 + 7].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 2 + 7].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 50) / 4,
                    ),
              menuModules.length > (4 * index + 3 + 7)
                  ? GestureDetector(
                      onTap: () {
                        if (!menuModules[4 * index + 3 + 7].isActive) return;

                        menuModules[4 * index + 3 + 7].onTap();
                      },
                      child: SizedBox(
                        width: (mediaQuery.size.width - 50) / 4,
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Icon(
                                      menuModules[4 * index + 3 + 7].icon,
                                      size: 50,
                                      color: menuModules[4 * index + 3 + 7].isActive ? Colors.grey : Colors.grey,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !menuModules[4 * index + 3 + 7].isActive,
                                    child: const Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.red,
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              menuModules[4 * index + 3 + 7].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: menuModules[4 * index + 3 + 7].isActive ? Colors.black : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: (mediaQuery.size.width - 50) / 4,
                    ),
            ],
          ),
        );
      });
  }

  Widget buildAnnouncement() {
    var mediaQuery = MediaQuery.of(context);
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(
            left: 10.0,
            right: 10.0,
          ),
          height: 205.0,
          child: PageView.builder(
            onPageChanged: (int index) {
              setState(() {
                _current = index;
              });
            },
            scrollDirection: Axis.horizontal,
            itemCount: _announcements.length,
            itemBuilder: (context, index) {
              var announcement = _announcements[index];
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  width: mediaQuery.size.width - 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        5.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 15.0,
                            right: 15.0,
                            top: 15.0,
                            bottom: 5.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                announcement.subject,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Colors.grey.shade300
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 15.0,
                            right: 15.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Html(
                                data: announcement.content,
                                style: {
                                  "table[border] td": Style(
                                    border: const Border(
                                      left: BorderSide(color: Colors.black, width: 0.5),
                                      right: BorderSide(color: Colors.black, width: 0.5),
                                      bottom: BorderSide(color: Colors.black, width: 0.5),
                                    ),
                                    padding: HtmlPaddings.all(5)
                                  ),
                                  "table[border] th": Style(
                                    border: const Border(
                                      left: BorderSide(color: Colors.black, width: 0.5),
                                      right: BorderSide(color: Colors.black, width: 0.5),
                                      bottom: BorderSide(color: Colors.black, width: 0.5),
                                    ),
                                    padding: HtmlPaddings.all(5)
                                  ),
                                  "table[border] tr:first-child th": Style(
                                    border: Border.all(color: Colors.black, width: 0.5),
                                    padding: HtmlPaddings.all(5)
                                  ),
                                  "table[border] tr:first-child td": Style(
                                    border: Border.all(color: Colors.black, width: 0.5),
                                    padding: HtmlPaddings.all(5)
                                  )
                                },
                                onLinkTap: (url, attributes, element) {
                                  if(url != null) {
                                    launchUrl(Uri.parse(url));
                                  }
                                },
                                extensions: const [TableHtmlExtension()],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _announcements.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Container(
                width: _current == index ? 16.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                  color: _current == index ? Config.DEFAULT_COLOR : Colors.grey[300],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }
}
