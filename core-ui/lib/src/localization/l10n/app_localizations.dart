import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GASI:One'**
  String get appName;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @createResource.
  ///
  /// In en, this message translates to:
  /// **'Create {resource}'**
  String createResource(String resource);

  /// No description provided for @editResource.
  ///
  /// In en, this message translates to:
  /// **'Edit {resource}'**
  String editResource(String resource);

  /// No description provided for @selectResource.
  ///
  /// In en, this message translates to:
  /// **'Select {resource}'**
  String selectResource(String resource);

  /// No description provided for @noResources.
  ///
  /// In en, this message translates to:
  /// **'No {resource}'**
  String noResources(String resource);

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data is available yet.'**
  String get noDataAvailable;

  /// No description provided for @noOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No options are available.'**
  String get noOptionsAvailable;

  /// No description provided for @deleteResourceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {resource}?'**
  String deleteResourceQuestion(String resource);

  /// No description provided for @deleteRecordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {label}?'**
  String deleteRecordQuestion(String label);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String validationRequired(String field);

  /// No description provided for @validationMaxLength.
  ///
  /// In en, this message translates to:
  /// **'{field} must be at most {maxLength} characters.'**
  String validationMaxLength(String field, int maxLength);

  /// No description provided for @validationWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a valid whole number.'**
  String validationWholeNumber(String field);

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a valid number.'**
  String validationNumber(String field);

  /// No description provided for @validationIsoDate.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a valid ISO date.'**
  String validationIsoDate(String field);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @mainMenuDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a menu to manage application data.'**
  String get mainMenuDescription;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(String name);

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @operationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get operationSuccessful;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed.'**
  String get operationFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection.'**
  String get networkError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @unauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Please sign in again.'**
  String get unauthorizedError;

  /// No description provided for @forbiddenError.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get forbiddenError;

  /// No description provided for @notFoundError.
  ///
  /// In en, this message translates to:
  /// **'The requested data was not found.'**
  String get notFoundError;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Some submitted data is not valid.'**
  String get validationError;

  /// No description provided for @conflictError.
  ///
  /// In en, this message translates to:
  /// **'The request conflicts with the current data.'**
  String get conflictError;

  /// No description provided for @rateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again.'**
  String get rateLimitError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'The server encountered a problem. Please try again.'**
  String get serverError;

  /// No description provided for @invalidResponseError.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid response.'**
  String get invalidResponseError;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get requestCancelled;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch theme'**
  String get switchTheme;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get switchLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route {routeName} was not found.'**
  String routeNotFound(String routeName);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
