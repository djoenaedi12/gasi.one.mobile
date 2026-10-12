import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe_public_holiday.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:flutter/material.dart';

class LeaveScoupePage extends StatefulWidget {
  final List<LeaveTransactionScoupe> leaveTransactionScoupes;
  final List<LeaveTransactionScoupePublicHoliday> leaveTransactionScoupePublicHolidays;
  final bool editable;
  const LeaveScoupePage({Key? key, this.leaveTransactionScoupes = const [], this.leaveTransactionScoupePublicHolidays = const [], this.editable= true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LeaveScoupePageState();
}

class _LeaveScoupePageState extends State<LeaveScoupePage> {
  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Scoupe".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: (widget.leaveTransactionScoupes.isEmpty) && (widget.leaveTransactionScoupePublicHolidays.isEmpty)
      ? Center(
        child: Text(
          "No Data Found".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      )
      : Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.leaveTransactionScoupes.length,
              itemBuilder: (BuildContext bc, int index) {
                LeaveTransactionScoupe leaveTransactionScoupe = widget.leaveTransactionScoupes[index];
                return Container(
                  width: mediaQuery.width,
                  padding: const EdgeInsets.only(
                    right: 10.0,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: leaveTransactionScoupe.scoupe,
                        onChanged: (val) {
                          if(!widget.editable) return;

                          setState(() {
                            leaveTransactionScoupe.scoupe = !leaveTransactionScoupe.scoupe;
                          });
                        },
                      ),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  leaveTransactionScoupe.leaveTransactionScoupe!.leaveCategory!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ],
                            ),
                            Text("${leaveTransactionScoupe.duration} ${"Days".tr()}")
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.leaveTransactionScoupePublicHolidays.length,
              itemBuilder: (BuildContext bc, int index) {
                LeaveTransactionScoupePublicHoliday leaveTransactionScoupePublicHoliday = widget.leaveTransactionScoupePublicHolidays[index];
                return Container(
                  width: mediaQuery.width,
                  padding: const EdgeInsets.only(
                    right: 10.0,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: leaveTransactionScoupePublicHoliday.scoupe,
                        onChanged: (val) {
                          if(!widget.editable) return;
                          
                          setState(() {
                            leaveTransactionScoupePublicHoliday.scoupe = !leaveTransactionScoupePublicHoliday.scoupe;
                          });
                        },
                      ),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${EnumProvider.convertToString(leaveTransactionScoupePublicHoliday.publicHoliday!.holidayType, capitalEachWord: true)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(width: 5.0),
                                Text(
                                  leaveTransactionScoupePublicHoliday.publicHoliday!.description,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ],
                            ),
                            Text("${leaveTransactionScoupePublicHoliday.duration} ${"Days".tr()}")
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
      ),
    );
  }
}