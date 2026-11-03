// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GASI:One';

  @override
  String get loading => 'Loading';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get preparingApp => 'Preparing the application…';

  @override
  String get appPreparationFailed =>
      'Unable to prepare the application. Please try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get requiredField => 'This field is required.';

  @override
  String createResource(String resource) {
    return 'Create $resource';
  }

  @override
  String editResource(String resource) {
    return 'Edit $resource';
  }

  @override
  String selectResource(String resource) {
    return 'Select $resource';
  }

  @override
  String noResources(String resource) {
    return 'No $resource';
  }

  @override
  String get noDataAvailable => 'No data is available yet.';

  @override
  String get noOptionsAvailable => 'No options are available.';

  @override
  String deleteResourceQuestion(String resource) {
    return 'Delete $resource?';
  }

  @override
  String deleteRecordQuestion(String label) {
    return 'Delete $label?';
  }

  @override
  String validationRequired(String field) {
    return '$field is required.';
  }

  @override
  String validationMaxLength(String field, int maxLength) {
    return '$field must be at most $maxLength characters.';
  }

  @override
  String validationWholeNumber(String field) {
    return '$field must be a valid whole number.';
  }

  @override
  String validationNumber(String field) {
    return '$field must be a valid number.';
  }

  @override
  String validationIsoDate(String field) {
    return '$field must be a valid ISO date.';
  }

  @override
  String get home => 'Home';

  @override
  String get mainMenuDescription => 'Choose a menu to manage application data.';

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get search => 'Search';

  @override
  String get code => 'Code';

  @override
  String get name => 'Name';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get operationSuccessful => 'Operation successful';

  @override
  String get operationFailed => 'Operation failed.';

  @override
  String get networkError =>
      'Unable to connect. Check your internet connection.';

  @override
  String get timeoutError => 'The request timed out. Please try again.';

  @override
  String get unauthorizedError =>
      'Your session is no longer valid. Please sign in again.';

  @override
  String get forbiddenError =>
      'You do not have permission to perform this action.';

  @override
  String get notFoundError => 'The requested data was not found.';

  @override
  String get validationError => 'Some submitted data is not valid.';

  @override
  String get conflictError => 'The request conflicts with the current data.';

  @override
  String get rateLimitError => 'Too many requests. Please wait and try again.';

  @override
  String get serverError =>
      'The server encountered a problem. Please try again.';

  @override
  String get invalidResponseError => 'The server returned an invalid response.';

  @override
  String get requestCancelled => 'The request was cancelled.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';

  @override
  String get switchTheme => 'Switch theme';

  @override
  String get switchLanguage => 'Switch language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String routeNotFound(String routeName) {
    return 'Route $routeName was not found.';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get unsafeDeviceTitle => 'Device Does Not Meet Security Standard';

  @override
  String get unsafeDeviceMessage =>
      'GASI:One requires a physical device without root or jailbreak, with developer mode disabled, and the app installed in internal storage.\n\nUse another device if it is rooted, jailbroken, or an emulator. Disable developer mode, or reinstall in internal storage if needed.\n\nContact your administrator if you need help.';

  @override
  String get invalidApplicationTitle => 'Invalid application';

  @override
  String get invalidApplicationMessage =>
      'The application signature is invalid. Please reinstall the application from the official store.';

  @override
  String get exitApplication => 'Exit';

  @override
  String get unsafeDeviceIntroduction =>
      'For your data’s safety, GASI:One only runs on devices that meet these requirements:';

  @override
  String get deviceIntegrityRequirement =>
      'Not rooted, jailbroken, or an emulator';

  @override
  String get developerModeRequirement => 'Developer mode turned off';

  @override
  String get internalStorageRequirement => 'Installed in internal storage';

  @override
  String get deviceRemediationTitle => 'Please:';

  @override
  String get deviceIntegrityRemediation =>
      'Use another device if rooted, jailbroken, or an emulator';

  @override
  String get developerModeRemediation => 'Turn off developer mode if it is on';

  @override
  String get internalStorageRemediation =>
      'Reinstall in internal storage if installed on SD card';

  @override
  String get deviceAdministratorHelp => 'Or contact Administrator if needed.';

  @override
  String get deviceRequirementMet => 'Requirement met';

  @override
  String get deviceRequirementNotMet => 'Requirement not met';

  @override
  String get deviceRequirementUnavailable => 'Check result unavailable';

  @override
  String appCopyright(int year) {
    return '© $year GASI:One';
  }
}
