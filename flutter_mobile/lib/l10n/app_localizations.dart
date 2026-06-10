import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

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
    Locale('hi'),
    Locale('te')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MEDCLUES'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your health, connected'**
  String get appTagline;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get languageTelugu;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get languageSelectHint;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get commonNoInternet;

  /// No description provided for @commonServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error, please try again'**
  String get commonServerError;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to your account'**
  String get authSignInTitle;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authHaveAccount;

  /// No description provided for @authLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginLink;

  /// No description provided for @authUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get authUser;

  /// No description provided for @authUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book appointments & view your health records'**
  String get authUserSubtitle;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authCreatePassword;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhone;

  /// No description provided for @authDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get authDateOfBirth;

  /// No description provided for @authSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get authSelectDob;

  /// No description provided for @authGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get authGender;

  /// No description provided for @authTermsAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get authTermsAgree;

  /// No description provided for @authSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MEDCLUES!'**
  String get authSignupSuccess;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset OTP'**
  String get authForgotSubtitle;

  /// No description provided for @authSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authSendOtp;

  /// No description provided for @authOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get authOtp;

  /// No description provided for @authOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get authOtpHint;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get authNewPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled'**
  String get authSignInCancelled;

  /// No description provided for @authGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleSignIn;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationEmailMax.
  ///
  /// In en, this message translates to:
  /// **'Email must not exceed 100 characters'**
  String get validationEmailMax;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordMin;

  /// No description provided for @validationPasswordMax.
  ///
  /// In en, this message translates to:
  /// **'Password must not exceed 32 characters'**
  String get validationPasswordMax;

  /// No description provided for @validationPasswordUpper.
  ///
  /// In en, this message translates to:
  /// **'Include at least 1 uppercase letter'**
  String get validationPasswordUpper;

  /// No description provided for @validationPasswordLower.
  ///
  /// In en, this message translates to:
  /// **'Include at least 1 lowercase letter'**
  String get validationPasswordLower;

  /// No description provided for @validationPasswordNumber.
  ///
  /// In en, this message translates to:
  /// **'Include at least 1 number'**
  String get validationPasswordNumber;

  /// No description provided for @validationPasswordSpecial.
  ///
  /// In en, this message translates to:
  /// **'Include at least 1 special character'**
  String get validationPasswordSpecial;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @validationOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'OTP is required'**
  String get validationOtpRequired;

  /// No description provided for @validationOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP'**
  String get validationOtpInvalid;

  /// No description provided for @validationPatientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Patient name is required'**
  String get validationPatientNameRequired;

  /// No description provided for @validationNameMin2.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get validationNameMin2;

  /// No description provided for @validationNameMax50.
  ///
  /// In en, this message translates to:
  /// **'Name must not exceed 50 characters'**
  String get validationNameMax50;

  /// No description provided for @validationNameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Use letters and spaces only'**
  String get validationNameLettersOnly;

  /// No description provided for @validationDoctorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Doctor name is required'**
  String get validationDoctorNameRequired;

  /// No description provided for @validationNameMin3.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get validationNameMin3;

  /// No description provided for @validationNameMax60.
  ///
  /// In en, this message translates to:
  /// **'Name must not exceed 60 characters'**
  String get validationNameMax60;

  /// No description provided for @validationAgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get validationAgeRequired;

  /// No description provided for @validationAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid age.'**
  String get validationAgeInvalid;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact number is required'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get validationPhoneInvalid;

  /// No description provided for @validationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String validationFieldRequired(String label);

  /// No description provided for @validationAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get validationAddressRequired;

  /// No description provided for @validationAddressMax.
  ///
  /// In en, this message translates to:
  /// **'Address must not exceed 250 characters'**
  String get validationAddressMax;

  /// No description provided for @validationAddressChars.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, comma, hyphen, or slash only'**
  String get validationAddressChars;

  /// No description provided for @validationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get validationReasonRequired;

  /// No description provided for @validationReasonMin.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least 5 characters'**
  String get validationReasonMin;

  /// No description provided for @validationReasonMax.
  ///
  /// In en, this message translates to:
  /// **'Reason must not exceed 500 characters'**
  String get validationReasonMax;

  /// No description provided for @validationReportTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Report title is required'**
  String get validationReportTitleRequired;

  /// No description provided for @validationTitleMin3.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 3 characters'**
  String get validationTitleMin3;

  /// No description provided for @validationTitleMax100.
  ///
  /// In en, this message translates to:
  /// **'Title must not exceed 100 characters'**
  String get validationTitleMax100;

  /// No description provided for @validationEmergencyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact name is required'**
  String get validationEmergencyNameRequired;

  /// No description provided for @validationDobInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date of birth'**
  String get validationDobInvalid;

  /// No description provided for @validationDobFuture.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future'**
  String get validationDobFuture;

  /// No description provided for @validationAgeDobMismatch.
  ///
  /// In en, this message translates to:
  /// **'Age does not match date of birth'**
  String get validationAgeDobMismatch;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNotToSay;

  /// No description provided for @relationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationshipFather;

  /// No description provided for @relationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationshipMother;

  /// No description provided for @relationshipBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relationshipBrother;

  /// No description provided for @relationshipSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relationshipSister;

  /// No description provided for @relationshipSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationshipSpouse;

  /// No description provided for @relationshipSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get relationshipSon;

  /// No description provided for @relationshipDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get relationshipDaughter;

  /// No description provided for @relationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get relationshipGuardian;

  /// No description provided for @relationshipFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationshipFriend;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @relationshipSelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get relationshipSelf;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone dark mode setting.'**
  String get settingsThemeSystemHint;

  /// No description provided for @settingsThemeDarkHint.
  ///
  /// In en, this message translates to:
  /// **'Dark theme (true black) is on.'**
  String get settingsThemeDarkHint;

  /// No description provided for @settingsThemeLightHint.
  ///
  /// In en, this message translates to:
  /// **'Light theme is on.'**
  String get settingsThemeLightHint;

  /// No description provided for @settingsEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Settings'**
  String get settingsEmergency;

  /// No description provided for @settingsEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts, medical info & SOS preferences'**
  String get settingsEmergencySubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get dashboardGreeting;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search doctors, hospitals…'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardTopDoctors.
  ///
  /// In en, this message translates to:
  /// **'Top Doctors'**
  String get dashboardTopDoctors;

  /// No description provided for @dashboardSpecialities.
  ///
  /// In en, this message translates to:
  /// **'Specialities'**
  String get dashboardSpecialities;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @dashboardHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get dashboardHospitals;

  /// No description provided for @dashboardLabs.
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get dashboardLabs;

  /// No description provided for @dashboardBloodBanks.
  ///
  /// In en, this message translates to:
  /// **'Blood Banks'**
  String get dashboardBloodBanks;

  /// No description provided for @bookingWhoIsItFor.
  ///
  /// In en, this message translates to:
  /// **'Who is this for?'**
  String get bookingWhoIsItFor;

  /// No description provided for @bookingSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option to continue booking'**
  String get bookingSelectOption;

  /// No description provided for @bookingForMyself.
  ///
  /// In en, this message translates to:
  /// **'Book for Myself'**
  String get bookingForMyself;

  /// No description provided for @bookingForMyselfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use my profile details'**
  String get bookingForMyselfSubtitle;

  /// No description provided for @bookingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Book for Someone Else'**
  String get bookingForOthers;

  /// No description provided for @bookingForOthersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter patient details'**
  String get bookingForOthersSubtitle;

  /// No description provided for @bookingPatientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get bookingPatientDetails;

  /// No description provided for @bookingPatientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get bookingPatientName;

  /// No description provided for @bookingAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get bookingAge;

  /// No description provided for @bookingSelectAge.
  ///
  /// In en, this message translates to:
  /// **'Select Age'**
  String get bookingSelectAge;

  /// No description provided for @bookingContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get bookingContactNumber;

  /// No description provided for @bookingRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get bookingRelationship;

  /// No description provided for @bookingCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first'**
  String get bookingCompleteProfile;

  /// No description provided for @bookingSelectSymptom.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one symptom'**
  String get bookingSelectSymptom;

  /// No description provided for @bookingOnlineOthersPayment.
  ///
  /// In en, this message translates to:
  /// **'Online payment: book for yourself, or choose Pay at clinic for others.'**
  String get bookingOnlineOthersPayment;

  /// No description provided for @bookingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment Booked Successfully!'**
  String get bookingSuccess;

  /// No description provided for @bookingPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get bookingPaymentSuccess;

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsTitle;

  /// No description provided for @appointmentsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get appointmentsUpcoming;

  /// No description provided for @appointmentsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get appointmentsCompleted;

  /// No description provided for @appointmentsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentsCancelled;

  /// No description provided for @appointmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet'**
  String get appointmentsEmpty;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get recordsTitle;

  /// No description provided for @recordsUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Report'**
  String get recordsUpload;

  /// No description provided for @recordsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Report Title'**
  String get recordsTitleLabel;

  /// No description provided for @recordsTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter report title'**
  String get recordsTitleHint;

  /// No description provided for @recordsType.
  ///
  /// In en, this message translates to:
  /// **'Record Type'**
  String get recordsType;

  /// No description provided for @recordsUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reports uploaded successfully'**
  String get recordsUploadSuccess;

  /// No description provided for @recordsLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get recordsLoginRequired;

  /// No description provided for @recordsEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a report title'**
  String get recordsEnterTitle;

  /// No description provided for @recordsMaxSize.
  ///
  /// In en, this message translates to:
  /// **'max 10MB each'**
  String get recordsMaxSize;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileAddress;

  /// No description provided for @profilePayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get profilePayments;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelp;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyTitle;

  /// No description provided for @emergencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get emergencyHelp;

  /// No description provided for @emergencySettings.
  ///
  /// In en, this message translates to:
  /// **'Emergency Settings'**
  String get emergencySettings;

  /// No description provided for @emergencySave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get emergencySave;

  /// No description provided for @emergencySaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get emergencySaved;

  /// No description provided for @emergencyContact1.
  ///
  /// In en, this message translates to:
  /// **'Contact 1'**
  String get emergencyContact1;

  /// No description provided for @emergencyContact2.
  ///
  /// In en, this message translates to:
  /// **'Contact 2'**
  String get emergencyContact2;

  /// No description provided for @emergencyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emergencyName;

  /// No description provided for @emergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get emergencyPhone;

  /// No description provided for @emergencyRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get emergencyRelation;

  /// No description provided for @emergencyBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get emergencyBloodGroup;

  /// No description provided for @emergencyAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get emergencyAllergies;

  /// No description provided for @emergencyConditions.
  ///
  /// In en, this message translates to:
  /// **'Medical Conditions'**
  String get emergencyConditions;

  /// No description provided for @emergencyMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get emergencyMedications;

  /// No description provided for @emergencyAutoSos.
  ///
  /// In en, this message translates to:
  /// **'Auto-SOS Timer'**
  String get emergencyAutoSos;

  /// No description provided for @emergencyCritical.
  ///
  /// In en, this message translates to:
  /// **'I Am Critical'**
  String get emergencyCritical;

  /// No description provided for @emergencyRespond.
  ///
  /// In en, this message translates to:
  /// **'I Can Respond'**
  String get emergencyRespond;

  /// No description provided for @emergencyHelpOthers.
  ///
  /// In en, this message translates to:
  /// **'Help Someone Else'**
  String get emergencyHelpOthers;

  /// No description provided for @emergencyCallAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Call Ambulance (108)'**
  String get emergencyCallAmbulance;

  /// No description provided for @emergencyTestingBlocked.
  ///
  /// In en, this message translates to:
  /// **'Emergency calls are disabled in test mode'**
  String get emergencyTestingBlocked;

  /// No description provided for @doctorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get doctorsEmpty;

  /// No description provided for @doctorsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search doctors'**
  String get doctorsSearch;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @videoConsultTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Consultation'**
  String get videoConsultTitle;

  /// No description provided for @videoConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to doctor…'**
  String get videoConnecting;

  /// No description provided for @videoWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for doctor to join'**
  String get videoWaiting;

  /// No description provided for @videoEndCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get videoEndCall;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingWelcome;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingComplete;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @emptyDoctors.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get emptyDoctors;

  /// No description provided for @emptyResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptyResults;

  /// No description provided for @authOtpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your email'**
  String get authOtpSent;

  /// No description provided for @authPasswordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get authPasswordResetSuccess;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authBackToLogin;

  /// No description provided for @authEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEnterValidEmail;

  /// No description provided for @authStepPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get authStepPersonalInfo;

  /// No description provided for @authStepContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get authStepContactInfo;

  /// No description provided for @authStepSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & Verification'**
  String get authStepSecurity;

  /// No description provided for @authStepSuccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get authStepSuccessLabel;

  /// No description provided for @authTellAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get authTellAboutYourself;

  /// No description provided for @authHowReachYou.
  ///
  /// In en, this message translates to:
  /// **'How can we reach you?'**
  String get authHowReachYou;

  /// No description provided for @authSecureAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get authSecureAccount;

  /// No description provided for @authEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authEnterFullName;

  /// No description provided for @authEnterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authEnterPhoneHint;

  /// No description provided for @authSelectDobHint.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get authSelectDobHint;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Taking you to your dashboard…'**
  String get authWelcomeSubtitle;

  /// No description provided for @authAcceptTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please accept Terms & Conditions'**
  String get authAcceptTermsError;

  /// No description provided for @authSelectGenderError.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get authSelectGenderError;

  /// No description provided for @authSelectDobError.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get authSelectDobError;

  /// No description provided for @authEnterFullNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authEnterFullNameError;

  /// No description provided for @emergencyMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Medical Info'**
  String get emergencyMedicalInfo;

  /// No description provided for @emergencySosPreferences.
  ///
  /// In en, this message translates to:
  /// **'SOS Preferences'**
  String get emergencySosPreferences;

  /// No description provided for @emergencyDefaultNumbers.
  ///
  /// In en, this message translates to:
  /// **'Default Emergency Numbers'**
  String get emergencyDefaultNumbers;

  /// No description provided for @emergencyAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get emergencyAmbulance;

  /// No description provided for @emergencyPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get emergencyPolice;

  /// No description provided for @emergencyFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get emergencyFire;

  /// No description provided for @emergencyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get emergencyNameRequired;

  /// No description provided for @emergencyPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone *'**
  String get emergencyPhoneRequired;

  /// No description provided for @emergencyRelationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Spouse'**
  String get emergencyRelationHint;

  /// No description provided for @emergencyVoiceSos.
  ///
  /// In en, this message translates to:
  /// **'Voice SOS'**
  String get emergencyVoiceSos;

  /// No description provided for @emergencyVoiceSosDesc.
  ///
  /// In en, this message translates to:
  /// **'Trigger SOS with voice command'**
  String get emergencyVoiceSosDesc;

  /// No description provided for @emergencyTripleTap.
  ///
  /// In en, this message translates to:
  /// **'Triple Tap SOS'**
  String get emergencyTripleTap;

  /// No description provided for @emergencyTripleTapDesc.
  ///
  /// In en, this message translates to:
  /// **'Triple-tap power button pattern'**
  String get emergencyTripleTapDesc;

  /// No description provided for @emergencyShakeSos.
  ///
  /// In en, this message translates to:
  /// **'Shake SOS'**
  String get emergencyShakeSos;

  /// No description provided for @emergencyShakeSosDesc.
  ///
  /// In en, this message translates to:
  /// **'Shake device to trigger SOS'**
  String get emergencyShakeSosDesc;

  /// No description provided for @emergencyAutoLocationSharing.
  ///
  /// In en, this message translates to:
  /// **'Auto Location Sharing'**
  String get emergencyAutoLocationSharing;

  /// No description provided for @emergencyAutoLocationSharingDesc.
  ///
  /// In en, this message translates to:
  /// **'Share GPS when SOS activates'**
  String get emergencyAutoLocationSharingDesc;

  /// No description provided for @emergencyAutoSosTimerDesc.
  ///
  /// In en, this message translates to:
  /// **'Countdown before automatic SOS ({seconds}s)'**
  String emergencyAutoSosTimerDesc(int seconds);

  /// No description provided for @emergencyBloodGroupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. O+'**
  String get emergencyBloodGroupHint;

  /// No description provided for @emergencyExistingDiseases.
  ///
  /// In en, this message translates to:
  /// **'Existing Diseases'**
  String get emergencyExistingDiseases;

  /// No description provided for @bookingBookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookingBookAppointment;

  /// No description provided for @bookingBookVideoConsult.
  ///
  /// In en, this message translates to:
  /// **'Book Video Consultation'**
  String get bookingBookVideoConsult;

  /// No description provided for @bookingSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get bookingSelectDate;

  /// No description provided for @bookingVideoSlots.
  ///
  /// In en, this message translates to:
  /// **'Video Consultation Slots'**
  String get bookingVideoSlots;

  /// No description provided for @bookingOpdSlots.
  ///
  /// In en, this message translates to:
  /// **'OPD Time Slots'**
  String get bookingOpdSlots;

  /// No description provided for @bookingAppointmentsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments left'**
  String bookingAppointmentsLeft(int count);

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'MEDCLUES needs these permissions for appointments, emergency help, video consult, and file uploads.'**
  String get permissionsSubtitle;

  /// No description provided for @permissionsNativeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Continue — your phone will show real Allow / Deny dialogs one by one (like other apps).'**
  String get permissionsNativeHint;

  /// No description provided for @permissionsWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {permission}…'**
  String permissionsWaitingFor(String permission);

  /// No description provided for @permissionsUseSystemDialog.
  ///
  /// In en, this message translates to:
  /// **'Choose Allow, While using the app, or Only this time on the system popup.'**
  String get permissionsUseSystemDialog;

  /// No description provided for @permissionsPleaseRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond on system popup…'**
  String get permissionsPleaseRespond;

  /// No description provided for @permissionsStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String permissionsStepOf(int current, int total);

  /// No description provided for @permissionsMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionsMicrophone;

  /// No description provided for @permissionsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionsNotifications;

  /// No description provided for @permissionsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Appointment reminders and updates when the app is closed'**
  String get permissionsNotificationsHint;

  /// No description provided for @permissionsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionsLocation;

  /// No description provided for @permissionsLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby hospitals and emergency SOS'**
  String get permissionsLocationHint;

  /// No description provided for @permissionsFiles.
  ///
  /// In en, this message translates to:
  /// **'Files & photos'**
  String get permissionsFiles;

  /// No description provided for @permissionsFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Upload medical reports and health records'**
  String get permissionsFilesHint;

  /// No description provided for @permissionsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera & microphone'**
  String get permissionsCamera;

  /// No description provided for @permissionsCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Video consultation with your doctor'**
  String get permissionsCameraHint;

  /// No description provided for @permissionsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get permissionsPhone;

  /// No description provided for @permissionsPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Call ambulance and emergency contacts'**
  String get permissionsPhoneHint;

  /// No description provided for @permissionsAllowContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow & continue'**
  String get permissionsAllowContinue;

  /// No description provided for @permissionsLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionsLater;

  /// No description provided for @settingsTelegramTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Telegram'**
  String get settingsTelegramTitle;

  /// No description provided for @settingsTelegramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get appointments & records in Telegram (works with Google login)'**
  String get settingsTelegramSubtitle;

  /// No description provided for @settingsTelegramConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Telegram'**
  String get settingsTelegramConnect;

  /// No description provided for @settingsTelegramConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsTelegramConnected;

  /// No description provided for @settingsTelegramOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Telegram'**
  String get settingsTelegramOpenFailed;

  /// No description provided for @settingsTelegramInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Telegram'**
  String get settingsTelegramInstallTitle;

  /// No description provided for @settingsTelegramInstallBody.
  ///
  /// In en, this message translates to:
  /// **'Telegram is not installed on this device. Install it from the Play Store or App Store, then tap Connect Telegram again.'**
  String get settingsTelegramInstallBody;

  /// No description provided for @settingsTelegramGetApp.
  ///
  /// In en, this message translates to:
  /// **'Download Telegram'**
  String get settingsTelegramGetApp;

  /// No description provided for @settingsTelegramServerPending.
  ///
  /// In en, this message translates to:
  /// **'Opened Telegram bot. If linking fails, update the app server and try again.'**
  String get settingsTelegramServerPending;

  /// No description provided for @recordsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening report…'**
  String get recordsOpening;

  /// No description provided for @recordsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open report. Allow pop-ups or try again.'**
  String get recordsOpenFailed;

  /// No description provided for @appointmentsAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Google Calendar'**
  String get appointmentsAddToCalendar;

  /// No description provided for @appointmentsCalendarAdded.
  ///
  /// In en, this message translates to:
  /// **'Opening calendar…'**
  String get appointmentsCalendarAdded;

  /// No description provided for @appointmentsCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add to calendar'**
  String get appointmentsCalendarFailed;

  /// No description provided for @bookingSlotFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get bookingSlotFull;

  /// No description provided for @bookingNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No available slots for this date'**
  String get bookingNoSlots;

  /// No description provided for @bookingPaymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get bookingPaymentMode;

  /// No description provided for @bookingInClinic.
  ///
  /// In en, this message translates to:
  /// **'In-clinic'**
  String get bookingInClinic;

  /// No description provided for @bookingPayOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay Online'**
  String get bookingPayOnline;

  /// No description provided for @bookingPayOnlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now via Razorpay before your visit.'**
  String bookingPayOnlineBanner(String amount);

  /// No description provided for @bookingInClinicPayHint.
  ///
  /// In en, this message translates to:
  /// **'In-clinic visits: pay at the hospital reception.'**
  String get bookingInClinicPayHint;

  /// No description provided for @bookingVideoFeeRequired.
  ///
  /// In en, this message translates to:
  /// **'Video consultation fee: {amount}. Payment via Razorpay is required.'**
  String bookingVideoFeeRequired(String amount);

  /// No description provided for @bookingConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get bookingConfirming;

  /// No description provided for @bookingPayAndBook.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} & Book'**
  String bookingPayAndBook(String amount);

  /// No description provided for @bookingSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get bookingSelectDateTime;

  /// No description provided for @bookingAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)'**
  String get bookingAdditionalNotes;

  /// No description provided for @bookingUploadReport.
  ///
  /// In en, this message translates to:
  /// **'Upload medical report (optional)'**
  String get bookingUploadReport;

  /// No description provided for @bookingReportAttached.
  ///
  /// In en, this message translates to:
  /// **'Report attached'**
  String get bookingReportAttached;

  /// No description provided for @bookingPickReport.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick PDF or image'**
  String get bookingPickReport;

  /// No description provided for @bookingConsultationWith.
  ///
  /// In en, this message translates to:
  /// **'Consultation with {doctor}'**
  String bookingConsultationWith(String doctor);

  /// No description provided for @paymentWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get paymentWaitingTitle;

  /// No description provided for @paymentOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order: {orderId}'**
  String paymentOrderLabel(String orderId);

  /// No description provided for @paymentTapIvePaidHint.
  ///
  /// In en, this message translates to:
  /// **'After \"Payment successful\" on Razorpay, tap I\'ve paid below.'**
  String get paymentTapIvePaidHint;

  /// No description provided for @paymentIvePaid.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid'**
  String get paymentIvePaid;

  /// No description provided for @paymentCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get paymentCompleteTitle;

  /// No description provided for @paymentCompleteBrowserHint.
  ///
  /// In en, this message translates to:
  /// **'Finish payment in the browser tab, then paste Razorpay details below.'**
  String get paymentCompleteBrowserHint;

  /// No description provided for @paymentCompleteAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Payment status: {status}\n\nFinish payment in the Razorpay tab. The app checks automatically; use manual verify only if needed.'**
  String paymentCompleteAutoHint(String status);

  /// No description provided for @paymentVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get paymentVerify;

  /// No description provided for @paymentPaymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get paymentPaymentId;

  /// No description provided for @paymentSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get paymentSignature;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed at Razorpay'**
  String get paymentFailed;

  /// No description provided for @paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed yet. Finish payment in Razorpay checkout.'**
  String get paymentNotCompleted;

  /// No description provided for @paymentFinishThenTap.
  ///
  /// In en, this message translates to:
  /// **'Finish payment in Razorpay, then tap I\'ve paid.'**
  String get paymentFinishThenTap;

  /// No description provided for @paymentConfirmingBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirming booking… {message}'**
  String paymentConfirmingBooking(String message);

  /// No description provided for @paymentCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open payment page. Check your connection.'**
  String get paymentCouldNotOpen;

  /// No description provided for @appointmentsMyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get appointmentsMyTitle;

  /// No description provided for @appointmentsNoTitle.
  ///
  /// In en, this message translates to:
  /// **'No appointments'**
  String get appointmentsNoTitle;

  /// No description provided for @appointmentsNoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a new appointment to get started.'**
  String get appointmentsNoSubtitle;

  /// No description provided for @appointmentsCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get appointmentsCancelledSuccess;

  /// No description provided for @appointmentsDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentsDetailsTitle;

  /// No description provided for @appointmentsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get appointmentsCancel;

  /// No description provided for @appointmentsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get appointmentsDate;

  /// No description provided for @appointmentsTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get appointmentsTime;

  /// No description provided for @appointmentsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get appointmentsDoctor;

  /// No description provided for @appointmentsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get appointmentsStatus;

  /// No description provided for @appointmentsPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get appointmentsPatient;

  /// No description provided for @doctorsRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get doctorsRecentSearches;

  /// No description provided for @doctorsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get doctorsNoResults;

  /// No description provided for @doctorExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get doctorExperience;

  /// No description provided for @doctorFees.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get doctorFees;

  /// No description provided for @doctorAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get doctorAbout;

  /// No description provided for @doctorBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get doctorBookNow;

  /// No description provided for @doctorVideoConsult.
  ///
  /// In en, this message translates to:
  /// **'Video Consult'**
  String get doctorVideoConsult;

  /// No description provided for @doctorInClinicVisit.
  ///
  /// In en, this message translates to:
  /// **'In-clinic Visit'**
  String get doctorInClinicVisit;

  /// No description provided for @doctorShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get doctorShare;

  /// No description provided for @doctorEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get doctorEducation;

  /// No description provided for @doctorAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get doctorAvailability;

  /// No description provided for @doctorAvailabilityDays.
  ///
  /// In en, this message translates to:
  /// **'Days: Mon - Sat'**
  String get doctorAvailabilityDays;

  /// No description provided for @doctorAvailabilityTime.
  ///
  /// In en, this message translates to:
  /// **'Time: 10:00 AM - 06:00 PM'**
  String get doctorAvailabilityTime;

  /// No description provided for @doctorsFilterAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get doctorsFilterAvailable;

  /// No description provided for @doctorsFilterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get doctorsFilterRating;

  /// No description provided for @doctorYearsExp.
  ///
  /// In en, this message translates to:
  /// **'{years}+ years'**
  String doctorYearsExp(String years);

  /// No description provided for @videoConsult.
  ///
  /// In en, this message translates to:
  /// **'Video Consult'**
  String get videoConsult;

  /// No description provided for @videoGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get videoGoBack;

  /// No description provided for @videoMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get videoMute;

  /// No description provided for @videoUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get videoUnmute;

  /// No description provided for @videoCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get videoCameraOn;

  /// No description provided for @videoCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get videoCameraOff;

  /// No description provided for @videoEndConsult.
  ///
  /// In en, this message translates to:
  /// **'End consultation'**
  String get videoEndConsult;

  /// No description provided for @videoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permissions are required'**
  String get videoPermissionDenied;

  /// No description provided for @videoWaitingDoctor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for doctor…'**
  String get videoWaitingDoctor;

  /// No description provided for @videoConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get videoConnected;

  /// No description provided for @videoChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get videoChannel;

  /// No description provided for @onboardingStep8of8.
  ///
  /// In en, this message translates to:
  /// **'Step 8/8'**
  String get onboardingStep8of8;

  /// No description provided for @onboardingCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get onboardingCompleteProfile;

  /// No description provided for @onboardingCompleteProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your details so doctors can serve you better.'**
  String get onboardingCompleteProfileDesc;

  /// No description provided for @onboardingCompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get onboardingCompleteSetup;

  /// No description provided for @onboardingSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get onboardingSaveContinue;

  /// No description provided for @onboardingEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get onboardingEmergencyContact;

  /// No description provided for @onboardingEmergencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add one person we can alert in an emergency.'**
  String get onboardingEmergencyDesc;

  /// No description provided for @onboardingEmergencySecondLater.
  ///
  /// In en, this message translates to:
  /// **'You can add a second contact later in Emergency settings.'**
  String get onboardingEmergencySecondLater;

  /// No description provided for @onboardingStartUsing.
  ///
  /// In en, this message translates to:
  /// **'Start Using MEDCLUES'**
  String get onboardingStartUsing;

  /// No description provided for @onboardingAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to go!'**
  String get onboardingAllSet;

  /// No description provided for @tourHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tourHomeTitle;

  /// No description provided for @tourHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Search doctors, hospitals, and quick actions.'**
  String get tourHomeDesc;

  /// No description provided for @tourHospitalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get tourHospitalsTitle;

  /// No description provided for @tourHospitalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Find nearby hospitals and details.'**
  String get tourHospitalsDesc;

  /// No description provided for @tourDoctorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get tourDoctorsTitle;

  /// No description provided for @tourDoctorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse specialists and book appointments.'**
  String get tourDoctorsDesc;

  /// No description provided for @tourAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get tourAppointmentsTitle;

  /// No description provided for @tourAppointmentsDesc.
  ///
  /// In en, this message translates to:
  /// **'View upcoming and past visits.'**
  String get tourAppointmentsDesc;

  /// No description provided for @tourRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get tourRecordsTitle;

  /// No description provided for @tourRecordsDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload and access your health reports.'**
  String get tourRecordsDesc;

  /// No description provided for @tourEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get tourEmergencyTitle;

  /// No description provided for @tourEmergencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick SOS and emergency contacts.'**
  String get tourEmergencyDesc;

  /// No description provided for @emergencyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Active'**
  String get emergencyActiveTitle;

  /// No description provided for @emergencyCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not place {label} call'**
  String emergencyCallFailed(String label);

  /// No description provided for @emergencyNoRelatives.
  ///
  /// In en, this message translates to:
  /// **'No relatives saved — shared via system sheet'**
  String get emergencyNoRelatives;

  /// No description provided for @emergencyShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share live location'**
  String get emergencyShareLocation;

  /// No description provided for @emergencyNearbyHospitals.
  ///
  /// In en, this message translates to:
  /// **'Nearby hospitals'**
  String get emergencyNearbyHospitals;

  /// No description provided for @emergencyBookConsultation.
  ///
  /// In en, this message translates to:
  /// **'Book consultation'**
  String get emergencyBookConsultation;

  /// No description provided for @emergencyConnectDoctors.
  ///
  /// In en, this message translates to:
  /// **'Connect to available doctors'**
  String get emergencyConnectDoctors;

  /// No description provided for @emergencyWhatsappAlert.
  ///
  /// In en, this message translates to:
  /// **'Send alert & live location link via WhatsApp'**
  String get emergencyWhatsappAlert;

  /// No description provided for @emergencyScheduleVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule a non-emergency visit'**
  String get emergencyScheduleVisit;

  /// No description provided for @emergencyCallPoliceBtn.
  ///
  /// In en, this message translates to:
  /// **'Call Police'**
  String get emergencyCallPoliceBtn;

  /// No description provided for @emergencyCallFireBtn.
  ///
  /// In en, this message translates to:
  /// **'Call Fire'**
  String get emergencyCallFireBtn;

  /// No description provided for @emergencyAccessCountdown.
  ///
  /// In en, this message translates to:
  /// **'Auto-SOS in {seconds}s'**
  String emergencyAccessCountdown(int seconds);

  /// No description provided for @emergencyCancelSos.
  ///
  /// In en, this message translates to:
  /// **'Cancel SOS'**
  String get emergencyCancelSos;

  /// No description provided for @emergencySelectSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Select your symptoms'**
  String get emergencySelectSymptoms;

  /// No description provided for @emergencySeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get emergencySeverityCritical;

  /// No description provided for @emergencySeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get emergencySeverityModerate;

  /// No description provided for @emergencySeverityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get emergencySeverityMinor;

  /// No description provided for @receiptAppointmentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Appointment Receipt'**
  String get receiptAppointmentReceipt;

  /// No description provided for @receiptConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get receiptConfirmed;

  /// No description provided for @receiptPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get receiptPatient;

  /// No description provided for @receiptDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get receiptDoctor;

  /// No description provided for @receiptSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get receiptSpecialization;

  /// No description provided for @receiptHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get receiptHospital;

  /// No description provided for @receiptLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get receiptLocation;

  /// No description provided for @receiptDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get receiptDateTime;

  /// No description provided for @receiptVisitType.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get receiptVisitType;

  /// No description provided for @receiptStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get receiptStatus;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receiptAmount;

  /// No description provided for @receiptToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get receiptToken;

  /// No description provided for @receiptBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get receiptBookingId;

  /// No description provided for @receiptGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get receiptGenerated;

  /// No description provided for @receiptStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get receiptStatusConfirmed;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancelEdit;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get profileBloodGroup;

  /// No description provided for @profileAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get profileAddressLine1;

  /// No description provided for @profileAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get profileAddressLine2;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get profileState;

  /// No description provided for @profilePincode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get profilePincode;

  /// No description provided for @addressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressTitle;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressSaved;

  /// No description provided for @recordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store and share your medical documents securely'**
  String get recordsSubtitle;

  /// No description provided for @recordsTypeLab.
  ///
  /// In en, this message translates to:
  /// **'Lab report'**
  String get recordsTypeLab;

  /// No description provided for @recordsTypePrescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get recordsTypePrescription;

  /// No description provided for @recordsTypeXray.
  ///
  /// In en, this message translates to:
  /// **'X-Ray / Scan'**
  String get recordsTypeXray;

  /// No description provided for @recordsTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get recordsTypeOther;

  /// No description provided for @recordsFileTypesHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, images, DOCX ({maxSize})'**
  String recordsFileTypesHint(String maxSize);

  /// No description provided for @recordsNoFile.
  ///
  /// In en, this message translates to:
  /// **'No file attached to this report'**
  String get recordsNoFile;

  /// No description provided for @recordsIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Report id missing — refresh and try again'**
  String get recordsIdMissing;

  /// No description provided for @recordsYourReports.
  ///
  /// In en, this message translates to:
  /// **'Your Reports'**
  String get recordsYourReports;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No health records yet'**
  String get recordsEmpty;

  /// No description provided for @recordsView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get recordsView;

  /// No description provided for @recordsEmptyUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload lab results, prescriptions, or scans above'**
  String get recordsEmptyUploadHint;

  /// No description provided for @recordsViewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get recordsViewReport;
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
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
