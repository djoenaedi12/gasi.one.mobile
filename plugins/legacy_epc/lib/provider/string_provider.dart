import 'package:flutter/material.dart';

class StringProvider {

  static String getInitials(String? words, {int length = 2}) {
    if(words == null) return "";
    
    List<String> names = words.split(" ");
    String initials = "";
    if(names.length < length) {
      length = names.length;
    }
    for (var i = 0; i < length; i++) {
      if(names[i] == "") continue;
      initials += names[i][0].toUpperCase();
    }
    return initials;
  }

  static String capitalEachWord(String? str) {
    if(str == null) return "";
    
    final List<String> splitStr = str.toLowerCase().split(RegExp(r'(_|-)+'));
    for (int i = 0; i < splitStr.length; i++) {
      splitStr[i] = '${splitStr[i][0].toUpperCase()}${splitStr[i].substring(1)}';
    }
    final output = splitStr.join(' ');
    return output;
  }

  static Color? hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if(hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }

    if(hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }

    return null;
  }
}