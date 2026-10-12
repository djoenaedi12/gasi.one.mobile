import 'package:easy_localization/easy_localization.dart';

class Validation {
  
  static String? validateField(String? value) {
    if (value == null || value.isEmpty) {
      return "This field is required".tr();
    }

    return null;
  }
  
}
