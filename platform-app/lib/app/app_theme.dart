import 'package:flutter/material.dart';

// TRANSITION[LEGACY-UI]: values below preserve the EPC visual theme.
// Replace parity values when the new design-system theme is approved.
// The host theme factory itself remains part of the permanent foundation.
ThemeData buildAppTheme({
  required Color primaryColor,
  required Color accentColor,
}) => ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  primarySwatch: Colors.blue,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    ),
  ),
  buttonTheme: ButtonThemeData(buttonColor: primaryColor),
  appBarTheme: AppBarTheme(backgroundColor: primaryColor),
  textSelectionTheme: TextSelectionThemeData(cursorColor: primaryColor),
  datePickerTheme: DatePickerThemeData(
    headerBackgroundColor: primaryColor,
    headerForegroundColor: accentColor,
    dividerColor: Colors.grey.shade300,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: Colors.white,
    dialHandColor: primaryColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
  ),
  colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
  ),
  drawerTheme: DrawerThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    ),
  ),
);
