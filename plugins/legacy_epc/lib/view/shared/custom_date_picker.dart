import 'dart:async';
import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
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

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Employee? employee;
  const CustomDatePicker({Key? key, required this.initialDate, required this.firstDate, required this.lastDate, this.employee}): super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {

  final List<String> _dayOfWeek = [
    "DayOfWeek.SUNDAY",
    "DayOfWeek.MONDAY",
    "DayOfWeek.TUESDAY",
    "DayOfWeek.WEDNESDAY",
    "DayOfWeek.THURSDAY",
    "DayOfWeek.FRIDAY",
    "DayOfWeek.SATURDAY"
  ];
  late DateTime _currentDate;
  late DateTime _selectedDate;
  final _scrollController = ScrollController();
  bool _calendarViewMode = true;
  final PublicHolidayRepository _publicHolidayRepository = Repository().getPublicHolidayRepository();
  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();
  Map<DateTime, List<Event>> eventsMap = HashMap();
  final _inputController = TextEditingController();
  bool _pickerMode = true;
  final _form = GlobalKey<FormState>();
  final _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(widget.initialDate.year,widget.initialDate.month,widget.initialDate.day);
    _selectedDate = DateTime(widget.initialDate.year,widget.initialDate.month,widget.initialDate.day);
    _getDataEvent(DateTime(_currentDate.year, _currentDate.month, 1), DateTime(_currentDate.year, _currentDate.month, DateProvider.getLastDay(_currentDate)));
    _inputController.text = DateProvider.convertDate2Str(_currentDate, "MM/dd/yyyy");
  }

  _getDataEvent(DateTime first, DateTime last) {
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

    if(widget.employee != null) {
      List<String> status = [
        EnumProvider.convertToString(WorkflowStatus.APPROVED)!,
      ];
      _leaveTransactionRepository.listByEmployeeWorkflowStatusAndDate(widget.employee!, status, first, last).then((value) {
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
                leaveTransaction.leaveCategory!.name,
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
  }
  

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Dialog(
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header(context),
             _pickerMode 
              ? bodyNavigation(context)
              : const SizedBox(),
            _calendarViewMode && _pickerMode
              ? bodyCalendarHeader(context)
              : const SizedBox(),
            _pickerMode
              ? _calendarViewMode 
                ? bodyCalendar(context)
                : bodyYear(context)
              : bodyInput(context),
            footerButton(context),
          ],
        ),
      ),
    );
  }

  Widget header(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;
    return Container(
      width: mediaQuery.width,
      decoration: BoxDecoration(
        color: Config.DEFAULT_COLOR,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5.0),
          topRight: Radius.circular(5.0),
        )
      ),
      padding: const EdgeInsets.only(
        left: 25.0,
        top: 20.0,
        bottom: 20.0,
        right: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELECT DATE".tr(),
            style: const TextStyle(
              letterSpacing: 1.5,
              fontSize: 9.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateProvider.convertDate2Str(_selectedDate, "EE, dd MMM"),
                style: const TextStyle(
                  fontSize: 30.0,
                  color: Colors.white
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _pickerMode = !_pickerMode;
                  });
                  if(!_pickerMode) {
                    _inputFocusNode.requestFocus();
                  }
                },
                child: Icon(
                  _pickerMode ? Icons.edit : Icons.calendar_today,
                  size: 20.0,
                  color: Colors.white
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bodyNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 25.0,
        top: 10.0,
        bottom: 10.0,
        right: 20.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _calendarViewMode = !_calendarViewMode;
                if(!_calendarViewMode) {
                  var duration = const Duration(milliseconds: 100);
                  Timer(duration, () {
                    double scrollTo = (_selectedDate.year - widget.firstDate.year) / 3 * 45;
                    _scrollController.jumpTo(scrollTo);
                  });
                }
              });
            },
            child: Row(
              children: [
                Text(
                  DateProvider.convertDate2Str(_currentDate, "MMMM yyyy"),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Icon(
                  _calendarViewMode 
                    ? Icons.arrow_drop_down 
                    : Icons.arrow_drop_up,
                  color: Colors.grey,
                )
              ],
            ),
          ),
          Visibility(
            visible: _calendarViewMode,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if(DateTime(_currentDate.year, _currentDate.month, 1).compareTo(widget.firstDate) <= 0 ) {
                      return;
                    }

                    setState(() {
                      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
                    });

                    _getDataEvent(DateTime(_currentDate.year, _currentDate.month, 1), DateTime(_currentDate.year, _currentDate.month, DateProvider.getLastDay(_currentDate)));
                  },
                  child: Icon(
                    Icons.chevron_left,
                    color: DateTime(_currentDate.year, _currentDate.month, 1).compareTo(widget.firstDate) <= 0
                            ? Colors.grey[400]
                            : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10.0),
                GestureDetector(
                  onTap: () {
                    if(DateTime(_currentDate.year, _currentDate.month, DateProvider.getLastDay(_currentDate)).compareTo(widget.lastDate) >= 0 ) {
                      return;
                    }

                    setState(() {
                      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
                    });
                    _getDataEvent(DateTime(_currentDate.year, _currentDate.month, 1), DateTime(_currentDate.year, _currentDate.month, DateProvider.getLastDay(_currentDate)));
                  },
                  child: Icon(
                    Icons.chevron_right,
                    color: DateTime(_currentDate.year, _currentDate.month, DateProvider.getLastDay(_currentDate)).compareTo(widget.lastDate) >= 0
                            ? Colors.grey[400]
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bodyCalendarHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: _dayOfWeek.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, 
        ),
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: Text(
              _dayOfWeek[index].tr(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
            ),
          );
        }
      ),
    );
  }

  Widget bodyCalendar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            itemCount: DateProvider.getLastDay(_currentDate) + getWeekday(_currentDate),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
            ),
            itemBuilder: (BuildContext context, int index) {
              int dow = getWeekday(_currentDate);
              if(dow > index) {
                return const SizedBox();
              }
              
              return GestureDetector(
                onTap: () {
                  if(DateTime(_currentDate.year, _currentDate.month, index - dow + 1).compareTo(widget.firstDate) < 0 || DateTime(_currentDate.year, _currentDate.month, index - dow + 1).compareTo(widget.lastDate) > 0 ) {
                    return;
                  }

                  setState(() {
                    _selectedDate = DateTime(_currentDate.year, _currentDate.month, index - dow + 1);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelectedDate(_currentDate, index - dow + 1) 
                              ? Config.DEFAULT_COLOR 
                              : Colors.white,
                      border: Border.all(
                        color: isCurrentDate(_currentDate, index - dow + 1) 
                                ? Config.DEFAULT_COLOR
                                : Colors.white,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (index - dow + 1).toString(),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: DateTime(_currentDate.year, _currentDate.month, index - dow + 1).compareTo(widget.firstDate) < 0 || DateTime(_currentDate.year, _currentDate.month, index - dow + 1).compareTo(widget.lastDate) > 0 
                                  ? Colors.grey[400]
                                  : isSelectedDate(_currentDate, index - dow + 1) 
                                    ? Colors.white 
                                    : isCurrentDate(_currentDate, index - dow + 1) 
                                      ? Config.DEFAULT_COLOR 
                                        : eventsMap.containsKey(DateTime(_currentDate.year, _currentDate.month, index - dow + 1))
                                          ? eventsMap[DateTime(_currentDate.year, _currentDate.month, index - dow + 1)]!.isNotEmpty 
                                            ? eventsMap[DateTime(_currentDate.year, _currentDate.month, index - dow + 1)]![0].color
                                            : Config.DEFAULT_COLOR
                                          : Colors.black
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              left: 10.0,
              right: 10.0,
              // bottom: 5.0,
            ),
            child: Visibility(
              visible: eventsMap.containsKey(_selectedDate)
                    && eventsMap[_selectedDate]!.isNotEmpty,
              child: Row(
                children: [
                  Container(
                    height: 7.0,
                    width: 7.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: eventsMap.containsKey(_selectedDate)
                              && eventsMap[_selectedDate]!.isNotEmpty 
                              ? eventsMap[_selectedDate]![0].color
                              : Config.DEFAULT_COLOR,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Expanded(
                    child: Text(
                      eventsMap.containsKey(_selectedDate)
                      && eventsMap[_selectedDate]!.isNotEmpty 
                      ? eventsMap[_selectedDate]![0].title
                      : "",
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bodyYear(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5.0),
        Divider(height: 5, color: Colors.grey.shade300),
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: GridView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: widget.lastDate.year - widget.firstDate.year + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              childAspectRatio: MediaQuery.of(context).size.width /
                  (MediaQuery.of(context).size.height / 3),
            ),
            itemBuilder: (BuildContext context, int index) {
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDate = DateTime(widget.firstDate.year + index, _currentDate.month, _currentDate.day);
                    _calendarViewMode = !_calendarViewMode;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: isSelectedYear(widget.firstDate.year + index) 
                              ? Config.DEFAULT_COLOR 
                              : Colors.white,
                      border: Border.all(
                        color: isCurrentYear(widget.firstDate.year + index) 
                                ? Config.DEFAULT_COLOR
                                : Colors.white,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (widget.firstDate.year + index).toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelectedYear(widget.firstDate.year + index) 
                                  ? Colors.white 
                                  : isCurrentYear(widget.firstDate.year + index) 
                                    ? Config.DEFAULT_COLOR 
                                    : Colors.black
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
        Divider(height: 5, color: Colors.grey.shade300),
      ],
    );
  }

  Widget bodyInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Form(
        key: _form,
        child: TextFormField(
          focusNode: _inputFocusNode,
          controller: _inputController,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            labelText: "Enter Date".tr(),
            hintText: "mm/dd/yyyy".tr(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: Config.DEFAULT_COLOR,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: Config.DEFAULT_COLOR,
              ),
            ),
          ),
          validator: (val) {
            try {
              DateTime pickedDate = DateProvider.convertStr2Date(val, "MM/dd/yyyy")!;
              if(pickedDate.compareTo(widget.firstDate) < 0 || pickedDate.compareTo(widget.lastDate) > 0) {
                return "Out of range".tr();
              }
            } catch (e) {
              return "Invalid format".tr();
            }

            return null;
          },
        ),
      ),
    );
  }

  Widget footerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 5.0,
        right: 10.0,
        bottom: 5.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "CANCEL".tr(),
              style: TextStyle(
                color: Config.DEFAULT_COLOR,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if(!_pickerMode) {
                if (_form.currentState!.validate()) {
                  setState(() {
                    _selectedDate = DateProvider.convertStr2Date(_inputController.text, "MM/dd/yyyy")!;  
                  });
                  Navigator.of(context).pop(_selectedDate);
                }
              } else {
                Navigator.of(context).pop(_selectedDate);
              }
            },
            child: Text(
              "OK".tr(),
              style: TextStyle(
                color: Config.DEFAULT_COLOR,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int getWeekday(DateTime now) {
    DateTime dow = DateTime(now.year, now.month, 1);
    return dow.weekday;
  }

  bool isSelectedDate(DateTime now, int day) {
    DateTime selectedDate = DateTime(now.year, now.month, day);
    if(_selectedDate == selectedDate) {
      return true;
    }

    return false;
  }

  bool isSelectedYear(int year) {
    if(_selectedDate.year == year) {
      return true;
    }

    return false;
  }

  bool isCurrentDate(DateTime now, int day) {
    DateTime selectedDate = DateTime(now.year, now.month, day);
    DateTime currentDate = DateProvider.getCurrentDateMidnight();
    if(currentDate == selectedDate) {
      return true;
    }

    return false;
  }

  bool isCurrentYear(int year) {
    int currentYear = DateTime.now().year;
    if(year == currentYear) {
      return true;
    }

    return false;
  }
}