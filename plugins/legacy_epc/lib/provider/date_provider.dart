// ignore_for_file: empty_catches

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/material.dart';

class DateProvider {
  
  static String convertDate2Str(DateTime? date, String format) {
    if(date == null) return "";
    return DateFormat(format, _getLocale()).format(date);
  }

  static DateTime? convertStr2Date(String? dateStr, String format) {
    if(dateStr == null || dateStr == "") return null;
    return DateFormat(format, _getLocale()).parse(dateStr);
  }

  static String convertTimeOfDay2Str(TimeOfDay? time) {
    if(time == null) return "";
    String formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return formattedTime;
  }

  static TimeOfDay? convertStr2TimeOfDay(String? timeStr) {
    if(timeStr == null || timeStr == "") return null;
    try {
      TimeOfDay formattedTime = TimeOfDay(hour:int.parse(timeStr.split(":")[0]),minute:int.parse(timeStr.split(":")[1]));
      return formattedTime;
    } catch (onError) {
      return null;
    }
  }

  static String convertDateStrFormat(String? dateStr, String oriFormat, String destFormat) {
    if(dateStr == null || dateStr == "") return "";
    DateTime date = DateFormat(oriFormat, _getLocale()).parse(dateStr);
    return DateFormat(destFormat, _getLocale()).format(date);
  }

  static DateTime? convertDateFormat(DateTime? date, String oriFormat, String destFormat) {
    if(date == null) return null;
    String dateStr = DateFormat(oriFormat, _getLocale()).format(date); 
    return DateFormat(destFormat, _getLocale()).parse(dateStr);
  }

  static String convertDateStrReadable(String? date) {
    if(date == null || date == "") return "";

    // DateTime now = DateTime.now();
    // DateTime postDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
    var strDate = "";
    // if(Jiffy(now).diff(postDate, Units.SECOND) < 10) {
    //   strDate = "${getTranslated(navigatorKey.currentContext, "Just Now")}";
    // } else if (Jiffy(now).diff(postDate, Units.MINUTE) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.SECOND).toString() + " ${getTranslated(navigatorKey.currentContext, "seconds ago")}";
    // } else if (Jiffy(now).diff(postDate, Units.HOUR) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.MINUTE).toString() + " ${getTranslated(navigatorKey.currentContext, "minutes ago")}";
    // } else if (Jiffy(now).diff(postDate, Units.DAY) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.HOUR).toString() + " ${getTranslated(navigatorKey.currentContext, "hours ago")}";
    // } else if (Jiffy(now).diff(postDate, Units.WEEK) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.DAY).toString() + " ${getTranslated(navigatorKey.currentContext, "days ago")}";
    // } else if (Jiffy(now).diff(postDate, Units.MONTH) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.WEEK).toString() + " ${getTranslated(navigatorKey.currentContext, "weeks ago")}";
    // } else if (Jiffy(now).diff(postDate, Units.YEAR) == 0) {
    //   strDate = Jiffy(now).diff(postDate, Units.MONTH).toString() + " ${getTranslated(navigatorKey.currentContext, "months ago")}";
    // } else {
    //   strDate = Jiffy(now).diff(postDate, Units.YEAR).toString() + " ${getTranslated(navigatorKey.currentContext, "years ago")}";
    // }

    return strDate;
  }

  static DateTime getCurrentDate() {
    return DateTime.now();
  }

  static DateTime getCurrentDateMidnight() {
    DateTime now = getCurrentDate();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? convertStr2DateMidnight(String? dateStr, String format) {
    if(dateStr == null || dateStr == "") return null;
    DateTime dt = DateFormat(format).parse(dateStr);
    return DateTime(dt.year, dt.month, dt.day);
  }

  static int getCurrentYear() {
    return getCurrentDate().year;
  }

  static DateTime getFirstMidnightCurrentDate() {
    DateTime now = getCurrentDate();
    return DateTime(now.year, now.month, 1);
  }

  // Ambil informasi tanggal terakhir
  // Pada tanggal / periode saat ini
  static DateTime getLastMidnightCurrentDate() {
    DateTime now = getCurrentDate();
    return DateTime(now.year, now.month, getLastDay(now));
  }

  static String _getLocale() {
    return Config.language;
  }

  static int getLastDay(DateTime now) {
    var lastDayDateTime = (now.month < 12) ? DateTime(now.year, now.month + 1, 0) : DateTime(now.year + 1, 1, 0);
    return lastDayDateTime.day;
  }

  static Duration convertDuration({required String durationStr, bool inverse= false}) {
    Duration duration = const Duration();
    try {
      var durations = durationStr.split(":");
      if(durations.length != 2) {
        throw Exception("");
      }

      var hour = durations[0];
      if(inverse) {
        if(durations[0].contains("+")) {
          hour = durations[0].replaceAll("+", "-");
        } else if(durations[0].contains("-")) {
          hour = durations[0].replaceAll("-", "+");
        }
      } 
      
      hour = hour.replaceAll("+", "");
      var minute = durations[1];
      duration = Duration(hours: int.parse(hour), minutes: int.parse(minute));
    } catch (e) {
    }

    return duration;
  }

  static DateTime? convertToLocal(DateTime? dt, Duration oriTimezone,{bool keepDate= false}) {
    if(dt == null) return null;
    
    Duration destDuration = DateTime.now().timeZoneOffset;
    DateTime nDt = dt.add(oriTimezone);
    nDt = nDt.add(destDuration);
    if(keepDate) {
      nDt = DateTime(dt.year, dt.month, dt.day, nDt.hour, nDt.minute, nDt.second);
    }
    return nDt;
  }

  static Duration getLocalTimezone() {
    return DateTime.now().timeZoneOffset;
  }

  static int compareTime(DateTime t1, DateTime t2) {
    if(t1.hour < t2.hour) {
      return 1;
    }
    else if (t1.hour > t2.hour) {
      return -1;
    }
    else {
      if(t1.minute < t2.minute) {
        return 1;
      }
      else if (t1.minute > t2.minute) {
        return -1;
      }
      else {
        if(t1.second < t2.second) {
          return 1;
        }
        else if (t1.second > t2.second) {
          return -1;
        }
        else {
          return 0;
        }
      }
    }
  }

  static DateTime getFirstDateOfWeek(DateTime dateTime) {
    return dateTime.subtract(Duration(days: dateTime.weekday % 7));
  }

  static DateTime getLastDateOfWeek(DateTime dateTime) {
    return dateTime.add(Duration(days: 6 - dateTime.weekday % 7));
  }
}