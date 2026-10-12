import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/event.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';
import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
import 'package:epeoplecare/repository/company/public_holiday_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const CalendarPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Event>> eventsMap = HashMap();
  final PublicHolidayRepository _publicHolidayRepository = Repository().getPublicHolidayRepository();
  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
     _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return eventsMap[DateTime(day.year,day.month,day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  _getData(DateTime first, DateTime last) async {
    eventsMap.clear();
    _publicHolidayRepository.listByDate(first, last).then((value) {
      setState(() {
        for (PublicHoliday publicHoliday in value) {
          List<Event> events = [];
          if(eventsMap.containsKey(DateProvider.convertStr2Date(publicHoliday.date, "yyyy-MM-dd"))) {
            events = eventsMap[DateProvider.convertStr2Date(publicHoliday.date, "yyyy-MM-dd")]!;
          }

          Event event = Event(publicHoliday.date, publicHoliday.description, Colors.red);
          events.add(event);
          eventsMap.putIfAbsent(DateProvider.convertStr2Date(publicHoliday.date, "yyyy-MM-dd")!, () => events);
        }
      });
    });
    List<String> status = [
      EnumProvider.convertToString(WorkflowStatus.APPROVED)!,
    ];

    _leaveTransactionRepository.listByWorkflowStatusAndDate(status, first, last).then((value) {
      setState(() {
        for (LeaveTransaction leaveTransaction in value) {
          DateTime from = DateProvider.convertStr2Date(leaveTransaction.startDate, "yyyy-MM-dd")!;
          DateTime to = DateProvider.convertStr2Date(leaveTransaction.endDate, "yyyy-MM-dd")!;
          while (from.compareTo(to) <= 0) {            
            List<Event> events = [];
            if(eventsMap.containsKey(from)) {
              events = eventsMap[from]!;
            }

            Event event = Event(
              DateProvider.convertDate2Str(from, "yyyy-MM-dd"), 
              "${leaveTransaction.leaveCategory!.name} - ${leaveTransaction.employee!.name}", 
              Config.DEFAULT_COLOR,
            );
            events.add(event);
            eventsMap.putIfAbsent(from, () => events);
            from = from.add(const Duration(days: 1));
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          _buildTableCalendarWithBuilders(),
          const SizedBox(height: 8.0),
          _buildEventList(),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Widget _buildTableCalendarWithBuilders() {
    return TableCalendar(
      eventLoader: _getEventsForDay,
      locale: Config.language,
      firstDay: DateTime(2010),
      lastDay: DateTime(2050),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      availableCalendarFormats: {
        CalendarFormat.month: 'Month'.tr(),
        CalendarFormat.week: 'Week'.tr(),
      },
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,        
      ),
      availableGestures: AvailableGestures.all,
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        DateTime first = DateTime(_focusedDay.year, _focusedDay.month, 1);
        DateTime last = DateTime(_focusedDay.year, _focusedDay.month+1, 0);
        _getData(DateProvider.getFirstDateOfWeek(first), DateProvider.getLastDateOfWeek(last));
      },
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      calendarBuilders: CalendarBuilders(
        selectedBuilder: (context, date, focusedDay) {
          return isSameDay(date, DateTime.now()) 
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 0.5, color: Config.DEFAULT_COLOR)
              ),
              padding: const EdgeInsets.only(top: 5.0),
              width: 100,
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Config.DEFAULT_COLOR,
                    ),
                    child: Text(
                      '${date.day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Config.DEFAULT_ACCENT_COLOR,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 0.8, color: Config.DEFAULT_COLOR)
              ),
              padding: const EdgeInsets.only(top: 10.0),
              width: 100,
              height: 100,
              child: Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                ),
              ),
            );
        },
        todayBuilder: (context, date, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 0.8, color: Colors.grey.shade100)
            ),
            padding: const EdgeInsets.only(top: 5.0),
            width: 100,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Config.DEFAULT_COLOR,
                  ),
                  child: Text(
                    '${date.day}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        outsideBuilder: (context, date, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 0.5, color: Colors.grey.shade200)
            ),
            padding: const EdgeInsets.only(top: 10.0),
            width: 100,
            height: 100,
            child: Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey
              ),
            ),
          );
        },
        defaultBuilder: (context, date, focusedDay) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 0.5, color: Colors.grey.shade200)
            ),
            padding: const EdgeInsets.only(top: 10.0),
            width: 100,
            height: 100,
            child: Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style: const TextStyle(
              ),
            ),
          );
        },
        markerBuilder: (context, day, events) {
          final item = <Widget>[];
          for (var i = 0; i < (events.length > 3 ? 3 : events.length); i++) {
            Event? event = events[i] as Event?;
            item.add(
              Container(
                margin: const EdgeInsets.only(right: 1.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: event!.color,
                ),
                width: 8.0,
                height: 8.0,
              ),
            );
          }

          return Positioned(
            bottom: 5.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: item,
            ),
          );
        },

      ),
      onCalendarCreated: (pageController) {
        DateTime first = DateTime(_focusedDay.year, _focusedDay.month, 1);
        DateTime last = DateTime(_focusedDay.year, _focusedDay.month+1, 0);
        _getData(DateProvider.getFirstDateOfWeek(first), DateProvider.getLastDateOfWeek(last));
      },
    );
  }

  Widget _buildEventList() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75.0,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  DateProvider.convertDate2Str(_selectedDay, "EE"),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateProvider.convertDate2Str(_selectedDay, "dd"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedEvents.value.isNotEmpty 
            ? ListView(
                children: _selectedEvents.value.map((event) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: event.color,
                  ),
                  margin:const EdgeInsets.symmetric(
                    horizontal: 8.0, 
                    vertical: 2.0,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {

                    },
                  ),
                )).toList(),
              )
            : Text(
              "No events".tr(),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}