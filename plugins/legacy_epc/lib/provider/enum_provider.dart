import 'package:epeoplecare/provider/string_provider.dart';

class EnumProvider {

  static bool _isEnumItem(enumItem) {
    final splitEnum = enumItem.toString().split('.');
    return splitEnum.length > 1 &&
        splitEnum[0] == enumItem.runtimeType.toString();
  }

  static int indexOf<T>(List<T> enumValues, value) {
    for (var i = 0; i < enumValues.length; i++) {
      if(enumValues[i] == value) {
        return i;
      }
    }
    return -1;
  }

  static List<String?>? toList<T>(List<T>? enumValues, {bool capitalEachWord = false}) {
    if (enumValues == null) return null;
    final enumList = enumValues
        .map((t) => !capitalEachWord
            ? EnumProvider.convertToString(t)
            : EnumProvider.convertToString(t, capitalEachWord: true))
        .toList();

    return enumList;
  }

  static String? convertToString(enumItem, {bool capitalEachWord = false}) {
    if (enumItem == null) return null;

    assert(_isEnumItem(enumItem), '$enumItem of type ${enumItem.runtimeType.toString()} is not an enum item');
    final tmp = enumItem.toString().split('.')[1];
    return !capitalEachWord ? tmp : StringProvider.capitalEachWord(tmp);
  }

  static T? fromString<T>(List<T>? enumValues, String? value) {
    if (value == null || enumValues == null) return null;

    return enumValues.singleWhere((enumItem) => EnumProvider.convertToString(enumItem)?.toLowerCase() == value.toLowerCase());
  }

  static List<T>? fromList<T>(List<T>? enumValues, List? valueList) {
    if (valueList == null || enumValues == null) return null;

    return List<T>.from(valueList.map((item) => item == null ? null : fromString<T>(enumValues, item)));
  }
}