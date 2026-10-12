import 'package:easy_localization/easy_localization.dart';

class NumberProvider {
  static String decimalFormatInt(int? number) {
    if(number == null) return "0.00";
    var numberFormat = NumberFormat("#,##0.00", "en_US");
    return numberFormat.format(number);
  }

  static String decimalFormatDouble(double? number) {
    if(number == null) return "0.00";
    var numberFormat = NumberFormat("#,##0.00", "en_US");
    return numberFormat.format(number);
  }
}