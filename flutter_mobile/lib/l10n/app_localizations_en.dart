// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MEDCLUES';

  @override
  String get appTagline => 'Your health, connected';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTelugu => 'Telugu';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageSelectHint => 'Choose app language';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOr => 'or';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonNoInternet => 'No internet connection';

  @override
  String get commonServerError => 'Server error, please try again';

  @override
  String get authSignInTitle => 'Sign in to continue to your account';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authRegister => 'Register';

  @override
  String get authEmail => 'Email Address';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authConfirmPasswordHint => 'Re-enter your password';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authLoginLink => 'Login';

  @override
  String get authUser => 'User';

  @override
  String get authUserSubtitle => 'Book appointments & view your health records';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authCreatePassword => 'Create a password';

  @override
  String get authFullName => 'Full Name';

  @override
  String get authPhone => 'Phone Number';

  @override
  String get authDateOfBirth => 'Date of Birth';

  @override
  String get authSelectDob => 'Select date of birth';

  @override
  String get authGender => 'Gender';

  @override
  String get authTermsAgree => 'I agree to the Terms & Conditions';

  @override
  String get authSignupSuccess => 'Welcome to MEDCLUES!';

  @override
  String get authForgotTitle => 'Forgot Password';

  @override
  String get authForgotSubtitle => 'Enter your email to receive a reset OTP';

  @override
  String get authSendOtp => 'Send OTP';

  @override
  String get authOtp => 'OTP';

  @override
  String get authOtpHint => 'Enter 6-digit OTP';

  @override
  String get authNewPassword => 'New Password';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authSignInCancelled => 'Sign-in cancelled';

  @override
  String get authGoogleSignIn => 'Continue with Google';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationEmailMax => 'Email must not exceed 100 characters';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordMin => 'Password must be at least 8 characters';

  @override
  String get validationPasswordMax => 'Password must not exceed 32 characters';

  @override
  String get validationPasswordUpper => 'Include at least 1 uppercase letter';

  @override
  String get validationPasswordLower => 'Include at least 1 lowercase letter';

  @override
  String get validationPasswordNumber => 'Include at least 1 number';

  @override
  String get validationPasswordSpecial =>
      'Include at least 1 special character';

  @override
  String get validationConfirmPassword => 'Please confirm your password';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationOtpRequired => 'OTP is required';

  @override
  String get validationOtpInvalid => 'Enter the 6-digit OTP';

  @override
  String get validationPatientNameRequired => 'Patient name is required';

  @override
  String get validationNameMin2 => 'Name must be at least 2 characters';

  @override
  String get validationNameMax50 => 'Name must not exceed 50 characters';

  @override
  String get validationNameLettersOnly => 'Use letters and spaces only';

  @override
  String get validationDoctorNameRequired => 'Doctor name is required';

  @override
  String get validationNameMin3 => 'Name must be at least 3 characters';

  @override
  String get validationNameMax60 => 'Name must not exceed 60 characters';

  @override
  String get validationAgeRequired => 'Age is required';

  @override
  String get validationAgeInvalid => 'Please select a valid age.';

  @override
  String get validationPhoneRequired => 'Contact number is required';

  @override
  String get validationPhoneInvalid => 'Enter a valid 10-digit mobile number';

  @override
  String validationFieldRequired(String label) {
    return '$label is required';
  }

  @override
  String get validationAddressRequired => 'Address is required';

  @override
  String get validationAddressMax => 'Address must not exceed 250 characters';

  @override
  String get validationAddressChars =>
      'Use letters, numbers, comma, hyphen, or slash only';

  @override
  String get validationReasonRequired => 'Reason is required';

  @override
  String get validationReasonMin => 'Reason must be at least 5 characters';

  @override
  String get validationReasonMax => 'Reason must not exceed 500 characters';

  @override
  String get validationReportTitleRequired => 'Report title is required';

  @override
  String get validationTitleMin3 => 'Title must be at least 3 characters';

  @override
  String get validationTitleMax100 => 'Title must not exceed 100 characters';

  @override
  String get validationEmergencyNameRequired => 'Contact name is required';

  @override
  String get validationDobInvalid => 'Enter a valid date of birth';

  @override
  String get validationDobFuture => 'Date of birth cannot be in the future';

  @override
  String get validationAgeDobMismatch => 'Age does not match date of birth';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get relationshipFather => 'Father';

  @override
  String get relationshipMother => 'Mother';

  @override
  String get relationshipBrother => 'Brother';

  @override
  String get relationshipSister => 'Sister';

  @override
  String get relationshipSpouse => 'Spouse';

  @override
  String get relationshipSon => 'Son';

  @override
  String get relationshipDaughter => 'Daughter';

  @override
  String get relationshipGuardian => 'Guardian';

  @override
  String get relationshipFriend => 'Friend';

  @override
  String get relationshipOther => 'Other';

  @override
  String get relationshipSelf => 'Self';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystemHint => 'Follows your phone dark mode setting.';

  @override
  String get settingsThemeDarkHint => 'Dark theme (true black) is on.';

  @override
  String get settingsThemeLightHint => 'Light theme is on.';

  @override
  String get settingsEmergency => 'Emergency Settings';

  @override
  String get settingsEmergencySubtitle =>
      'Contacts, medical info & SOS preferences';

  @override
  String get navHome => 'Home';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get navRecords => 'Records';

  @override
  String get navProfile => 'Profile';

  @override
  String get dashboardGreeting => 'Hello';

  @override
  String get dashboardSearchHint => 'Search doctors, hospitals…';

  @override
  String get dashboardTopDoctors => 'Top Doctors';

  @override
  String get dashboardSpecialities => 'Specialities';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardHospitals => 'Hospitals';

  @override
  String get dashboardLabs => 'Labs';

  @override
  String get dashboardBloodBanks => 'Blood Banks';

  @override
  String get bookingWhoIsItFor => 'Who is this for?';

  @override
  String get bookingSelectOption => 'Select an option to continue booking';

  @override
  String get bookingForMyself => 'Book for Myself';

  @override
  String get bookingForMyselfSubtitle => 'Use my profile details';

  @override
  String get bookingForOthers => 'Book for Someone Else';

  @override
  String get bookingForOthersSubtitle => 'Enter patient details';

  @override
  String get bookingPatientDetails => 'Patient Details';

  @override
  String get bookingPatientName => 'Patient Name';

  @override
  String get bookingAge => 'Age';

  @override
  String get bookingSelectAge => 'Select Age';

  @override
  String get bookingContactNumber => 'Contact Number';

  @override
  String get bookingRelationship => 'Relationship';

  @override
  String get bookingCompleteProfile => 'Please complete your profile first';

  @override
  String get bookingSelectSymptom => 'Please select at least one symptom';

  @override
  String get bookingOnlineOthersPayment =>
      'Online payment: book for yourself, or choose Pay at clinic for others.';

  @override
  String get bookingSuccess => 'Appointment Booked Successfully!';

  @override
  String get bookingPaymentSuccess => 'Payment Successful';

  @override
  String get appointmentsTitle => 'Appointments';

  @override
  String get appointmentsUpcoming => 'Upcoming';

  @override
  String get appointmentsCompleted => 'Completed';

  @override
  String get appointmentsCancelled => 'Cancelled';

  @override
  String get appointmentsEmpty => 'No appointments yet';

  @override
  String get recordsTitle => 'Health Records';

  @override
  String get recordsUpload => 'Upload Report';

  @override
  String get recordsTitleLabel => 'Report Title';

  @override
  String get recordsTitleHint => 'Enter report title';

  @override
  String get recordsType => 'Record Type';

  @override
  String get recordsUploadSuccess => 'Reports uploaded successfully';

  @override
  String get recordsLoginRequired => 'Please log in';

  @override
  String get recordsEnterTitle => 'Enter a report title';

  @override
  String get recordsMaxSize => 'max 10MB each';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profileAddress => 'Address';

  @override
  String get profilePayments => 'Payments';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileHelp => 'Help & Support';

  @override
  String get profileAbout => 'About';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get emergencyTitle => 'Emergency';

  @override
  String get emergencyHelp => 'Emergency Help';

  @override
  String get emergencySettings => 'Emergency Settings';

  @override
  String get emergencySave => 'Save Settings';

  @override
  String get emergencySaved => 'Settings saved';

  @override
  String get emergencyContact1 => 'Contact 1';

  @override
  String get emergencyContact2 => 'Contact 2';

  @override
  String get emergencyName => 'Name';

  @override
  String get emergencyPhone => 'Phone';

  @override
  String get emergencyRelation => 'Relation';

  @override
  String get emergencyBloodGroup => 'Blood Group';

  @override
  String get emergencyAllergies => 'Allergies';

  @override
  String get emergencyConditions => 'Medical Conditions';

  @override
  String get emergencyMedications => 'Medications';

  @override
  String get emergencyAutoSos => 'Auto-SOS Timer';

  @override
  String get emergencyCritical => 'I Am Critical';

  @override
  String get emergencyRespond => 'I Can Respond';

  @override
  String get emergencyHelpOthers => 'Help Someone Else';

  @override
  String get emergencyCallAmbulance => 'Call Ambulance (108)';

  @override
  String get emergencyTestingBlocked =>
      'Emergency calls are disabled in test mode';

  @override
  String get doctorsEmpty => 'No doctors found';

  @override
  String get doctorsSearch => 'Search doctors';

  @override
  String get doctorProfile => 'Doctor Profile';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get videoConsultTitle => 'Video Consultation';

  @override
  String get videoConnecting => 'Connecting to doctor…';

  @override
  String get videoWaiting => 'Waiting for doctor to join';

  @override
  String get videoEndCall => 'End Call';

  @override
  String get onboardingWelcome => 'Welcome';

  @override
  String get onboardingComplete => 'You\'re all set!';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get emptyDoctors => 'No doctors found';

  @override
  String get emptyResults => 'No results found';

  @override
  String get authOtpSent => 'OTP sent to your email';

  @override
  String get authPasswordResetSuccess => 'Password reset successfully';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authEnterValidEmail => 'Enter a valid email';

  @override
  String get authStepPersonalInfo => 'Personal Information';

  @override
  String get authStepContactInfo => 'Contact Information';

  @override
  String get authStepSecurity => 'Security & Verification';

  @override
  String get authStepSuccessLabel => 'Success';

  @override
  String get authTellAboutYourself => 'Tell us about yourself';

  @override
  String get authHowReachYou => 'How can we reach you?';

  @override
  String get authSecureAccount => 'Secure your account';

  @override
  String get authEnterFullName => 'Enter your full name';

  @override
  String get authEnterPhoneHint => 'Enter your phone number';

  @override
  String get authSelectDobHint => 'Select your date of birth';

  @override
  String get authWelcomeSubtitle =>
      'Your account is ready. Taking you to your dashboard…';

  @override
  String get authAcceptTermsError => 'Please accept Terms & Conditions';

  @override
  String get authSelectGenderError => 'Select gender';

  @override
  String get authSelectDobError => 'Select date of birth';

  @override
  String get authEnterFullNameError => 'Enter your full name';

  @override
  String get emergencyMedicalInfo => 'Medical Info';

  @override
  String get emergencySosPreferences => 'SOS Preferences';

  @override
  String get emergencyDefaultNumbers => 'Default Emergency Numbers';

  @override
  String get emergencyAmbulance => 'Ambulance';

  @override
  String get emergencyPolice => 'Police';

  @override
  String get emergencyFire => 'Fire';

  @override
  String get emergencyNameRequired => 'Name *';

  @override
  String get emergencyPhoneRequired => 'Phone *';

  @override
  String get emergencyRelationHint => 'e.g. Spouse';

  @override
  String get emergencyVoiceSos => 'Voice SOS';

  @override
  String get emergencyVoiceSosDesc => 'Trigger SOS with voice command';

  @override
  String get emergencyTripleTap => 'Triple Tap SOS';

  @override
  String get emergencyTripleTapDesc => 'Triple-tap power button pattern';

  @override
  String get emergencyShakeSos => 'Shake SOS';

  @override
  String get emergencyShakeSosDesc => 'Shake device to trigger SOS';

  @override
  String get emergencyAutoLocationSharing => 'Auto Location Sharing';

  @override
  String get emergencyAutoLocationSharingDesc => 'Share GPS when SOS activates';

  @override
  String emergencyAutoSosTimerDesc(int seconds) {
    return 'Countdown before automatic SOS (${seconds}s)';
  }

  @override
  String get emergencyBloodGroupHint => 'e.g. O+';

  @override
  String get emergencyExistingDiseases => 'Existing Diseases';

  @override
  String get bookingBookAppointment => 'Book Appointment';

  @override
  String get bookingBookVideoConsult => 'Book Video Consultation';

  @override
  String get bookingSelectDate => 'Select Date';

  @override
  String get bookingVideoSlots => 'Video Consultation Slots';

  @override
  String get bookingOpdSlots => 'OPD Time Slots';

  @override
  String bookingAppointmentsLeft(int count) {
    return '$count appointments left';
  }

  @override
  String get permissionsTitle => 'Allow permissions';

  @override
  String get permissionsSubtitle =>
      'MEDCLUES needs these permissions for appointments, emergency help, video consult, and file uploads.';

  @override
  String get permissionsNativeHint =>
      'Tap Continue — your phone will show real Allow / Deny dialogs one by one (like other apps).';

  @override
  String permissionsWaitingFor(String permission) {
    return 'Waiting for $permission…';
  }

  @override
  String get permissionsUseSystemDialog =>
      'Choose Allow, While using the app, or Only this time on the system popup.';

  @override
  String get permissionsPleaseRespond => 'Respond on system popup…';

  @override
  String permissionsStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get permissionsMicrophone => 'Microphone';

  @override
  String get permissionsNotifications => 'Notifications';

  @override
  String get permissionsNotificationsHint =>
      'Appointment reminders and updates when the app is closed';

  @override
  String get permissionsLocation => 'Location';

  @override
  String get permissionsLocationHint => 'Nearby hospitals and emergency SOS';

  @override
  String get permissionsFiles => 'Files & photos';

  @override
  String get permissionsFilesHint =>
      'Upload medical reports and health records';

  @override
  String get permissionsCamera => 'Camera & microphone';

  @override
  String get permissionsCameraHint => 'Video consultation with your doctor';

  @override
  String get permissionsPhone => 'Phone';

  @override
  String get permissionsPhoneHint => 'Call ambulance and emergency contacts';

  @override
  String get permissionsAllowContinue => 'Allow & continue';

  @override
  String get permissionsLater => 'Not now';

  @override
  String get settingsTelegramTitle => 'Connect Telegram';

  @override
  String get settingsTelegramSubtitle =>
      'Get appointments & records in Telegram (works with Google login)';

  @override
  String get settingsTelegramConnect => 'Connect Telegram';

  @override
  String get settingsTelegramConnected => 'Connected';

  @override
  String get settingsTelegramOpenFailed => 'Could not open Telegram';

  @override
  String get settingsTelegramInstallTitle => 'Get Telegram';

  @override
  String get settingsTelegramInstallBody =>
      'Telegram is not installed on this device. Install it from the Play Store or App Store, then tap Connect Telegram again.';

  @override
  String get settingsTelegramGetApp => 'Download Telegram';

  @override
  String get settingsTelegramServerPending =>
      'Opened Telegram bot. If linking fails, update the app server and try again.';

  @override
  String get recordsOpening => 'Opening report…';

  @override
  String get recordsOpenFailed =>
      'Could not open report. Allow pop-ups or try again.';

  @override
  String get appointmentsAddToCalendar => 'Add to Google Calendar';

  @override
  String get appointmentsCalendarAdded => 'Opening calendar…';

  @override
  String get appointmentsCalendarFailed => 'Could not add to calendar';

  @override
  String get bookingSlotFull => 'Full';

  @override
  String get bookingNoSlots => 'No available slots for this date';

  @override
  String get bookingPaymentMode => 'Payment Mode';

  @override
  String get bookingInClinic => 'In-clinic';

  @override
  String get bookingPayOnline => 'Pay Online';

  @override
  String bookingPayOnlineBanner(String amount) {
    return 'Pay $amount now via Razorpay before your visit.';
  }

  @override
  String get bookingInClinicPayHint =>
      'In-clinic visits: pay at the hospital reception.';

  @override
  String bookingVideoFeeRequired(String amount) {
    return 'Video consultation fee: $amount. Payment via Razorpay is required.';
  }

  @override
  String get bookingConfirming => 'Confirming…';

  @override
  String bookingPayAndBook(String amount) {
    return 'Pay $amount & Book';
  }

  @override
  String get bookingSelectDateTime => 'Please select date and time';

  @override
  String get bookingAdditionalNotes => 'Additional notes (optional)';

  @override
  String get bookingUploadReport => 'Upload medical report (optional)';

  @override
  String get bookingReportAttached => 'Report attached';

  @override
  String get bookingPickReport => 'Tap to pick PDF or image';

  @override
  String bookingConsultationWith(String doctor) {
    return 'Consultation with $doctor';
  }

  @override
  String get paymentWaitingTitle => 'Waiting for payment';

  @override
  String paymentOrderLabel(String orderId) {
    return 'Order: $orderId';
  }

  @override
  String get paymentTapIvePaidHint =>
      'After \"Payment successful\" on Razorpay, tap I\'ve paid below.';

  @override
  String get paymentIvePaid => 'I\'ve paid';

  @override
  String get paymentCompleteTitle => 'Complete payment';

  @override
  String get paymentCompleteBrowserHint =>
      'Finish payment in the browser tab, then paste Razorpay details below.';

  @override
  String paymentCompleteAutoHint(String status) {
    return 'Payment status: $status\n\nFinish payment in the Razorpay tab. The app checks automatically; use manual verify only if needed.';
  }

  @override
  String get paymentVerify => 'Verify';

  @override
  String get paymentPaymentId => 'Payment ID';

  @override
  String get paymentSignature => 'Signature';

  @override
  String get paymentCancelled => 'Payment cancelled';

  @override
  String get paymentFailed => 'Payment failed at Razorpay';

  @override
  String get paymentNotCompleted =>
      'Payment not completed yet. Finish payment in Razorpay checkout.';

  @override
  String get paymentFinishThenTap =>
      'Finish payment in Razorpay, then tap I\'ve paid.';

  @override
  String paymentConfirmingBooking(String message) {
    return 'Confirming booking… $message';
  }

  @override
  String get paymentCouldNotOpen =>
      'Could not open payment page. Check your connection.';

  @override
  String get appointmentsMyTitle => 'My Appointments';

  @override
  String get appointmentsNoTitle => 'No appointments';

  @override
  String get appointmentsNoSubtitle => 'Book a new appointment to get started.';

  @override
  String get appointmentsCancelledSuccess => 'Appointment cancelled';

  @override
  String get appointmentsDetailsTitle => 'Appointment Details';

  @override
  String get appointmentsCancel => 'Cancel Appointment';

  @override
  String get appointmentsDate => 'Date';

  @override
  String get appointmentsTime => 'Time';

  @override
  String get appointmentsDoctor => 'Doctor';

  @override
  String get appointmentsStatus => 'Status';

  @override
  String get appointmentsPatient => 'Patient';

  @override
  String get doctorsRecentSearches => 'Recent searches';

  @override
  String get doctorsNoResults => 'No results';

  @override
  String get doctorExperience => 'Experience';

  @override
  String get doctorFees => 'Consultation Fee';

  @override
  String get doctorAbout => 'About';

  @override
  String get doctorBookNow => 'Book Now';

  @override
  String get doctorVideoConsult => 'Video Consult';

  @override
  String get doctorInClinicVisit => 'In-clinic Visit';

  @override
  String get doctorShare => 'Share';

  @override
  String get doctorEducation => 'Education';

  @override
  String get doctorAvailability => 'Availability';

  @override
  String get doctorAvailabilityDays => 'Days: Mon - Sat';

  @override
  String get doctorAvailabilityTime => 'Time: 10:00 AM - 06:00 PM';

  @override
  String get doctorsFilterAvailable => 'Available';

  @override
  String get doctorsFilterRating => 'Rating';

  @override
  String doctorYearsExp(String years) {
    return '$years+ years';
  }

  @override
  String get videoConsult => 'Video Consult';

  @override
  String get videoGoBack => 'Go back';

  @override
  String get videoMute => 'Mute';

  @override
  String get videoUnmute => 'Unmute';

  @override
  String get videoCameraOn => 'Camera on';

  @override
  String get videoCameraOff => 'Camera off';

  @override
  String get videoEndConsult => 'End consultation';

  @override
  String get videoPermissionDenied =>
      'Camera and microphone permissions are required';

  @override
  String get videoWaitingDoctor => 'Waiting for doctor…';

  @override
  String get videoConnected => 'Connected';

  @override
  String get videoChannel => 'Channel';

  @override
  String get onboardingStep8of8 => 'Step 8/8';

  @override
  String get onboardingCompleteProfile => 'Complete Your Profile';

  @override
  String get onboardingCompleteProfileDesc =>
      'Add your details so doctors can serve you better.';

  @override
  String get onboardingCompleteSetup => 'Complete Setup';

  @override
  String get onboardingSaveContinue => 'Save & Continue';

  @override
  String get onboardingEmergencyContact => 'Emergency Contact';

  @override
  String get onboardingEmergencyDesc =>
      'Add one person we can alert in an emergency.';

  @override
  String get onboardingEmergencySecondLater =>
      'You can add a second contact later in Emergency settings.';

  @override
  String get onboardingStartUsing => 'Start Using MEDCLUES';

  @override
  String get onboardingAllSet => 'You\'re ready to go!';

  @override
  String get tourHomeTitle => 'Home';

  @override
  String get tourHomeDesc => 'Search doctors, hospitals, and quick actions.';

  @override
  String get tourHospitalsTitle => 'Hospitals';

  @override
  String get tourHospitalsDesc => 'Find nearby hospitals and details.';

  @override
  String get tourDoctorsTitle => 'Doctors';

  @override
  String get tourDoctorsDesc => 'Browse specialists and book appointments.';

  @override
  String get tourAppointmentsTitle => 'Appointments';

  @override
  String get tourAppointmentsDesc => 'View upcoming and past visits.';

  @override
  String get tourRecordsTitle => 'Medical Records';

  @override
  String get tourRecordsDesc => 'Upload and access your health reports.';

  @override
  String get tourEmergencyTitle => 'Emergency';

  @override
  String get tourEmergencyDesc => 'Quick SOS and emergency contacts.';

  @override
  String get emergencyActiveTitle => 'Emergency Active';

  @override
  String emergencyCallFailed(String label) {
    return 'Could not place $label call';
  }

  @override
  String get emergencyNoRelatives =>
      'No relatives saved — shared via system sheet';

  @override
  String get emergencyShareLocation => 'Share live location';

  @override
  String get emergencyNearbyHospitals => 'Nearby hospitals';

  @override
  String get emergencyBookConsultation => 'Book consultation';

  @override
  String get emergencyConnectDoctors => 'Connect to available doctors';

  @override
  String get emergencyWhatsappAlert =>
      'Send alert & live location link via WhatsApp';

  @override
  String get emergencyScheduleVisit => 'Schedule a non-emergency visit';

  @override
  String get emergencyCallPoliceBtn => 'Call Police';

  @override
  String get emergencyCallFireBtn => 'Call Fire';

  @override
  String emergencyAccessCountdown(int seconds) {
    return 'Auto-SOS in ${seconds}s';
  }

  @override
  String get emergencyCancelSos => 'Cancel SOS';

  @override
  String get emergencySelectSymptoms => 'Select your symptoms';

  @override
  String get emergencySeverityCritical => 'Critical';

  @override
  String get emergencySeverityModerate => 'Moderate';

  @override
  String get emergencySeverityMinor => 'Minor';

  @override
  String get receiptAppointmentReceipt => 'Appointment Receipt';

  @override
  String get receiptConfirmed => 'Appointment Confirmed';

  @override
  String get receiptPatient => 'Patient';

  @override
  String get receiptDoctor => 'Doctor';

  @override
  String get receiptSpecialization => 'Specialization';

  @override
  String get receiptHospital => 'Hospital';

  @override
  String get receiptLocation => 'Location';

  @override
  String get receiptDateTime => 'Date & Time';

  @override
  String get receiptVisitType => 'Visit Type';

  @override
  String get receiptStatus => 'Status';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptToken => 'Token';

  @override
  String get receiptBookingId => 'Booking ID';

  @override
  String get receiptGenerated => 'Generated';

  @override
  String get receiptStatusConfirmed => 'Confirmed';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileCancelEdit => 'Cancel';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileBloodGroup => 'Blood Group';

  @override
  String get profileAddressLine1 => 'Address Line 1';

  @override
  String get profileAddressLine2 => 'Address Line 2';

  @override
  String get profileCity => 'City';

  @override
  String get profileState => 'State';

  @override
  String get profilePincode => 'PIN Code';

  @override
  String get addressTitle => 'Address';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get recordsSubtitle =>
      'Store and share your medical documents securely';

  @override
  String get recordsTypeLab => 'Lab report';

  @override
  String get recordsTypePrescription => 'Prescription';

  @override
  String get recordsTypeXray => 'X-Ray / Scan';

  @override
  String get recordsTypeOther => 'Other';

  @override
  String recordsFileTypesHint(String maxSize) {
    return 'PDF, images, DOCX ($maxSize)';
  }

  @override
  String get recordsNoFile => 'No file attached to this report';

  @override
  String get recordsIdMissing => 'Report id missing — refresh and try again';

  @override
  String get recordsYourReports => 'Your Reports';

  @override
  String get recordsEmpty => 'No health records yet';

  @override
  String get recordsView => 'View';

  @override
  String get recordsEmptyUploadHint =>
      'Upload lab results, prescriptions, or scans above';

  @override
  String get recordsViewReport => 'View report';
}
