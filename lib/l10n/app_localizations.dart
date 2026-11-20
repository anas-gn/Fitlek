import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @loginErrorEmptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get loginErrorEmptyEmail;

  /// No description provided for @loginErrorEmptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get loginErrorEmptyPassword;

  /// No description provided for @loginErrorInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid token received from the server.'**
  String get loginErrorInvalidToken;

  /// No description provided for @loginErrorMissingUserData.
  ///
  /// In en, this message translates to:
  /// **'User data is missing.'**
  String get loginErrorMissingUserData;

  /// No description provided for @loginErrorIncompleteUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Incomplete user information.'**
  String get loginErrorIncompleteUserInfo;

  /// No description provided for @loginErrorSocialAccount.
  ///
  /// In en, this message translates to:
  /// **'This account uses Google or Apple sign-in. Continue with your original sign-in method below.'**
  String get loginErrorSocialAccount;

  /// No description provided for @loginErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Login error ({code})'**
  String loginErrorCode(int code);

  /// No description provided for @loginErrorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection.'**
  String get loginErrorCheckConnection;

  /// No description provided for @loginErrorUnrecognizedRole.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized role: {role}'**
  String loginErrorUnrecognizedRole(String role);

  /// No description provided for @loginErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginErrorGoogleFailed;

  /// No description provided for @loginErrorAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get loginErrorAppleFailed;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginErrorSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended.'**
  String get loginErrorSuspended;

  /// No description provided for @loginErrorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get loginErrorFillAllFields;

  /// No description provided for @loginErrorAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginErrorAccountNotFound;

  /// No description provided for @loginBadgeSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginBadgeSignIn;

  /// No description provided for @loginHeadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginHeadingTitle;

  /// No description provided for @loginHeadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your space and manage your activities.'**
  String get loginHeadingSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginCtaLogIn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get loginCtaLogIn;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOr;

  /// No description provided for @loginContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get loginContinueGoogle;

  /// No description provided for @loginContinueApple.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH APPLE'**
  String get loginContinueApple;

  /// No description provided for @loginNotRegisteredYet.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet?'**
  String get loginNotRegisteredYet;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE AN ACCOUNT'**
  String get loginCreateAccount;

  /// No description provided for @loginBackTo.
  ///
  /// In en, this message translates to:
  /// **'Back to '**
  String get loginBackTo;

  /// No description provided for @loginBackToHome.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get loginBackToHome;

  /// No description provided for @loginSetPasswordErrorMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginSetPasswordErrorMinLength;

  /// No description provided for @loginSetPasswordErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get loginSetPasswordErrorMismatch;

  /// No description provided for @loginSetPasswordErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set password.'**
  String get loginSetPasswordErrorFailed;

  /// No description provided for @loginSetPasswordErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error.'**
  String get loginSetPasswordErrorConnection;

  /// No description provided for @loginSetPasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password set!'**
  String get loginSetPasswordSuccessTitle;

  /// No description provided for @loginSetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'You can now log in with your email and password.'**
  String get loginSetPasswordSuccessMessage;

  /// No description provided for @loginSetPasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get loginSetPasswordDone;

  /// No description provided for @loginSetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a Password'**
  String get loginSetPasswordTitle;

  /// No description provided for @loginSetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally set a password so you can also log in with your email later.'**
  String get loginSetPasswordSubtitle;

  /// No description provided for @loginSetPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get loginSetPasswordNewLabel;

  /// No description provided for @loginSetPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get loginSetPasswordConfirmLabel;

  /// No description provided for @loginSetPasswordSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get loginSetPasswordSkip;

  /// No description provided for @loginSetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get loginSetPasswordSubmit;

  /// No description provided for @registerInterestsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get registerInterestsDialogTitle;

  /// No description provided for @registerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get registerCancel;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerErrorSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get registerErrorSelectRole;

  /// No description provided for @registerErrorAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Sirvya Legal & Compliance Framework to create an account.'**
  String get registerErrorAcceptTerms;

  /// No description provided for @registerErrorFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name required'**
  String get registerErrorFirstNameRequired;

  /// No description provided for @registerErrorLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name required'**
  String get registerErrorLastNameRequired;

  /// No description provided for @registerErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get registerErrorInvalidEmail;

  /// No description provided for @registerErrorHeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Height required'**
  String get registerErrorHeightRequired;

  /// No description provided for @registerErrorInvalidHeight.
  ///
  /// In en, this message translates to:
  /// **'Invalid height'**
  String get registerErrorInvalidHeight;

  /// No description provided for @registerErrorInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight in kg'**
  String get registerErrorInvalidWeight;

  /// No description provided for @registerErrorChooseInterest.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one interest (up to 5)'**
  String get registerErrorChooseInterest;

  /// No description provided for @registerErrorLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Press Use my current location to fill your location'**
  String get registerErrorLocationRequired;

  /// No description provided for @registerErrorChooseSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one specialty (up to 5)'**
  String get registerErrorChooseSpecialty;

  /// No description provided for @registerErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short (min 6 chars)'**
  String get registerErrorPasswordTooShort;

  /// No description provided for @registerErrorPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerErrorPasswordsMismatch;

  /// No description provided for @registerErrorSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender to continue'**
  String get registerErrorSelectGender;

  /// No description provided for @registerErrorOtpLength.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code sent to your email'**
  String get registerErrorOtpLength;

  /// No description provided for @registerErrorSendOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get registerErrorSendOtpFailed;

  /// No description provided for @registerErrorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server'**
  String get registerErrorServerUnreachable;

  /// No description provided for @registerErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get registerErrorInvalidOtp;

  /// No description provided for @registerErrorVerifyOtpNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error verifying code'**
  String get registerErrorVerifyOtpNetwork;

  /// No description provided for @registerErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerErrorFailed;

  /// No description provided for @registerErrorSelectRoleGoogle.
  ///
  /// In en, this message translates to:
  /// **'Select your role before continuing with Google.'**
  String get registerErrorSelectRoleGoogle;

  /// No description provided for @registerErrorSelectRoleApple.
  ///
  /// In en, this message translates to:
  /// **'Select your role before continuing with Apple.'**
  String get registerErrorSelectRoleApple;

  /// No description provided for @registerErrorAgreeTermsSocial.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service to sign up.'**
  String get registerErrorAgreeTermsSocial;

  /// No description provided for @registerErrorUnrecognizedRole.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized role: {role}'**
  String registerErrorUnrecognizedRole(String role);

  /// No description provided for @registerErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-up failed. Please try again.'**
  String get registerErrorGoogleFailed;

  /// No description provided for @registerErrorAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-up failed. Please try again.'**
  String get registerErrorAppleFailed;

  /// No description provided for @registerSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get registerSuccessTitle;

  /// No description provided for @registerSuccessPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Welcome {firstName}. Your account is pending approval.'**
  String registerSuccessPendingApproval(String firstName);

  /// No description provided for @registerLogInButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLogInButton;

  /// No description provided for @registerSuccessWelcomePrefix.
  ///
  /// In en, this message translates to:
  /// **'Welcome {firstName}. '**
  String registerSuccessWelcomePrefix(String firstName);

  /// No description provided for @registerSuccessCoachBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'You can now log in. Your Sirvya verified badge is pending verification, which can take up to 48 hours.'**
  String get registerSuccessCoachBadgeNote;

  /// No description provided for @registerSuccessAdvisorPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending approval.'**
  String get registerSuccessAdvisorPendingNote;

  /// No description provided for @registerSuccessClientNote.
  ///
  /// In en, this message translates to:
  /// **'You can now log in.'**
  String get registerSuccessClientNote;

  /// No description provided for @registerStep1Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 / 5'**
  String get registerStep1Label;

  /// No description provided for @registerStep2Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 / 5'**
  String get registerStep2Label;

  /// No description provided for @registerStep3Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 3 / 5'**
  String get registerStep3Label;

  /// No description provided for @registerStep4Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 4 / 5'**
  String get registerStep4Label;

  /// No description provided for @registerStep5Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 5 / 5'**
  String get registerStep5Label;

  /// No description provided for @registerStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What is\nyour role?'**
  String get registerStep1Title;

  /// No description provided for @registerStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get registerStep2Title;

  /// No description provided for @registerStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Secure\nyour account'**
  String get registerStep3Title;

  /// No description provided for @registerStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Terms &\nPreferences'**
  String get registerStep4Title;

  /// No description provided for @registerStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Verify your\nemail OTP'**
  String get registerStep5Title;

  /// No description provided for @registerStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'ll use SIRVYA.'**
  String get registerStep1Sub;

  /// No description provided for @registerStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to call you.'**
  String get registerStep2Sub;

  /// No description provided for @registerStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password.'**
  String get registerStep3Sub;

  /// No description provided for @registerStep4Sub.
  ///
  /// In en, this message translates to:
  /// **'Personalize & agree to legal terms.'**
  String get registerStep4Sub;

  /// No description provided for @registerStep5Sub.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email address.'**
  String get registerStep5Sub;

  /// No description provided for @registerOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP Code'**
  String get registerOtpLabel;

  /// No description provided for @registerOtpHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get registerOtpHint;

  /// No description provided for @registerOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email} via noreply@devunivers.com'**
  String registerOtpSentTo(String email);

  /// No description provided for @registerOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get registerOtpResend;

  /// No description provided for @registerRoleClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get registerRoleClientLabel;

  /// No description provided for @registerRoleClientDesc.
  ///
  /// In en, this message translates to:
  /// **'Find a coach and book sessions.'**
  String get registerRoleClientDesc;

  /// No description provided for @registerRoleCoachLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get registerRoleCoachLabel;

  /// No description provided for @registerRoleCoachDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your clients and grow your business.'**
  String get registerRoleCoachDesc;

  /// No description provided for @registerInviterCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Inviter code (optional)'**
  String get registerInviterCodeLabel;

  /// No description provided for @registerInviterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your coach’s invitation code'**
  String get registerInviterCodeHint;

  /// No description provided for @registerOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get registerOr;

  /// No description provided for @registerSelectRoleFirst.
  ///
  /// In en, this message translates to:
  /// **'SELECT A ROLE FIRST'**
  String get registerSelectRoleFirst;

  /// No description provided for @registerContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH GOOGLE'**
  String get registerContinueGoogle;

  /// No description provided for @registerContinueApple.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH APPLE'**
  String get registerContinueApple;

  /// No description provided for @registerFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get registerFirstNameLabel;

  /// No description provided for @registerFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Anas'**
  String get registerFirstNameHint;

  /// No description provided for @registerLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get registerLastNameLabel;

  /// No description provided for @registerLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Benali'**
  String get registerLastNameHint;

  /// No description provided for @registerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get registerEmailLabel;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.ma'**
  String get registerEmailHint;

  /// No description provided for @registerHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get registerHeightLabel;

  /// No description provided for @registerHeightHint.
  ///
  /// In en, this message translates to:
  /// **'175'**
  String get registerHeightHint;

  /// No description provided for @registerWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get registerWeightLabel;

  /// No description provided for @registerWeightHint.
  ///
  /// In en, this message translates to:
  /// **'70'**
  String get registerWeightHint;

  /// No description provided for @registerNutritionGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Your nutrition goal (optional)'**
  String get registerNutritionGoalTitle;

  /// No description provided for @registerNutritionGoalBalanced.
  ///
  /// In en, this message translates to:
  /// **'Build balanced habits'**
  String get registerNutritionGoalBalanced;

  /// No description provided for @registerNutritionGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight gradually'**
  String get registerNutritionGoalLose;

  /// No description provided for @registerNutritionGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight gradually'**
  String get registerNutritionGoalGain;

  /// No description provided for @registerNutritionGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain my weight'**
  String get registerNutritionGoalMaintain;

  /// No description provided for @registerNutritionGoalPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal goal'**
  String get registerNutritionGoalPersonal;

  /// No description provided for @registerNutritionGoalSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped · You can set this up later in your profile'**
  String get registerNutritionGoalSkipped;

  /// No description provided for @registerNutritionGoalOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional · Tap to configure or skip for now'**
  String get registerNutritionGoalOptional;

  /// No description provided for @registerNutritionGoalClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get registerNutritionGoalClearTooltip;

  /// No description provided for @registerNutritionGoalSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get registerNutritionGoalSkip;

  /// No description provided for @registerInterestsHeader.
  ///
  /// In en, this message translates to:
  /// **'Your interests ({count}/5)'**
  String registerInterestsHeader(int count);

  /// No description provided for @registerSpecialtiesHeader.
  ///
  /// In en, this message translates to:
  /// **'Coaching specialties ({count}/5)'**
  String registerSpecialtiesHeader(int count);

  /// No description provided for @registerInterestsSub.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 interests to personalize your coach recommendations.'**
  String get registerInterestsSub;

  /// No description provided for @registerSpecialtiesSub.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 specialties.'**
  String get registerSpecialtiesSub;

  /// No description provided for @registerSpecialtyStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength Training'**
  String get registerSpecialtyStrength;

  /// No description provided for @registerSpecialtyWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get registerSpecialtyWeightLoss;

  /// No description provided for @registerSpecialtyYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get registerSpecialtyYoga;

  /// No description provided for @registerSpecialtyCrossFit.
  ///
  /// In en, this message translates to:
  /// **'CrossFit'**
  String get registerSpecialtyCrossFit;

  /// No description provided for @registerSpecialtyBoxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing'**
  String get registerSpecialtyBoxing;

  /// No description provided for @registerSpecialtyNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get registerSpecialtyNutrition;

  /// No description provided for @registerSpecialtyPilates.
  ///
  /// In en, this message translates to:
  /// **'Pilates'**
  String get registerSpecialtyPilates;

  /// No description provided for @registerSpecialtyCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get registerSpecialtyCardio;

  /// No description provided for @registerSpecialtyStretching.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get registerSpecialtyStretching;

  /// No description provided for @registerSpecialtyFunctional.
  ///
  /// In en, this message translates to:
  /// **'Functional Training'**
  String get registerSpecialtyFunctional;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordLabel;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get registerGenderMale;

  /// No description provided for @registerGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get registerGenderFemale;

  /// No description provided for @registerGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get registerGenderOther;

  /// No description provided for @registerInvitationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code (optional)'**
  String get registerInvitationCodeLabel;

  /// No description provided for @registerInvitationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A1B2C3D4E5F6'**
  String get registerInvitationCodeHint;

  /// No description provided for @registerInvitationCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Invited by a coach? Enter their code to credit your signup.'**
  String get registerInvitationCodeHelper;

  /// No description provided for @registerInvitationCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is not recognized.'**
  String get registerInvitationCodeInvalid;

  /// No description provided for @registerInvitationCodeValid.
  ///
  /// In en, this message translates to:
  /// **'Valid coach code'**
  String get registerInvitationCodeValid;

  /// No description provided for @registerTermsAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get registerTermsAgreePrefix;

  /// No description provided for @registerTermsAgreeLink.
  ///
  /// In en, this message translates to:
  /// **'Sirvya Master Legal & Compliance Framework'**
  String get registerTermsAgreeLink;

  /// No description provided for @registerTermsAgreeSuffix.
  ///
  /// In en, this message translates to:
  /// **' including Terms of Service, Privacy Policy & Disclaimers.'**
  String get registerTermsAgreeSuffix;

  /// No description provided for @registerTermsReadButton.
  ///
  /// In en, this message translates to:
  /// **'Read Full Framework'**
  String get registerTermsReadButton;

  /// No description provided for @registerTermsModalHeader.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA MASTER LEGAL FRAMEWORK'**
  String get registerTermsModalHeader;

  /// No description provided for @registerTermsSecGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get registerTermsSecGeneralTitle;

  /// No description provided for @registerTermsSecGeneralBody.
  ///
  /// In en, this message translates to:
  /// **'Effective Date: November 2026\nVersion: 1.0.3\nOperating Entity: DevUnivers (Morocco)\nContact: privacy@devunivers.com | support@devunivers.com\nPlatform: Sirvya Mobile Application & Associated Infrastructure'**
  String get registerTermsSecGeneralBody;

  /// No description provided for @registerTermsSecScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Framework & International Scope'**
  String get registerTermsSecScopeTitle;

  /// No description provided for @registerTermsSecScopeBody.
  ///
  /// In en, this message translates to:
  /// **'Sirvya is operated by DevUnivers in Morocco and designed for global accessibility. This comprehensive legal framework governs your use of Sirvya worldwide. It adheres to Moroccan privacy regulations (Law 09-08 / CNDP) and aligns with international data protection benchmarks including the EU General Data Protection Regulation (GDPR) and global consumer protection standards.'**
  String get registerTermsSecScopeBody;

  /// No description provided for @registerTermsSecDefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Definitions'**
  String get registerTermsSecDefsTitle;

  /// No description provided for @registerTermsSecDefsBody.
  ///
  /// In en, this message translates to:
  /// **'• Platform: Refers to the Sirvya application, its associated web infrastructure, AI services, and systems provided by DevUnivers.\n• Company: Refers to DevUnivers, the operating legal entity.\n• User: Any individual creating an account on the Platform to track nutrition, workouts, book services, or interact with Coaches/Gyms.\n• Coach: An independent fitness professional or personal trainer offering services or advice via the Platform.\n• Gym: An independent fitness facility or studio listed on the Platform.'**
  String get registerTermsSecDefsBody;

  /// No description provided for @registerTermsSecTosTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Terms of Service (ToS)'**
  String get registerTermsSecTosTitle;

  /// No description provided for @registerTermsSecTosBody.
  ///
  /// In en, this message translates to:
  /// **'1.1 Acceptance of Terms\nBy accessing, creating an account, or using Sirvya, you agree to be bound by these Terms of Service. If you do not agree to these terms, you must discontinue use and uninstall the app.\n\n1.2 Eligibility & Age Requirements\nUsers must be at least 18 years old (or the legal age of majority in their jurisdiction) to independently register. Minors between 13 and 17 may only use the platform under parental/guardian supervision and verifiable consent. Sirvya is strictly not intended for children under 13.\n\n1.3 Account Security & Integrity\nYou are responsible for safeguarding your credentials. Account sharing, selling, automated scraping, reverse engineering, security tampering, or unauthorized commercial exploitation is strictly prohibited.\n\n1.4 Subscription & Marketplace Terms\nWhile certain core features are currently provided free or in beta, Sirvya reserves the right to introduce optional premium features, subscriptions, or transaction fees with clear prior notice.\n\n1.5 Limitation of Liability\nTo the maximum extent permitted by applicable law, DevUnivers, Sirvya, and their affiliates shall not be liable for indirect, incidental, punitive, or consequential damages resulting from app usage, workout activities, nutritional tracking, or interactions with independent third parties.\n\n1.6 Governing Law & International Users\nThese Terms are governed by and construed in accordance with the laws of the Kingdom of Morocco. If you are an individual consumer residing outside Morocco (such as in the European Union, United Kingdom, United States, or GCC), nothing in these Terms deprives you of the mandatory statutory consumer protections provided by the laws of your country of habitual residence. In case of any concern, we encourage contacting support@devunivers.com for informal amicable resolution.'**
  String get registerTermsSecTosBody;

  /// No description provided for @registerTermsSecPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Privacy Policy & Data Protection'**
  String get registerTermsSecPrivacyTitle;

  /// No description provided for @registerTermsSecPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'2.1 Data Collection & Purpose\nWe collect personal and health-related fitness data exclusively to provide personalized fitness tracking, coach discovery, and nutrition analytics (name, email, age, height, weight, BMI, meal logs, macros, booking records, and chat communications).\n\n2.2 Health & Biometric Data Consent\nTracking nutrition, calories, body weight, and workout metrics involves health-related data. By using these optional features, you provide your explicit consent for Sirvya to store and process this data to display your diary, calculate calorie targets, and track fitness progress.\n\n2.3 AI Meal Scanning & Microsoft Azure\nOptional meal photo analysis transmits stripped image data via secure TLS encryption to Microsoft Azure AI (GPT-4 mini) solely to estimate foods, portions, and macros. Photos are processed ephemerally in memory and are not retained in Sirvya server storage.\n\n2.4 Location & OpenStreetMap Nominatim\nWhen granted permission, device location is accessed to detect your city and display nearby coaches. Reverse geocoding is powered by OpenStreetMap Nominatim under OSM privacy safeguards. Your precise GPS coordinates are never broadcast to other users.\n\n2.5 International & GDPR User Rights\nRegardless of your country of residence, you have full control over your personal data:\n• Right to Access: Request a copy of your personal data.\n• Right to Rectification: Correct or update any inaccurate information.\n• Right to Erasure: Request total deletion of your account and linked records.\n• Right to Withdraw Consent: Discontinue health/location tracking at any time.\n• In-App Deletion: You can permanently delete your account directly inside the app settings under your profile.\nFor any privacy inquiry, contact privacy@devunivers.com.'**
  String get registerTermsSecPrivacyBody;

  /// No description provided for @registerTermsSecHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Health, Medical & Allergen Disclaimers'**
  String get registerTermsSecHealthTitle;

  /// No description provided for @registerTermsSecHealthBody.
  ///
  /// In en, this message translates to:
  /// **'3.1 NOT A HEALTHCARE PROVIDER\nSIRVYA IS NOT A MEDICAL PLATFORM, MEDICAL DEVICE, OR HEALTHCARE PROVIDER. App content, AI estimates, and Coach services are for informational and lifestyle purposes only and must NEVER replace qualified medical diagnosis or professional healthcare advice.\n\n3.2 CRITICAL ALLERGY WARNING\nNEITHER SIRVYA, ITS AI IMAGE SCANNER, NOR ITS INGREDIENT DATABASES DETECT OR VERIFY ALLERGENS (such as peanuts, tree nuts, gluten, dairy, shellfish, soy, or eggs). NEVER rely on Sirvya or photo scans if you have food allergies, celiac disease, or medical dietary restrictions. Always check manufacturer labels.\n\n3.3 Assumption of Physical Risk\nPhysical exercise entails inherent risks of injury. Consult a licensed physician prior to starting any new training or nutrition regimen. You voluntarily assume all physical risks associated with workouts.\n\n3.4 Emergency Services\nIn the event of a medical emergency, immediately contact your local emergency response services (such as 15/190 in Morocco, 112 in the EU, or 911 in the US).'**
  String get registerTermsSecHealthBody;

  /// No description provided for @registerTermsSecOpenSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Open Source & Third-Party Database Attribution'**
  String get registerTermsSecOpenSourceTitle;

  /// No description provided for @registerTermsSecOpenSourceBody.
  ///
  /// In en, this message translates to:
  /// **'Food and nutritional information in Sirvya is powered in part by the Open Food Facts global collaborative database (openfoodfacts.org), made available under the Open Database License (ODbL 1.0) and Database Contents License (DbCL). Open Food Facts is an independent open-data project and does not endorse Sirvya.'**
  String get registerTermsSecOpenSourceBody;

  /// No description provided for @registerTermsSecCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Coach & Gym Terms (Independent Contractors)'**
  String get registerTermsSecCoachTitle;

  /// No description provided for @registerTermsSecCoachBody.
  ///
  /// In en, this message translates to:
  /// **'5.1 Independent Status\nSirvya is a neutral technology platform connecting users with fitness providers. Coaches and Gyms operate as independent businesses and are solely responsible for their sessions, guidance, and qualifications.\n\n5.2 Zero Tolerance for Fraudulent Credentials\nFalsification of professional certifications or misrepresentation results in immediate account expulsion and potential legal reporting.'**
  String get registerTermsSecCoachBody;

  /// No description provided for @registerTermsSecCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Community Guidelines & Intellectual Property'**
  String get registerTermsSecCommunityTitle;

  /// No description provided for @registerTermsSecCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'6.1 Community Standards: Zero tolerance for harassment, hate speech, spam, offensive media, or unauthorized commercial solicitation.\n\n6.2 Intellectual Property: Sirvya brand assets, designs, code, and interfaces are the proprietary property of DevUnivers. Users retain ownership of their personal workout content.'**
  String get registerTermsSecCommunityBody;

  /// No description provided for @registerTermsSecBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Booking & Cancellation Policy'**
  String get registerTermsSecBookingTitle;

  /// No description provided for @registerTermsSecBookingBody.
  ///
  /// In en, this message translates to:
  /// **'7.1 Commitment: Automated systems detect and prevent fraudulent bookings.\n7.2 Provider Policies: Individual session cancellations are governed by the specific Coach or Gym policy selected at booking.'**
  String get registerTermsSecBookingBody;

  /// No description provided for @registerTermsAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'I AGREE & ACCEPT TERMS'**
  String get registerTermsAcceptButton;

  /// No description provided for @registerCtaContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get registerCtaContinue;

  /// No description provided for @registerCtaVerifyCreate.
  ///
  /// In en, this message translates to:
  /// **'VERIFY & CREATE ACCOUNT'**
  String get registerCtaVerifyCreate;

  /// No description provided for @registerAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get registerAlreadyRegistered;

  /// No description provided for @registerCtaLogIn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get registerCtaLogIn;

  /// No description provided for @registerPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get registerPasswordWeak;

  /// No description provided for @registerPasswordMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get registerPasswordMedium;

  /// No description provided for @registerPasswordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get registerPasswordGood;

  /// No description provided for @registerPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get registerPasswordStrong;

  /// No description provided for @registerPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security: {strength}'**
  String registerPasswordSecurity(String strength);

  /// No description provided for @clientForgotErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get clientForgotErrorInvalidEmail;

  /// No description provided for @clientForgotErrorOtpLength.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code'**
  String get clientForgotErrorOtpLength;

  /// No description provided for @clientForgotErrorPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short (min 6 chars)'**
  String get clientForgotErrorPasswordShort;

  /// No description provided for @clientForgotErrorPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get clientForgotErrorPasswordsMismatch;

  /// No description provided for @clientForgotErrorEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email not found'**
  String get clientForgotErrorEmailNotFound;

  /// No description provided for @clientForgotErrorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server'**
  String get clientForgotErrorServerUnreachable;

  /// No description provided for @clientForgotErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get clientForgotErrorInvalidOtp;

  /// No description provided for @clientForgotErrorResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Error while resetting password'**
  String get clientForgotErrorResetFailed;

  /// No description provided for @clientForgotSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get clientForgotSuccessTitle;

  /// No description provided for @clientForgotSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'You can now log in with your new password.'**
  String get clientForgotSuccessMessage;

  /// No description provided for @clientForgotLogInCta.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get clientForgotLogInCta;

  /// No description provided for @clientForgotStep1Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 / 3'**
  String get clientForgotStep1Label;

  /// No description provided for @clientForgotStep2Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 / 3'**
  String get clientForgotStep2Label;

  /// No description provided for @clientForgotStep3Label.
  ///
  /// In en, this message translates to:
  /// **'STEP 3 / 3'**
  String get clientForgotStep3Label;

  /// No description provided for @clientForgotStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Your\nemail address'**
  String get clientForgotStep1Title;

  /// No description provided for @clientForgotStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Verification\ncode'**
  String get clientForgotStep2Title;

  /// No description provided for @clientForgotStep3Title.
  ///
  /// In en, this message translates to:
  /// **'New\npassword'**
  String get clientForgotStep3Title;

  /// No description provided for @clientForgotStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset code.'**
  String get clientForgotStep1Sub;

  /// No description provided for @clientForgotStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email.'**
  String get clientForgotStep2Sub;

  /// No description provided for @clientForgotStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Choose a new secure password.'**
  String get clientForgotStep3Sub;

  /// No description provided for @clientForgotEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get clientForgotEmailLabel;

  /// No description provided for @clientForgotEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.ma'**
  String get clientForgotEmailHint;

  /// No description provided for @clientForgotOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP code'**
  String get clientForgotOtpLabel;

  /// No description provided for @clientForgotOtpHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get clientForgotOtpHint;

  /// No description provided for @clientForgotResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get clientForgotResendCode;

  /// No description provided for @clientForgotNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get clientForgotNewPasswordLabel;

  /// No description provided for @clientForgotNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get clientForgotNewPasswordHint;

  /// No description provided for @clientForgotConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get clientForgotConfirmPasswordLabel;

  /// No description provided for @clientForgotConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get clientForgotConfirmPasswordHint;

  /// No description provided for @clientForgotCtaSendCode.
  ///
  /// In en, this message translates to:
  /// **'SEND CODE'**
  String get clientForgotCtaSendCode;

  /// No description provided for @clientForgotCtaVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'VERIFY CODE'**
  String get clientForgotCtaVerifyCode;

  /// No description provided for @clientForgotCtaResetPassword.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get clientForgotCtaResetPassword;

  /// No description provided for @clientForgotRememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get clientForgotRememberPassword;

  /// No description provided for @clientForgotLogInLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get clientForgotLogInLink;

  /// No description provided for @clientForgotPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get clientForgotPasswordWeak;

  /// No description provided for @clientForgotPasswordMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get clientForgotPasswordMedium;

  /// No description provided for @clientForgotPasswordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get clientForgotPasswordGood;

  /// No description provided for @clientForgotPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get clientForgotPasswordStrong;

  /// No description provided for @clientForgotPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security: {strength}'**
  String clientForgotPasswordSecurity(String strength);

  /// No description provided for @headerFooterNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get headerFooterNavHome;

  /// No description provided for @headerFooterNavExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get headerFooterNavExplore;

  /// No description provided for @headerFooterNavSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get headerFooterNavSessions;

  /// No description provided for @headerFooterNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get headerFooterNavProfile;

  /// No description provided for @headerFooterHomeContent.
  ///
  /// In en, this message translates to:
  /// **'Home Content {index}'**
  String headerFooterHomeContent(int index);

  /// No description provided for @coachOnboardingErrorInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid coach invitation.'**
  String get coachOnboardingErrorInvalidQr;

  /// No description provided for @coachOnboardingErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This invitation code is not recognized.'**
  String get coachOnboardingErrorInvalidCode;

  /// No description provided for @coachOnboardingErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed.'**
  String get coachOnboardingErrorUploadFailed;

  /// No description provided for @coachOnboardingLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get coachOnboardingLogOut;

  /// No description provided for @coachOnboardingOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify your account'**
  String get coachOnboardingOfflineTitle;

  /// No description provided for @coachOnboardingOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get coachOnboardingOfflineSubtitle;

  /// No description provided for @coachOnboardingRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get coachOnboardingRetry;

  /// No description provided for @coachOnboardingBadgeVerification.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION'**
  String get coachOnboardingBadgeVerification;

  /// No description provided for @coachOnboardingChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your\ncoach account'**
  String get coachOnboardingChoicesTitle;

  /// No description provided for @coachOnboardingChoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This step is required to access SIRVYA as a coach.'**
  String get coachOnboardingChoicesSubtitle;

  /// No description provided for @coachOnboardingQrTag.
  ///
  /// In en, this message translates to:
  /// **'INSTANT ACCESS'**
  String get coachOnboardingQrTag;

  /// No description provided for @coachOnboardingQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan an invitation QR code'**
  String get coachOnboardingQrTitle;

  /// No description provided for @coachOnboardingQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code of the coach who invited you and enter right away.'**
  String get coachOnboardingQrDesc;

  /// No description provided for @coachOnboardingOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get coachOnboardingOr;

  /// No description provided for @coachOnboardingCertTag.
  ///
  /// In en, this message translates to:
  /// **'REVIEW · UP TO 48H'**
  String get coachOnboardingCertTag;

  /// No description provided for @coachOnboardingCertTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your certificate'**
  String get coachOnboardingCertTitle;

  /// No description provided for @coachOnboardingCertDesc.
  ///
  /// In en, this message translates to:
  /// **'Our team checks your credentials. You enter once your request is approved.'**
  String get coachOnboardingCertDesc;

  /// No description provided for @coachOnboardingPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Your documents are only used to verify your identity as a coach.'**
  String get coachOnboardingPrivacyNotice;

  /// No description provided for @coachOnboardingBadgePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING REVIEW'**
  String get coachOnboardingBadgePending;

  /// No description provided for @coachOnboardingWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for\napproval'**
  String get coachOnboardingWaitingTitle;

  /// No description provided for @coachOnboardingWaitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your certificate was sent. You will get access as soon as our team approves it.'**
  String get coachOnboardingWaitingSubtitle;

  /// No description provided for @coachOnboardingStepSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate sent'**
  String get coachOnboardingStepSentTitle;

  /// No description provided for @coachOnboardingStepSentSub.
  ///
  /// In en, this message translates to:
  /// **'We received your photo.'**
  String get coachOnboardingStepSentSub;

  /// No description provided for @coachOnboardingStepReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get coachOnboardingStepReviewTitle;

  /// No description provided for @coachOnboardingStepReviewSub.
  ///
  /// In en, this message translates to:
  /// **'Usually within 48 hours.'**
  String get coachOnboardingStepReviewSub;

  /// No description provided for @coachOnboardingStepApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get coachOnboardingStepApprovedTitle;

  /// No description provided for @coachOnboardingStepApprovedSub.
  ///
  /// In en, this message translates to:
  /// **'You get full access to SIRVYA.'**
  String get coachOnboardingStepApprovedSub;

  /// No description provided for @coachOnboardingCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'CHECK STATUS'**
  String get coachOnboardingCheckStatus;

  /// No description provided for @coachOnboardingSendAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send another photo'**
  String get coachOnboardingSendAnotherPhoto;

  /// No description provided for @coachAboutYouErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get coachAboutYouErrorUploadFailed;

  /// No description provided for @coachAboutYouPhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Photo ready. Save to confirm.'**
  String get coachAboutYouPhotoReady;

  /// No description provided for @coachAboutYouErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String coachAboutYouErrorGeneric(String error);

  /// No description provided for @coachAboutYouSelectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get coachAboutYouSelectLanguageTitle;

  /// No description provided for @coachAboutYouLanguageAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Language already added'**
  String get coachAboutYouLanguageAlreadyAdded;

  /// No description provided for @coachAboutYouLangArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get coachAboutYouLangArabic;

  /// No description provided for @coachAboutYouLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get coachAboutYouLangFrench;

  /// No description provided for @coachAboutYouLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get coachAboutYouLangEnglish;

  /// No description provided for @coachAboutYouLangSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get coachAboutYouLangSpanish;

  /// No description provided for @coachAboutYouLangTamazight.
  ///
  /// In en, this message translates to:
  /// **'Tamazight'**
  String get coachAboutYouLangTamazight;

  /// No description provided for @coachAboutYouLangGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get coachAboutYouLangGerman;

  /// No description provided for @coachAboutYouLangItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get coachAboutYouLangItalian;

  /// No description provided for @coachAboutYouLangDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get coachAboutYouLangDutch;

  /// No description provided for @coachAboutYouLangPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get coachAboutYouLangPortuguese;

  /// No description provided for @coachAboutYouLangRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get coachAboutYouLangRussian;

  /// No description provided for @coachAboutYouErrorFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get coachAboutYouErrorFullName;

  /// No description provided for @coachAboutYouProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get coachAboutYouProfileUpdated;

  /// No description provided for @coachAboutYouErrorUpdating.
  ///
  /// In en, this message translates to:
  /// **'Error while updating'**
  String get coachAboutYouErrorUpdating;

  /// No description provided for @coachAboutYouTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get coachAboutYouTitle;

  /// No description provided for @coachAboutYouPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get coachAboutYouPreview;

  /// No description provided for @coachAboutYouChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get coachAboutYouChangePhoto;

  /// No description provided for @coachAboutYouFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get coachAboutYouFullNameLabel;

  /// No description provided for @coachAboutYouProfessionalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional title'**
  String get coachAboutYouProfessionalTitleLabel;

  /// No description provided for @coachAboutYouBioLabel.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get coachAboutYouBioLabel;

  /// No description provided for @coachAboutYouLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get coachAboutYouLanguagesLabel;

  /// No description provided for @coachAboutYouAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get coachAboutYouAddLanguage;

  /// No description provided for @coachAboutYouGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get coachAboutYouGenderLabel;

  /// No description provided for @coachAboutYouGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get coachAboutYouGenderMale;

  /// No description provided for @coachAboutYouGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get coachAboutYouGenderFemale;

  /// No description provided for @coachAboutYouGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get coachAboutYouGenderOther;

  /// No description provided for @coachAboutYouGenderHint.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this appears on your public profile.'**
  String get coachAboutYouGenderHint;

  /// No description provided for @coachAboutYouShowOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Show on profile'**
  String get coachAboutYouShowOnProfile;

  /// No description provided for @coachAboutYouInstagramDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Instagram handle'**
  String get coachAboutYouInstagramDialogTitle;

  /// No description provided for @coachAboutYouInstagramHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. mouad.coach'**
  String get coachAboutYouInstagramHint;

  /// No description provided for @coachAboutYouCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachAboutYouCancel;

  /// No description provided for @coachAboutYouSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachAboutYouSave;

  /// No description provided for @coachAboutYouErrorAddInstagramFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add your Instagram handle first'**
  String get coachAboutYouErrorAddInstagramFirst;

  /// No description provided for @coachAboutYouErrorLaunchInstagram.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Instagram'**
  String get coachAboutYouErrorLaunchInstagram;

  /// No description provided for @coachAboutYouContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get coachAboutYouContactTitle;

  /// No description provided for @coachAboutYouInstagramTitle.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get coachAboutYouInstagramTitle;

  /// No description provided for @coachAboutYouAddInstagram.
  ///
  /// In en, this message translates to:
  /// **'Add Instagram'**
  String get coachAboutYouAddInstagram;

  /// No description provided for @coachAboutYouOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get coachAboutYouOpen;

  /// No description provided for @coachAboutYouEmailPhoneManaged.
  ///
  /// In en, this message translates to:
  /// **'Email and phone are managed\nin Account settings.'**
  String get coachAboutYouEmailPhoneManaged;

  /// No description provided for @coachAboutYouAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get coachAboutYouAccountSettings;

  /// No description provided for @coachAboutYouSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get coachAboutYouSaveChanges;

  /// No description provided for @clientHomeSessionFallback.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get clientHomeSessionFallback;

  /// No description provided for @clientHomeUpdateFavoritesFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update favorites'**
  String get clientHomeUpdateFavoritesFailed;

  /// No description provided for @clientHomeErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Error ({statusCode})'**
  String clientHomeErrorCode(int statusCode);

  /// No description provided for @clientHomeLoadRecommendationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recommendations. Please try again.'**
  String get clientHomeLoadRecommendationsFailed;

  /// No description provided for @clientHomeConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Please try again.'**
  String get clientHomeConnectFailed;

  /// No description provided for @clientHomeServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get clientHomeServerUnreachable;

  /// No description provided for @clientHomeNutritionDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your nutrition diary'**
  String get clientHomeNutritionDiaryTitle;

  /// No description provided for @clientHomeNutritionDiarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calories, macros & every meal'**
  String get clientHomeNutritionDiarySubtitle;

  /// No description provided for @clientHomeSectionMyFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get clientHomeSectionMyFavorites;

  /// No description provided for @clientHomeSectionRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get clientHomeSectionRecommended;

  /// No description provided for @clientHomeSetLocationDistances.
  ///
  /// In en, this message translates to:
  /// **'Set location to see distances'**
  String get clientHomeSetLocationDistances;

  /// No description provided for @clientHomeSectionUpcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Sessions'**
  String get clientHomeSectionUpcomingSessions;

  /// No description provided for @clientHomeSectionCoachingCompanies.
  ///
  /// In en, this message translates to:
  /// **'Coaching companies'**
  String get clientHomeSectionCoachingCompanies;

  /// No description provided for @clientHomeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your\nGoals.\nOur Coaches.'**
  String get clientHomeHeroTitle;

  /// No description provided for @clientHomeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the right coach, book a\nsession and start your journey.'**
  String get clientHomeHeroSubtitle;

  /// No description provided for @clientHomeFindYourCoach.
  ///
  /// In en, this message translates to:
  /// **'Find your coach'**
  String get clientHomeFindYourCoach;

  /// No description provided for @clientHomeTagline.
  ///
  /// In en, this message translates to:
  /// **'TRAIN • CONNECT • PROGRESS'**
  String get clientHomeTagline;

  /// No description provided for @clientHomeSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get clientHomeSetLocation;

  /// No description provided for @clientHomeActionBookSession.
  ///
  /// In en, this message translates to:
  /// **'Book a\nSession'**
  String get clientHomeActionBookSession;

  /// No description provided for @clientHomeActionFindCoach.
  ///
  /// In en, this message translates to:
  /// **'Find a\nCoach'**
  String get clientHomeActionFindCoach;

  /// No description provided for @clientHomeActionScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan\nQR'**
  String get clientHomeActionScanQr;

  /// No description provided for @clientHomeActionScanMeal.
  ///
  /// In en, this message translates to:
  /// **'Sirvya AI\nScan meal'**
  String get clientHomeActionScanMeal;

  /// No description provided for @clientHomeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get clientHomeSeeAll;

  /// No description provided for @clientHomeCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientHomeCategoryAll;

  /// No description provided for @clientHomeNoCoachesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coaches available'**
  String get clientHomeNoCoachesAvailable;

  /// No description provided for @clientHomeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientHomeRetry;

  /// No description provided for @clientHomeSessionTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today • {time}'**
  String clientHomeSessionTodayAt(String time);

  /// No description provided for @clientHomeSessionTomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow • {time}'**
  String clientHomeSessionTomorrowAt(String time);

  /// No description provided for @clientHomeSessionDateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} • {time}'**
  String clientHomeSessionDateAt(String date, String time);

  /// No description provided for @clientHomeWithCoach.
  ///
  /// In en, this message translates to:
  /// **'With {coachName}'**
  String clientHomeWithCoach(String coachName);

  /// No description provided for @clientHomeNoCompaniesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No companies available'**
  String get clientHomeNoCompaniesAvailable;

  /// No description provided for @clientHomeNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientHomeNewBadge;

  /// No description provided for @clientHomeCoachCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coach} other{{count} coaches}}'**
  String clientHomeCoachCount(int count);

  /// No description provided for @clientHomeCoachingDefault.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get clientHomeCoachingDefault;

  /// No description provided for @clientHomeCountryDefault.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get clientHomeCountryDefault;

  /// No description provided for @clientHomeCompanyReviewsCount.
  ///
  /// In en, this message translates to:
  /// **' ({count, plural, =1{1 review} other{{count} reviews}})'**
  String clientHomeCompanyReviewsCount(int count);

  /// No description provided for @clientHomeViewCoaches.
  ///
  /// In en, this message translates to:
  /// **'VIEW COACHES'**
  String get clientHomeViewCoaches;

  /// No description provided for @clientListLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get clientListLocationServicesDisabled;

  /// No description provided for @clientListLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get clientListLocationPermissionDenied;

  /// No description provided for @clientListLocationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get clientListLocationPermissionDeniedForever;

  /// No description provided for @clientListFetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get clientListFetchingLocation;

  /// No description provided for @clientListGetLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String clientListGetLocationFailed(String error);

  /// No description provided for @clientListServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode})'**
  String clientListServerError(int statusCode);

  /// No description provided for @clientListLoadRecommendationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recommendations. Please try again.'**
  String get clientListLoadRecommendationsFailed;

  /// No description provided for @clientListConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Please try again.'**
  String get clientListConnectFailed;

  /// No description provided for @clientListServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable.'**
  String get clientListServerUnreachable;

  /// No description provided for @clientListFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientListFiltersButton;

  /// No description provided for @clientListAllSpecialties.
  ///
  /// In en, this message translates to:
  /// **'All specialties'**
  String get clientListAllSpecialties;

  /// No description provided for @clientListFindACoach.
  ///
  /// In en, this message translates to:
  /// **'Find a coach'**
  String get clientListFindACoach;

  /// No description provided for @clientListMapToggle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get clientListMapToggle;

  /// No description provided for @clientListListToggle.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get clientListListToggle;

  /// No description provided for @clientListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search coaches, specialties...'**
  String get clientListSearchHint;

  /// No description provided for @clientListVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get clientListVerifiedOnly;

  /// No description provided for @clientListMinRatingChip.
  ///
  /// In en, this message translates to:
  /// **'{rating}+ Stars'**
  String clientListMinRatingChip(String rating);

  /// No description provided for @clientListFilterCoachesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter coaches'**
  String get clientListFilterCoachesTitle;

  /// No description provided for @clientListDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get clientListDone;

  /// No description provided for @clientListVerifiedOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show coaches verified by Sirvya'**
  String get clientListVerifiedOnlySubtitle;

  /// No description provided for @clientListSortByLabel.
  ///
  /// In en, this message translates to:
  /// **'SORT BY'**
  String get clientListSortByLabel;

  /// No description provided for @clientListSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get clientListSortRecommended;

  /// No description provided for @clientListSortPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get clientListSortPoints;

  /// No description provided for @clientListSortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get clientListSortAlphabetical;

  /// No description provided for @clientListSortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get clientListSortTopRated;

  /// No description provided for @clientListMinRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'MINIMUM RATING'**
  String get clientListMinRatingLabel;

  /// No description provided for @clientListClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientListClear;

  /// No description provided for @clientListAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientListAll;

  /// No description provided for @clientListCityLabel.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get clientListCityLabel;

  /// No description provided for @clientListLocationToBeDefined.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get clientListLocationToBeDefined;

  /// No description provided for @clientListCompanyIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get clientListCompanyIndependent;

  /// No description provided for @clientListNoCoachesInCity.
  ///
  /// In en, this message translates to:
  /// **'No coaches found in {city}'**
  String clientListNoCoachesInCity(String city);

  /// No description provided for @clientListNoCoachesFound.
  ///
  /// In en, this message translates to:
  /// **'No coaches found'**
  String get clientListNoCoachesFound;

  /// No description provided for @clientListCoachesFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coach found} other{{count} coaches found}}'**
  String clientListCoachesFoundCount(int count);

  /// No description provided for @clientListListViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get clientListListViewTooltip;

  /// No description provided for @clientListGridViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get clientListGridViewTooltip;

  /// No description provided for @clientListSortAction.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get clientListSortAction;

  /// No description provided for @clientListNoCompaniesInCity.
  ///
  /// In en, this message translates to:
  /// **'No companies found in {city}'**
  String clientListNoCompaniesInCity(String city);

  /// No description provided for @clientListNoCompaniesFound.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get clientListNoCompaniesFound;

  /// No description provided for @clientListRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientListRetry;

  /// No description provided for @clientListReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get clientListReset;

  /// No description provided for @clientListPremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get clientListPremiumBadge;

  /// No description provided for @clientListNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientListNewBadge;

  /// No description provided for @clientListAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Available today'**
  String get clientListAvailableToday;

  /// No description provided for @clientListPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clientListPriceFrom;

  /// No description provided for @clientListPriceCurrency.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD'**
  String clientListPriceCurrency(int price);

  /// No description provided for @clientListPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientListPriceLabel;

  /// No description provided for @clientListPriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get clientListPriceOnRequest;

  /// No description provided for @clientListViewAndBook.
  ///
  /// In en, this message translates to:
  /// **'View & book'**
  String get clientListViewAndBook;

  /// No description provided for @clientListCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get clientListCodeCopied;

  /// No description provided for @clientListNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get clientListNumberCopied;

  /// No description provided for @clientListViewCoachesBadge.
  ///
  /// In en, this message translates to:
  /// **'View coaches'**
  String get clientListViewCoachesBadge;

  /// No description provided for @clientListViewProfile.
  ///
  /// In en, this message translates to:
  /// **'VIEW PROFILE'**
  String get clientListViewProfile;

  /// No description provided for @clientCoachFavoritesServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode})'**
  String clientCoachFavoritesServerError(int statusCode);

  /// No description provided for @clientCoachFavoritesServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable'**
  String get clientCoachFavoritesServerUnreachable;

  /// No description provided for @clientCoachFavoritesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update favorites'**
  String get clientCoachFavoritesUpdateFailed;

  /// No description provided for @clientCoachFavoritesLocationToBeDefined.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get clientCoachFavoritesLocationToBeDefined;

  /// No description provided for @clientCoachFavoritesCompanyIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get clientCoachFavoritesCompanyIndependent;

  /// No description provided for @clientCoachFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get clientCoachFavoritesTitle;

  /// No description provided for @clientCoachFavoritesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get clientCoachFavoritesLoading;

  /// No description provided for @clientCoachFavoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coaches you like will appear here'**
  String get clientCoachFavoritesEmptySubtitle;

  /// No description provided for @clientCoachFavoritesSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coach saved} other{{count} coaches saved}}'**
  String clientCoachFavoritesSavedCount(int count);

  /// No description provided for @clientCoachFavoritesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your favorite coaches...'**
  String get clientCoachFavoritesSearchHint;

  /// No description provided for @clientCoachFavoritesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientCoachFavoritesRetry;

  /// No description provided for @clientCoachFavoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite coaches yet'**
  String get clientCoachFavoritesEmptyTitle;

  /// No description provided for @clientCoachFavoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a coach to save them here.'**
  String get clientCoachFavoritesEmptyMessage;

  /// No description provided for @clientCoachFavoritesFindACoach.
  ///
  /// In en, this message translates to:
  /// **'Find a coach'**
  String get clientCoachFavoritesFindACoach;

  /// No description provided for @clientCoachFavoritesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No coach matches your search'**
  String get clientCoachFavoritesNoResults;

  /// No description provided for @clientCoachFavoritesReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get clientCoachFavoritesReset;

  /// No description provided for @clientCoachFavoritesNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientCoachFavoritesNewBadge;

  /// No description provided for @clientCoachFavoritesViewProfile.
  ///
  /// In en, this message translates to:
  /// **'VIEW PROFILE'**
  String get clientCoachFavoritesViewProfile;

  /// No description provided for @clientCoachReviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load feedback. Pull down to retry.'**
  String get clientCoachReviewsLoadFailed;

  /// No description provided for @clientCoachReviewsMyFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'My feedback'**
  String get clientCoachReviewsMyFeedbackTitle;

  /// No description provided for @clientCoachReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews & Ratings'**
  String get clientCoachReviewsTitle;

  /// No description provided for @clientCoachReviewsAllCount.
  ///
  /// In en, this message translates to:
  /// **'All Reviews ({count})'**
  String clientCoachReviewsAllCount(int count);

  /// No description provided for @clientCoachReviewsStarCount.
  ///
  /// In en, this message translates to:
  /// **'{stars} Star Reviews ({count})'**
  String clientCoachReviewsStarCount(int stars, int count);

  /// No description provided for @clientCoachReviewsClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clientCoachReviewsClearFilter;

  /// No description provided for @clientCoachReviewsTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String clientCoachReviewsTotalCount(int count);

  /// No description provided for @clientCoachReviewsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String clientCoachReviewsFilterAll(int count);

  /// No description provided for @clientCoachReviewsEmptyStarFilter.
  ///
  /// In en, this message translates to:
  /// **'No reviews with {stars} stars yet'**
  String clientCoachReviewsEmptyStarFilter(int stars);

  /// No description provided for @clientCoachReviewsEmptyCoachView.
  ///
  /// In en, this message translates to:
  /// **'Your client feedback will appear here'**
  String get clientCoachReviewsEmptyCoachView;

  /// No description provided for @clientCoachReviewsEmptyClientView.
  ///
  /// In en, this message translates to:
  /// **'No reviews found'**
  String get clientCoachReviewsEmptyClientView;

  /// No description provided for @clientCoachReviewsMyReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'My review'**
  String get clientCoachReviewsMyReviewBadge;

  /// No description provided for @clientCompanyDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Advisor not found'**
  String get clientCompanyDetailNotFound;

  /// No description provided for @clientCompanyDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading advisor ({statusCode})'**
  String clientCompanyDetailLoadError(int statusCode);

  /// No description provided for @clientCompanyDetailVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get clientCompanyDetailVerifiedBadge;

  /// No description provided for @clientCompanyDetailStatCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get clientCompanyDetailStatCoaches;

  /// No description provided for @clientCompanyDetailStatInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get clientCompanyDetailStatInvitations;

  /// No description provided for @clientCompanyDetailStatPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get clientCompanyDetailStatPoints;

  /// No description provided for @clientCompanyDetailTabCoaches.
  ///
  /// In en, this message translates to:
  /// **'COACHES ({count})'**
  String clientCompanyDetailTabCoaches(int count);

  /// No description provided for @clientCompanyDetailTabAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get clientCompanyDetailTabAbout;

  /// No description provided for @clientCompanyDetailTabGallery.
  ///
  /// In en, this message translates to:
  /// **'GALLERY ({count})'**
  String clientCompanyDetailTabGallery(int count);

  /// No description provided for @clientCompanyDetailTabLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get clientCompanyDetailTabLocation;

  /// No description provided for @clientCompanyDetailNoCoaches.
  ///
  /// In en, this message translates to:
  /// **'No coaches linked yet'**
  String get clientCompanyDetailNoCoaches;

  /// No description provided for @clientCompanyDetailCertifiedCoach.
  ///
  /// In en, this message translates to:
  /// **'Certified coach'**
  String get clientCompanyDetailCertifiedCoach;

  /// No description provided for @clientCompanyDetailSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get clientCompanyDetailSectionProfile;

  /// No description provided for @clientCompanyDetailFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get clientCompanyDetailFullName;

  /// No description provided for @clientCompanyDetailEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientCompanyDetailEmail;

  /// No description provided for @clientCompanyDetailSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get clientCompanyDetailSpecialty;

  /// No description provided for @clientCompanyDetailCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get clientCompanyDetailCity;

  /// No description provided for @clientCompanyDetailGymName.
  ///
  /// In en, this message translates to:
  /// **'Gym name'**
  String get clientCompanyDetailGymName;

  /// No description provided for @clientCompanyDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get clientCompanyDetailAddress;

  /// No description provided for @clientCompanyDetailSectionStatistics.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get clientCompanyDetailSectionStatistics;

  /// No description provided for @clientCompanyDetailStatTeamCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches on the team'**
  String get clientCompanyDetailStatTeamCoaches;

  /// No description provided for @clientCompanyDetailStatTotalInvitations.
  ///
  /// In en, this message translates to:
  /// **'Total invitations'**
  String get clientCompanyDetailStatTotalInvitations;

  /// No description provided for @clientCompanyDetailStatTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get clientCompanyDetailStatTotalPoints;

  /// No description provided for @clientCompanyDetailNoGalleryImages.
  ///
  /// In en, this message translates to:
  /// **'No gym images yet'**
  String get clientCompanyDetailNoGalleryImages;

  /// No description provided for @clientCompanyDetailSectionAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get clientCompanyDetailSectionAddress;

  /// No description provided for @clientCompanyDetailAddressNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Address not provided'**
  String get clientCompanyDetailAddressNotProvided;

  /// No description provided for @clientCompanyDetailSectionMap.
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get clientCompanyDetailSectionMap;

  /// No description provided for @clientCompanyDetailLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get clientCompanyDetailLocationNotAvailable;

  /// No description provided for @clientCompanyDetailGymDefault.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get clientCompanyDetailGymDefault;

  /// No description provided for @clientCompanyDetailOpenMap.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get clientCompanyDetailOpenMap;

  /// No description provided for @clientCompanyDetailLoadingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get clientCompanyDetailLoadingErrorTitle;

  /// No description provided for @clientCompanyDetailRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get clientCompanyDetailRetry;

  /// No description provided for @clientCompanyDetailViewProfile.
  ///
  /// In en, this message translates to:
  /// **'VIEW PROFILE'**
  String get clientCompanyDetailViewProfile;

  /// No description provided for @clientCompanyDetailCoachDefault.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get clientCompanyDetailCoachDefault;

  /// No description provided for @clientCompanyDetailAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get clientCompanyDetailAnywhere;

  /// No description provided for @clientCompanyDetailNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientCompanyDetailNewBadge;

  /// No description provided for @clientCompanyDetailReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String clientCompanyDetailReviewsCount(int count);

  /// No description provided for @clientCompanyDetailInvitationsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} inv.'**
  String clientCompanyDetailInvitationsShort(int count);

  /// No description provided for @clientCompanyDetailPointsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String clientCompanyDetailPointsShort(int count);

  /// No description provided for @clientProfilServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode})'**
  String clientProfilServerError(int statusCode);

  /// No description provided for @clientProfilCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get clientProfilCheckConnection;

  /// No description provided for @clientProfilLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile. Please try again.'**
  String get clientProfilLoadFailed;

  /// No description provided for @clientProfilWeightLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your latest records. Tap Refresh history to try again.'**
  String get clientProfilWeightLoadFailed;

  /// No description provided for @clientProfilWeightSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save weight.'**
  String get clientProfilWeightSaveFailed;

  /// No description provided for @clientProfilWeightSaved.
  ///
  /// In en, this message translates to:
  /// **'Weight saved ✓'**
  String get clientProfilWeightSaved;

  /// No description provided for @clientProfilPhotoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your photo. Please try again.'**
  String get clientProfilPhotoSaveFailed;

  /// No description provided for @clientProfilPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated ✓'**
  String get clientProfilPhotoUpdated;

  /// No description provided for @clientProfilUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error'**
  String get clientProfilUploadError;

  /// No description provided for @clientProfilGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String clientProfilGenericError(String error);

  /// No description provided for @clientProfilNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add your first and last name.'**
  String get clientProfilNameRequired;

  /// No description provided for @clientProfilInvalidHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid height in centimetres.'**
  String get clientProfilInvalidHeight;

  /// No description provided for @clientProfilSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Error while saving.'**
  String get clientProfilSaveFailed;

  /// No description provided for @clientProfilServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get clientProfilServerUnreachable;

  /// No description provided for @clientProfilDeleteBlockedDefault.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete account right now.'**
  String get clientProfilDeleteBlockedDefault;

  /// No description provided for @clientProfilSendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code.'**
  String get clientProfilSendCodeFailed;

  /// No description provided for @clientProfilEnterFullCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code.'**
  String get clientProfilEnterFullCode;

  /// No description provided for @clientProfilVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed.'**
  String get clientProfilVerificationFailed;

  /// No description provided for @clientProfilDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get clientProfilDeleteAccountTitle;

  /// No description provided for @clientProfilDeletePermanentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent'**
  String get clientProfilDeletePermanentSubtitle;

  /// No description provided for @clientProfilDeleteWhatWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'What will be deleted:'**
  String get clientProfilDeleteWhatWillBeDeleted;

  /// No description provided for @clientProfilDeleteItemProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile and personal information'**
  String get clientProfilDeleteItemProfile;

  /// No description provided for @clientProfilDeleteItemSessions.
  ///
  /// In en, this message translates to:
  /// **'All sessions and booking history'**
  String get clientProfilDeleteItemSessions;

  /// No description provided for @clientProfilDeleteItemMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages and conversations'**
  String get clientProfilDeleteItemMessages;

  /// No description provided for @clientProfilDeleteItemWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight progress and fitness data'**
  String get clientProfilDeleteItemWeight;

  /// No description provided for @clientProfilDeleteUnderstandCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand this action is irreversible and all my data will be permanently deleted.'**
  String get clientProfilDeleteUnderstandCheckbox;

  /// No description provided for @clientProfilCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientProfilCancel;

  /// No description provided for @clientProfilSendCode.
  ///
  /// In en, this message translates to:
  /// **'SEND CODE'**
  String get clientProfilSendCode;

  /// No description provided for @clientProfilVerifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get clientProfilVerifyIdentityTitle;

  /// No description provided for @clientProfilVerifyCheckEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the code'**
  String get clientProfilVerifyCheckEmailSubtitle;

  /// No description provided for @clientProfilVerifyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email address to confirm account deletion.'**
  String get clientProfilVerifyInstructions;

  /// No description provided for @clientProfilCodeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {minutes}:{seconds}'**
  String clientProfilCodeExpiresIn(String minutes, String seconds);

  /// No description provided for @clientProfilCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get clientProfilCodeExpired;

  /// No description provided for @clientProfilResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get clientProfilResendCode;

  /// No description provided for @clientProfilBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get clientProfilBack;

  /// No description provided for @clientProfilDeleteAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get clientProfilDeleteAccountBtn;

  /// No description provided for @clientProfilGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get clientProfilGenderMale;

  /// No description provided for @clientProfilGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get clientProfilGenderFemale;

  /// No description provided for @clientProfilGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientProfilGenderOther;

  /// No description provided for @clientProfilPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated ✓'**
  String get clientProfilPasswordUpdated;

  /// No description provided for @clientProfilLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get clientProfilLoadingProfile;

  /// No description provided for @clientProfilRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientProfilRetry;

  /// No description provided for @clientProfilSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get clientProfilSaving;

  /// No description provided for @clientProfilSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get clientProfilSaveChanges;

  /// No description provided for @clientProfilHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get clientProfilHeaderTitle;

  /// No description provided for @clientProfilHeaderSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved.'**
  String get clientProfilHeaderSavedSubtitle;

  /// No description provided for @clientProfilHeaderDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little more you. A stronger journey.'**
  String get clientProfilHeaderDefaultSubtitle;

  /// No description provided for @clientProfilCancelEditingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get clientProfilCancelEditingTooltip;

  /// No description provided for @clientProfilEditProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get clientProfilEditProfileTooltip;

  /// No description provided for @clientProfilStatSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get clientProfilStatSessions;

  /// No description provided for @clientProfilStatCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get clientProfilStatCurrentWeight;

  /// No description provided for @clientProfilWeightValueKg.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String clientProfilWeightValueKg(String weight);

  /// No description provided for @clientProfilStatHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get clientProfilStatHeight;

  /// No description provided for @clientProfilHeightValueCm.
  ///
  /// In en, this message translates to:
  /// **'{height} cm'**
  String clientProfilHeightValueCm(String height);

  /// No description provided for @clientProfilTabMyDetails.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get clientProfilTabMyDetails;

  /// No description provided for @clientProfilTabMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My progress'**
  String get clientProfilTabMyProgress;

  /// No description provided for @clientProfilTabNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get clientProfilTabNutrition;

  /// No description provided for @clientProfilEditInstructions.
  ///
  /// In en, this message translates to:
  /// **'Make your changes below, then tap Save changes.'**
  String get clientProfilEditInstructions;

  /// No description provided for @clientProfilGroupAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get clientProfilGroupAboutTitle;

  /// No description provided for @clientProfilGroupAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The details that make this space yours.'**
  String get clientProfilGroupAboutSubtitle;

  /// No description provided for @clientProfilFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get clientProfilFirstName;

  /// No description provided for @clientProfilLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get clientProfilLastName;

  /// No description provided for @clientProfilHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get clientProfilHeightCm;

  /// No description provided for @clientProfilGroupInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your fitness interests'**
  String get clientProfilGroupInterestsTitle;

  /// No description provided for @clientProfilGroupInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 things you enjoy. We’ll use them to help you discover coaches.'**
  String get clientProfilGroupInterestsSubtitle;

  /// No description provided for @clientProfilGroupAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & location'**
  String get clientProfilGroupAccountTitle;

  /// No description provided for @clientProfilGroupAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your contact details up to date.'**
  String get clientProfilGroupAccountSubtitle;

  /// No description provided for @clientProfilEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get clientProfilEmailAddress;

  /// No description provided for @clientProfilAddEmail.
  ///
  /// In en, this message translates to:
  /// **'Add your email'**
  String get clientProfilAddEmail;

  /// No description provided for @clientProfilPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get clientProfilPhoneNumber;

  /// No description provided for @clientProfilAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get clientProfilAddPhone;

  /// No description provided for @clientProfilMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get clientProfilMyLocation;

  /// No description provided for @clientProfilSetCity.
  ///
  /// In en, this message translates to:
  /// **'Set your city'**
  String get clientProfilSetCity;

  /// No description provided for @clientProfilGroupSirvyaTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Sirvya'**
  String get clientProfilGroupSirvyaTitle;

  /// No description provided for @clientProfilGroupSirvyaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your people, your preferences, your peace of mind.'**
  String get clientProfilGroupSirvyaSubtitle;

  /// No description provided for @clientProfilFavoriteCoaches.
  ///
  /// In en, this message translates to:
  /// **'Favorite coaches'**
  String get clientProfilFavoriteCoaches;

  /// No description provided for @clientProfilFavoriteCoachesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your favorites close'**
  String get clientProfilFavoriteCoachesSubtitle;

  /// No description provided for @clientProfilNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientProfilNotifications;

  /// No description provided for @clientProfilNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates about your activity'**
  String get clientProfilNotificationsSubtitle;

  /// No description provided for @clientProfilPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password & security'**
  String get clientProfilPasswordSecurity;

  /// No description provided for @clientProfilPasswordSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your password'**
  String get clientProfilPasswordSecuritySubtitle;

  /// No description provided for @clientProfilBlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked accounts'**
  String get clientProfilBlockedAccounts;

  /// No description provided for @clientProfilBlockedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage who can contact you'**
  String get clientProfilBlockedAccountsSubtitle;

  /// No description provided for @clientProfilLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get clientProfilLogOut;

  /// No description provided for @clientProfilDeleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get clientProfilDeleteMyAccount;

  /// No description provided for @clientProfilChooseInterests.
  ///
  /// In en, this message translates to:
  /// **'Choose your interests'**
  String get clientProfilChooseInterests;

  /// No description provided for @clientProfilInterestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Interests could not be loaded. Try again to choose from the catalog.'**
  String get clientProfilInterestsLoadFailed;

  /// No description provided for @clientProfilTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get clientProfilTryAgain;

  /// No description provided for @clientProfilMaxInterests.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 interests.'**
  String get clientProfilMaxInterests;

  /// No description provided for @clientProfilGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get clientProfilGender;

  /// No description provided for @clientProfilNotAddedYet.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get clientProfilNotAddedYet;

  /// No description provided for @clientBookingHomeVisitLocation.
  ///
  /// In en, this message translates to:
  /// **'Home visit — arrange address with coach in messages'**
  String get clientBookingHomeVisitLocation;

  /// No description provided for @clientBookingDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Location to be arranged with coach in messages'**
  String get clientBookingDefaultLocation;

  /// No description provided for @clientBookingSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String clientBookingSessionLabel(int number);

  /// No description provided for @clientBookingLeadTimeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a session more than one hour from now.'**
  String get clientBookingLeadTimeError;

  /// No description provided for @clientBookingMultipleBookedSuccess.
  ///
  /// In en, this message translates to:
  /// **'All {count} sessions booked successfully!'**
  String clientBookingMultipleBookedSuccess(int count);

  /// No description provided for @clientBookingSingleBookedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking sent successfully!'**
  String get clientBookingSingleBookedSuccess;

  /// No description provided for @clientBookingErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Error ({code})'**
  String clientBookingErrorCode(int code);

  /// No description provided for @clientBookingServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get clientBookingServerUnreachable;

  /// No description provided for @clientBookingChoosePackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Package'**
  String get clientBookingChoosePackageTitle;

  /// No description provided for @clientBookingSelectPackageHeading.
  ///
  /// In en, this message translates to:
  /// **'Select a Package'**
  String get clientBookingSelectPackageHeading;

  /// No description provided for @clientBookingSelectPackageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the package that fits you best, or book without a package.'**
  String get clientBookingSelectPackageSubtitle;

  /// No description provided for @clientBookingContinueToBooking.
  ///
  /// In en, this message translates to:
  /// **'Continue to Booking'**
  String get clientBookingContinueToBooking;

  /// No description provided for @clientBookingPackageSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String clientBookingPackageSessionsCount(int count);

  /// No description provided for @clientBookingPriceMad.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD'**
  String clientBookingPriceMad(int price);

  /// No description provided for @clientBookingPriceToDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Price to discuss'**
  String get clientBookingPriceToDiscuss;

  /// No description provided for @clientBookingBookWithoutPackage.
  ///
  /// In en, this message translates to:
  /// **'Book without a package'**
  String get clientBookingBookWithoutPackage;

  /// No description provided for @clientBookingBookWithoutPackageSub.
  ///
  /// In en, this message translates to:
  /// **'Single session — price discussed with coach'**
  String get clientBookingBookWithoutPackageSub;

  /// No description provided for @clientBookingBannerPackagePrice.
  ///
  /// In en, this message translates to:
  /// **'{name} · {price} MAD'**
  String clientBookingBannerPackagePrice(String name, int price);

  /// No description provided for @clientBookingBannerPackageRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} · Price on request'**
  String clientBookingBannerPackageRequest(String name);

  /// No description provided for @clientBookingNoPackageSelected.
  ///
  /// In en, this message translates to:
  /// **'No package selected'**
  String get clientBookingNoPackageSelected;

  /// No description provided for @clientBookingPackageSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Package Sessions'**
  String get clientBookingPackageSessionsTitle;

  /// No description provided for @clientBookingScheduledProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} scheduled'**
  String clientBookingScheduledProgress(int completed, int total);

  /// No description provided for @clientBookingSelectDatesWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Select a date & time for each session ({price} MAD / session):'**
  String clientBookingSelectDatesWithPrice(int price);

  /// No description provided for @clientBookingSelectDatesNoPrice.
  ///
  /// In en, this message translates to:
  /// **'Select a date & time for each of the {total} sessions included in your package:'**
  String clientBookingSelectDatesNoPrice(int total);

  /// No description provided for @clientBookingSessionWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Session {number} · {price} MAD'**
  String clientBookingSessionWithPrice(int number, int price);

  /// No description provided for @clientBookingSelectingNow.
  ///
  /// In en, this message translates to:
  /// **'Selecting now...'**
  String get clientBookingSelectingNow;

  /// No description provided for @clientBookingTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get clientBookingTapToSelect;

  /// No description provided for @clientBookingHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a session'**
  String get clientBookingHeaderTitle;

  /// No description provided for @clientBookingCoachFallback.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get clientBookingCoachFallback;

  /// No description provided for @clientBookingAnywhereFallback.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get clientBookingAnywhereFallback;

  /// No description provided for @clientBookingNewCoach.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientBookingNewCoach;

  /// No description provided for @clientBookingReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String clientBookingReviewsCount(int count);

  /// No description provided for @clientBookingPricePerSession.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD/session'**
  String clientBookingPricePerSession(int price);

  /// No description provided for @clientBookingSessionDateHeader.
  ///
  /// In en, this message translates to:
  /// **'Session {number} Date · {month}'**
  String clientBookingSessionDateHeader(int number, String month);

  /// No description provided for @clientBookingWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get clientBookingWeekdayMon;

  /// No description provided for @clientBookingWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get clientBookingWeekdayTue;

  /// No description provided for @clientBookingWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get clientBookingWeekdayWed;

  /// No description provided for @clientBookingWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get clientBookingWeekdayThu;

  /// No description provided for @clientBookingWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get clientBookingWeekdayFri;

  /// No description provided for @clientBookingWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get clientBookingWeekdaySat;

  /// No description provided for @clientBookingWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get clientBookingWeekdaySun;

  /// No description provided for @clientBookingSessionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Session location'**
  String get clientBookingSessionLocationTitle;

  /// No description provided for @clientBookingLocationHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'My home'**
  String get clientBookingLocationHomeTitle;

  /// No description provided for @clientBookingLocationHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange your address with the coach in messages'**
  String get clientBookingLocationHomeSubtitle;

  /// No description provided for @clientBookingLocationGymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coach’s gym · confirm directions in messages'**
  String get clientBookingLocationGymSubtitle;

  /// No description provided for @clientBookingLocationTbdTitle.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get clientBookingLocationTbdTitle;

  /// No description provided for @clientBookingLocationTbdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agree on the meeting place with your coach in messages'**
  String get clientBookingLocationTbdSubtitle;

  /// No description provided for @clientBookingSessionTimeSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Session {number} Time slot'**
  String clientBookingSessionTimeSlotTitle(int number);

  /// No description provided for @clientBookingTimeSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Time slots'**
  String get clientBookingTimeSlotsTitle;

  /// No description provided for @clientBookingAvailableSlotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String clientBookingAvailableSlotsCount(int count);

  /// No description provided for @clientBookingSlotsFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get clientBookingSlotsFull;

  /// No description provided for @clientBookingDateForSession.
  ///
  /// In en, this message translates to:
  /// **'{date} · for Session {number}'**
  String clientBookingDateForSession(String date, int number);

  /// No description provided for @clientBookingSlotSelected.
  ///
  /// In en, this message translates to:
  /// **'✓ Selected'**
  String get clientBookingSlotSelected;

  /// No description provided for @clientBookingSlotDuration.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get clientBookingSlotDuration;

  /// No description provided for @clientBookingSlotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get clientBookingSlotBlocked;

  /// No description provided for @clientBookingSlotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get clientBookingSlotBooked;

  /// No description provided for @clientBookingLegendFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get clientBookingLegendFree;

  /// No description provided for @clientBookingLegendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get clientBookingLegendUnavailable;

  /// No description provided for @clientBookingConfirmAllSessions.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM ALL {total} SESSIONS'**
  String clientBookingConfirmAllSessions(int total);

  /// No description provided for @clientBookingSelectAllSessions.
  ///
  /// In en, this message translates to:
  /// **'SELECT ALL SESSIONS ({completed}/{total} CHOSEN)'**
  String clientBookingSelectAllSessions(int completed, int total);

  /// No description provided for @clientBookingConfirmWithTime.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM · {time}'**
  String clientBookingConfirmWithTime(String time);

  /// No description provided for @clientBookingChooseASlot.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A SLOT'**
  String get clientBookingChooseASlot;

  /// No description provided for @clientBookingSelectDateAndTimePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a date & time for Session {number}'**
  String clientBookingSelectDateAndTimePrompt(int number);

  /// No description provided for @clientBookingLocationYourGym.
  ///
  /// In en, this message translates to:
  /// **'Your gym'**
  String get clientBookingLocationYourGym;

  /// No description provided for @clientBookingConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get clientBookingConfirmDialogTitle;

  /// No description provided for @clientBookingNotYetRated.
  ///
  /// In en, this message translates to:
  /// **'Not yet rated'**
  String get clientBookingNotYetRated;

  /// No description provided for @clientBookingLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientBookingLabelDate;

  /// No description provided for @clientBookingLabelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clientBookingLabelTime;

  /// No description provided for @clientBookingScheduledSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Sessions ({count})'**
  String clientBookingScheduledSessionsCount(int count);

  /// No description provided for @clientBookingSessionDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String clientBookingSessionDateAtTime(String date, String time);

  /// No description provided for @clientBookingNotScheduledYet.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled yet'**
  String get clientBookingNotScheduledYet;

  /// No description provided for @clientBookingLabelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientBookingLabelLocation;

  /// No description provided for @clientBookingLabelPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientBookingLabelPackage;

  /// No description provided for @clientBookingLabelTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get clientBookingLabelTotalPrice;

  /// No description provided for @clientBookingTotalPriceMulti.
  ///
  /// In en, this message translates to:
  /// **'{total} MAD ({perSession} MAD / session)'**
  String clientBookingTotalPriceMulti(int total, int perSession);

  /// No description provided for @clientBookingTotalPriceSingle.
  ///
  /// In en, this message translates to:
  /// **'{total} MAD / session'**
  String clientBookingTotalPriceSingle(int total);

  /// No description provided for @clientBookingBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get clientBookingBtnCancel;

  /// No description provided for @clientBookingBtnConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get clientBookingBtnConfirm;

  /// No description provided for @clientCoachDetailRemovedFavorite.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get clientCoachDetailRemovedFavorite;

  /// No description provided for @clientCoachDetailAddedFavorite.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites ✓'**
  String get clientCoachDetailAddedFavorite;

  /// No description provided for @clientCoachDetailFavoriteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorites'**
  String get clientCoachDetailFavoriteUpdateFailed;

  /// No description provided for @clientCoachDetailConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get clientCoachDetailConnectionFailed;

  /// No description provided for @clientCoachDetailErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Error {code}'**
  String clientCoachDetailErrorCode(int code);

  /// No description provided for @clientCoachDetailServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get clientCoachDetailServerUnreachable;

  /// No description provided for @clientCoachDetailSelectRatingFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a rating first'**
  String get clientCoachDetailSelectRatingFirst;

  /// No description provided for @clientCoachDetailReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved ✓'**
  String get clientCoachDetailReviewSaved;

  /// No description provided for @clientCoachDetailServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get clientCoachDetailServerError;

  /// No description provided for @clientCoachDetailInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to the coach ✓'**
  String get clientCoachDetailInvitationSent;

  /// No description provided for @clientCoachDetailInvitationAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Invitation already sent'**
  String get clientCoachDetailInvitationAlreadySent;

  /// No description provided for @clientCoachDetailLoginToMessage.
  ///
  /// In en, this message translates to:
  /// **'Please login to message the coach'**
  String get clientCoachDetailLoginToMessage;

  /// No description provided for @clientCoachDetailConversationStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to start conversation. Please try again.'**
  String get clientCoachDetailConversationStartFailed;

  /// No description provided for @clientCoachDetailReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get clientCoachDetailReportReasonSpam;

  /// No description provided for @clientCoachDetailReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get clientCoachDetailReportReasonHarassment;

  /// No description provided for @clientCoachDetailReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get clientCoachDetailReportReasonInappropriate;

  /// No description provided for @clientCoachDetailReportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud / Scam'**
  String get clientCoachDetailReportReasonFraud;

  /// No description provided for @clientCoachDetailReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientCoachDetailReportReasonOther;

  /// No description provided for @clientCoachDetailReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String clientCoachDetailReportTitle(String name);

  /// No description provided for @clientCoachDetailReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this user? We take these reports seriously.'**
  String get clientCoachDetailReportPrompt;

  /// No description provided for @clientCoachDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientCoachDetailCancel;

  /// No description provided for @clientCoachDetailSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get clientCoachDetailSubmit;

  /// No description provided for @clientCoachDetailReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully.'**
  String get clientCoachDetailReportSubmitted;

  /// No description provided for @clientCoachDetailReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get clientCoachDetailReportFailed;

  /// No description provided for @clientCoachDetailNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get clientCoachDetailNetworkError;

  /// No description provided for @clientCoachDetailBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String clientCoachDetailBlockTitle(String name);

  /// No description provided for @clientCoachDetailBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.'**
  String get clientCoachDetailBlockMessage;

  /// No description provided for @clientCoachDetailBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get clientCoachDetailBlockConfirm;

  /// No description provided for @clientCoachDetailUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get clientCoachDetailUserBlocked;

  /// No description provided for @clientCoachDetailBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user'**
  String get clientCoachDetailBlockFailed;

  /// No description provided for @clientCoachDetailQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach QR Code'**
  String get clientCoachDetailQrTitle;

  /// No description provided for @clientCoachDetailCertificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get clientCoachDetailCertificationsTitle;

  /// No description provided for @clientCoachDetailVerifiedBySirvya.
  ///
  /// In en, this message translates to:
  /// **'Verified by Sirvya'**
  String get clientCoachDetailVerifiedBySirvya;

  /// No description provided for @clientCoachDetailSelfReported.
  ///
  /// In en, this message translates to:
  /// **'Self-reported'**
  String get clientCoachDetailSelfReported;

  /// No description provided for @clientCoachDetailCoachingPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching packages'**
  String get clientCoachDetailCoachingPackagesTitle;

  /// No description provided for @clientCoachDetailNoPackagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No packages available for this coach.'**
  String get clientCoachDetailNoPackagesAvailable;

  /// No description provided for @clientCoachDetailPriceMad.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD'**
  String clientCoachDetailPriceMad(int price);

  /// No description provided for @clientCoachDetailPackageSessionInfo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session · 60 min} other{{count} sessions · 60 min each}}'**
  String clientCoachDetailPackageSessionInfo(int count);

  /// No description provided for @clientCoachDetailChooseAndBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get clientCoachDetailChooseAndBook;

  /// No description provided for @clientCoachDetailSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all >'**
  String get clientCoachDetailSeeAll;

  /// No description provided for @clientCoachDetailAgreeOnPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Agree on the price before confirmation.'**
  String get clientCoachDetailAgreeOnPriceNote;

  /// No description provided for @clientCoachDetailOnRequest.
  ///
  /// In en, this message translates to:
  /// **'On request'**
  String get clientCoachDetailOnRequest;

  /// No description provided for @clientCoachDetailBookChip.
  ///
  /// In en, this message translates to:
  /// **'Book >'**
  String get clientCoachDetailBookChip;

  /// No description provided for @clientCoachDetailAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Available today'**
  String get clientCoachDetailAvailableToday;

  /// No description provided for @clientCoachDetailReportCoachMenu.
  ///
  /// In en, this message translates to:
  /// **'Report Coach'**
  String get clientCoachDetailReportCoachMenu;

  /// No description provided for @clientCoachDetailBlockCoachMenu.
  ///
  /// In en, this message translates to:
  /// **'Block Coach'**
  String get clientCoachDetailBlockCoachMenu;

  /// No description provided for @clientCoachDetailStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientCoachDetailStatRating;

  /// No description provided for @clientCoachDetailStatReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get clientCoachDetailStatReviews;

  /// No description provided for @clientCoachDetailStatClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientCoachDetailStatClients;

  /// No description provided for @clientCoachDetailPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price} MAD'**
  String clientCoachDetailPriceFrom(String price);

  /// No description provided for @clientCoachDetailPriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get clientCoachDetailPriceOnRequest;

  /// No description provided for @clientCoachDetailSessionRatesFrom.
  ///
  /// In en, this message translates to:
  /// **'Session rates starting from {price} MAD'**
  String clientCoachDetailSessionRatesFrom(String price);

  /// No description provided for @clientCoachDetailContactForRates.
  ///
  /// In en, this message translates to:
  /// **'Contact the coach for session rates'**
  String get clientCoachDetailContactForRates;

  /// No description provided for @clientCoachDetailMessageBtn.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientCoachDetailMessageBtn;

  /// No description provided for @clientCoachDetailRequestBookingBtn.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get clientCoachDetailRequestBookingBtn;

  /// No description provided for @clientCoachDetailSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get clientCoachDetailSpecialtiesTitle;

  /// No description provided for @clientCoachDetailAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get clientCoachDetailAboutTitle;

  /// No description provided for @clientCoachDetailGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching gallery'**
  String get clientCoachDetailGalleryTitle;

  /// No description provided for @clientCoachDetailViewAllCount.
  ///
  /// In en, this message translates to:
  /// **'View all ({count})'**
  String clientCoachDetailViewAllCount(int count);

  /// No description provided for @clientCoachDetailCoachingFallback.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get clientCoachDetailCoachingFallback;

  /// No description provided for @clientCoachDetailAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get clientCoachDetailAvailabilityTitle;

  /// No description provided for @clientCoachDetailNoSlotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No slots available'**
  String get clientCoachDetailNoSlotsAvailable;

  /// No description provided for @clientCoachDetailAssociatedGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Associated gym'**
  String get clientCoachDetailAssociatedGymTitle;

  /// No description provided for @clientCoachDetailPracticalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Practical info'**
  String get clientCoachDetailPracticalInfoTitle;

  /// No description provided for @clientCoachDetailCityDefault.
  ///
  /// In en, this message translates to:
  /// **'Casablanca'**
  String get clientCoachDetailCityDefault;

  /// No description provided for @clientCoachDetailQrRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach QR code'**
  String get clientCoachDetailQrRowLabel;

  /// No description provided for @clientCoachDetailTapToEnlarge.
  ///
  /// In en, this message translates to:
  /// **'Tap to enlarge'**
  String get clientCoachDetailTapToEnlarge;

  /// No description provided for @clientCoachDetailClientReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client reviews'**
  String get clientCoachDetailClientReviewsTitle;

  /// No description provided for @clientCoachDetailRatingSummary.
  ///
  /// In en, this message translates to:
  /// **'{rating} · {count, plural, =1{1 review} other{{count} reviews}} >'**
  String clientCoachDetailRatingSummary(String rating, int count);

  /// No description provided for @clientCoachDetailEditMyReview.
  ///
  /// In en, this message translates to:
  /// **'Edit my review'**
  String get clientCoachDetailEditMyReview;

  /// No description provided for @clientCoachDetailLeaveAReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get clientCoachDetailLeaveAReview;

  /// No description provided for @clientCoachDetailViewAllReviewsBtn.
  ///
  /// In en, this message translates to:
  /// **'View all {count} reviews'**
  String clientCoachDetailViewAllReviewsBtn(int count);

  /// No description provided for @clientCoachDetailYourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get clientCoachDetailYourRatingLabel;

  /// No description provided for @clientCoachDetailCommentOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get clientCoachDetailCommentOptionalLabel;

  /// No description provided for @clientCoachDetailReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with this coach…'**
  String get clientCoachDetailReviewHint;

  /// No description provided for @clientCoachDetailUpdateReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Update review'**
  String get clientCoachDetailUpdateReviewBtn;

  /// No description provided for @clientCoachDetailPublishReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get clientCoachDetailPublishReviewBtn;

  /// No description provided for @clientCoachDetailMyReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'My review'**
  String get clientCoachDetailMyReviewBadge;

  /// No description provided for @clientCoachDetailNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get clientCoachDetailNoReviewsYet;

  /// No description provided for @clientCoachDetailBeFirstToReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share your experience'**
  String get clientCoachDetailBeFirstToReview;

  /// No description provided for @clientCoachDetailRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clientCoachDetailRetry;

  /// No description provided for @clientSessionsServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error ({code})'**
  String clientSessionsServerError(int code);

  /// No description provided for @clientSessionsCheckConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get clientSessionsCheckConnectionError;

  /// No description provided for @clientSessionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your sessions. Please try again.'**
  String get clientSessionsLoadError;

  /// No description provided for @clientSessionsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh sessions'**
  String get clientSessionsRefreshTooltip;

  /// No description provided for @clientSessionsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed} other{{count} completed}}'**
  String clientSessionsCompletedCount(int count);

  /// No description provided for @clientSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My sessions'**
  String get clientSessionsTitle;

  /// No description provided for @clientSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your coaching appointments.'**
  String get clientSessionsSubtitle;

  /// No description provided for @clientSessionsTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String clientSessionsTabUpcoming(int count);

  /// No description provided for @clientSessionsTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past ({count})'**
  String clientSessionsTabPast(int count);

  /// No description provided for @clientSessionsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get clientSessionsTryAgain;

  /// No description provided for @clientSessionsEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming sessions.'**
  String get clientSessionsEmptyUpcoming;

  /// No description provided for @clientSessionsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'No past sessions.'**
  String get clientSessionsEmptyPast;

  /// No description provided for @clientSessionsConfirmedWhenAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your session is confirmed once the coach accepts.'**
  String get clientSessionsConfirmedWhenAccepted;

  /// No description provided for @clientSessionsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help with a booking?'**
  String get clientSessionsHelpTitle;

  /// No description provided for @clientSessionsHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch and we\'ll be happy to help.'**
  String get clientSessionsHelpSubtitle;

  /// No description provided for @clientSessionsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get clientSessionsContactSupport;

  /// No description provided for @clientSessionsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientSessionsFilterAll;

  /// No description provided for @clientSessionsFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get clientSessionsFilterCompleted;

  /// No description provided for @clientSessionsFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clientSessionsFilterCancelled;

  /// No description provided for @clientSessionsCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel session'**
  String get clientSessionsCancelDialogTitle;

  /// No description provided for @clientSessionsCancelDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get clientSessionsCancelDialogMessage;

  /// No description provided for @clientSessionsCancelDialogNo.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get clientSessionsCancelDialogNo;

  /// No description provided for @clientSessionsCancelDialogYes.
  ///
  /// In en, this message translates to:
  /// **'YES, CANCEL'**
  String get clientSessionsCancelDialogYes;

  /// No description provided for @clientSessionsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get clientSessionsStatusCompleted;

  /// No description provided for @clientSessionsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get clientSessionsStatusPending;

  /// No description provided for @clientSessionsStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get clientSessionsStatusExpired;

  /// No description provided for @clientSessionsStatusPriceDeclined.
  ///
  /// In en, this message translates to:
  /// **'Price declined'**
  String get clientSessionsStatusPriceDeclined;

  /// No description provided for @clientSessionsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clientSessionsStatusCancelled;

  /// No description provided for @clientSessionsPriceOfferReady.
  ///
  /// In en, this message translates to:
  /// **'Price offer ready — open details to approve.'**
  String get clientSessionsPriceOfferReady;

  /// No description provided for @clientSessionsAwaitingPrice.
  ///
  /// In en, this message translates to:
  /// **'Awaiting coach’s price.'**
  String get clientSessionsAwaitingPrice;

  /// No description provided for @clientSessionsAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting coach confirmation.'**
  String get clientSessionsAwaitingConfirmation;

  /// No description provided for @clientSessionsCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you'**
  String get clientSessionsCancelledByYou;

  /// No description provided for @clientSessionsPriceMad.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD'**
  String clientSessionsPriceMad(int price);

  /// No description provided for @clientSessionsDurationMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String clientSessionsDurationMin(int minutes);

  /// No description provided for @clientSessionsLocationTbc.
  ///
  /// In en, this message translates to:
  /// **'Location to be confirmed'**
  String get clientSessionsLocationTbc;

  /// No description provided for @clientSessionsSessionPriceWithPkg.
  ///
  /// In en, this message translates to:
  /// **'Session price ({packageName})'**
  String clientSessionsSessionPriceWithPkg(String packageName);

  /// No description provided for @clientSessionsSessionTotal.
  ///
  /// In en, this message translates to:
  /// **'Session total'**
  String get clientSessionsSessionTotal;

  /// No description provided for @clientSessionsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details >'**
  String get clientSessionsViewDetails;

  /// No description provided for @clientSessionsBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again >'**
  String get clientSessionsBookAgain;

  /// No description provided for @clientSessionsEditReviewRating.
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating}/5 '**
  String clientSessionsEditReviewRating(int rating);

  /// No description provided for @clientSessionsLeaveAReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get clientSessionsLeaveAReview;

  /// No description provided for @clientSessionsMessageBtn.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientSessionsMessageBtn;

  /// No description provided for @clientSessionsCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get clientSessionsCancelBooking;

  /// No description provided for @clientSessionDetailAcceptPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept proposed price?'**
  String get clientSessionDetailAcceptPriceTitle;

  /// No description provided for @clientSessionDetailDeclinePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline proposed price?'**
  String get clientSessionDetailDeclinePriceTitle;

  /// No description provided for @clientSessionDetailAcceptPriceMessage.
  ///
  /// In en, this message translates to:
  /// **'Accept {price} MAD and confirm this session?'**
  String clientSessionDetailAcceptPriceMessage(String price);

  /// No description provided for @clientSessionDetailDeclinePriceMessage.
  ///
  /// In en, this message translates to:
  /// **'Declining will cancel this booking request.'**
  String get clientSessionDetailDeclinePriceMessage;

  /// No description provided for @clientSessionDetailAcceptConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT & CONFIRM'**
  String get clientSessionDetailAcceptConfirmBtn;

  /// No description provided for @clientSessionDetailDeclinePriceBtn.
  ///
  /// In en, this message translates to:
  /// **'DECLINE PRICE'**
  String get clientSessionDetailDeclinePriceBtn;

  /// No description provided for @clientSessionDetailPriceRespondError.
  ///
  /// In en, this message translates to:
  /// **'Could not respond to price.'**
  String get clientSessionDetailPriceRespondError;

  /// No description provided for @clientSessionDetailConnectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Connection unavailable. Please try again.'**
  String get clientSessionDetailConnectionUnavailable;

  /// No description provided for @clientSessionDetailPriceExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Price request expired'**
  String get clientSessionDetailPriceExpiredTitle;

  /// No description provided for @clientSessionDetailApprovePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve your session price'**
  String get clientSessionDetailApprovePriceTitle;

  /// No description provided for @clientSessionDetailAwaitingPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting coach’s price'**
  String get clientSessionDetailAwaitingPriceTitle;

  /// No description provided for @clientSessionDetailPriceExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'No price was agreed before the deadline. Please make a new booking.'**
  String get clientSessionDetailPriceExpiredBody;

  /// No description provided for @clientSessionDetailProposedPriceBody.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD per session. Your acceptance confirms this booking.'**
  String clientSessionDetailProposedPriceBody(String price);

  /// No description provided for @clientSessionDetailAwaitingPriceBody.
  ///
  /// In en, this message translates to:
  /// **'Your coach will send a price offer. You must accept it to confirm the session.'**
  String get clientSessionDetailAwaitingPriceBody;

  /// No description provided for @clientSessionDetailPriceDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date} · {time} (2 hours before the session)'**
  String clientSessionDetailPriceDeadline(String date, String time);

  /// No description provided for @clientSessionDetailAcceptAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept & confirm'**
  String get clientSessionDetailAcceptAndConfirm;

  /// No description provided for @clientSessionDetailDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get clientSessionDetailDecline;

  /// No description provided for @clientSessionDetailStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get clientSessionDetailStatusExpired;

  /// No description provided for @clientSessionDetailStatusPriceDeclined.
  ///
  /// In en, this message translates to:
  /// **'PRICE DECLINED'**
  String get clientSessionDetailStatusPriceDeclined;

  /// No description provided for @clientSessionDetailStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get clientSessionDetailStatusPending;

  /// No description provided for @clientSessionDetailStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get clientSessionDetailStatusConfirmed;

  /// No description provided for @clientSessionDetailStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get clientSessionDetailStatusCancelled;

  /// No description provided for @clientSessionDetailCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel session?'**
  String get clientSessionDetailCancelTitle;

  /// No description provided for @clientSessionDetailCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get clientSessionDetailCancelMessage;

  /// No description provided for @clientSessionDetailCancelConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL SESSION'**
  String get clientSessionDetailCancelConfirmBtn;

  /// No description provided for @clientSessionDetailSessionCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Session cancelled.'**
  String get clientSessionDetailSessionCancelledSnack;

  /// No description provided for @clientSessionDetailCancelErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Error while cancelling.'**
  String get clientSessionDetailCancelErrorSnack;

  /// No description provided for @clientSessionDetailServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get clientSessionDetailServerUnreachable;

  /// No description provided for @clientSessionDetailReviewPublishedSnack.
  ///
  /// In en, this message translates to:
  /// **'Review published successfully!'**
  String get clientSessionDetailReviewPublishedSnack;

  /// No description provided for @clientSessionDetailReviewPublishErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Error while publishing.'**
  String get clientSessionDetailReviewPublishErrorSnack;

  /// No description provided for @clientSessionDetailDialogBack.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get clientSessionDetailDialogBack;

  /// No description provided for @clientSessionDetailTopBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get clientSessionDetailTopBarTitle;

  /// No description provided for @clientSessionDetailBannerPriceProposed.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD · proposed'**
  String clientSessionDetailBannerPriceProposed(String price);

  /// No description provided for @clientSessionDetailBannerPriceMad.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD'**
  String clientSessionDetailBannerPriceMad(int price);

  /// No description provided for @clientSessionDetailBannerFreeSession.
  ///
  /// In en, this message translates to:
  /// **'Free session'**
  String get clientSessionDetailBannerFreeSession;

  /// No description provided for @clientSessionDetailBannerAwaitingPricing.
  ///
  /// In en, this message translates to:
  /// **'Awaiting pricing'**
  String get clientSessionDetailBannerAwaitingPricing;

  /// No description provided for @clientSessionDetailDurationTimeRange.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {start} — {end}'**
  String clientSessionDetailDurationTimeRange(
      int minutes, String start, String end);

  /// No description provided for @clientSessionDetailPerSessionPackage.
  ///
  /// In en, this message translates to:
  /// **'Per session · {packageName}'**
  String clientSessionDetailPerSessionPackage(String packageName);

  /// No description provided for @clientSessionDetailInfoDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientSessionDetailInfoDate;

  /// No description provided for @clientSessionDetailInfoTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clientSessionDetailInfoTime;

  /// No description provided for @clientSessionDetailInfoDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get clientSessionDetailInfoDuration;

  /// No description provided for @clientSessionDetailDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String clientSessionDetailDurationMinutes(int minutes);

  /// No description provided for @clientSessionDetailInfoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientSessionDetailInfoLocation;

  /// No description provided for @clientSessionDetailLocationDefault.
  ///
  /// In en, this message translates to:
  /// **'Location to be arranged with coach in messages'**
  String get clientSessionDetailLocationDefault;

  /// No description provided for @clientSessionDetailInfoPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientSessionDetailInfoPackage;

  /// No description provided for @clientSessionDetailInfoRef.
  ///
  /// In en, this message translates to:
  /// **'Ref.'**
  String get clientSessionDetailInfoRef;

  /// No description provided for @clientSessionDetailCoachFallback.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get clientSessionDetailCoachFallback;

  /// No description provided for @clientSessionDetailAnywhereFallback.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get clientSessionDetailAnywhereFallback;

  /// No description provided for @clientSessionDetailNewCoach.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get clientSessionDetailNewCoach;

  /// No description provided for @clientSessionDetailBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get clientSessionDetailBtnCancel;

  /// No description provided for @clientSessionDetailApprovalExpiredReason.
  ///
  /// In en, this message translates to:
  /// **'The coach did not approve this booking before the one-hour deadline.'**
  String get clientSessionDetailApprovalExpiredReason;

  /// No description provided for @clientSessionDetailPriceNotAgreedReason.
  ///
  /// In en, this message translates to:
  /// **'The price was not agreed before the two-hour deadline.'**
  String get clientSessionDetailPriceNotAgreedReason;

  /// No description provided for @clientSessionDetailRequestExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Request expired'**
  String get clientSessionDetailRequestExpiredTitle;

  /// No description provided for @clientSessionDetailCancellationReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get clientSessionDetailCancellationReasonTitle;

  /// No description provided for @clientSessionDetailShareReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your review'**
  String get clientSessionDetailShareReviewTitle;

  /// No description provided for @clientSessionDetailShareReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help others choose the right coach'**
  String get clientSessionDetailShareReviewSubtitle;

  /// No description provided for @clientSessionDetailPublishedBadge.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED'**
  String get clientSessionDetailPublishedBadge;

  /// No description provided for @clientSessionDetailEditMyReview.
  ///
  /// In en, this message translates to:
  /// **'Edit my review'**
  String get clientSessionDetailEditMyReview;

  /// No description provided for @clientSessionDetailCancelEditing.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get clientSessionDetailCancelEditing;

  /// No description provided for @clientSessionDetailCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get clientSessionDetailCommentLabel;

  /// No description provided for @clientSessionDetailHowWasSession.
  ///
  /// In en, this message translates to:
  /// **'How was your session?'**
  String get clientSessionDetailHowWasSession;

  /// No description provided for @clientSessionDetailReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share the details... (optional)'**
  String get clientSessionDetailReviewHint;

  /// No description provided for @clientSessionDetailUpdateMyReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Review'**
  String get clientSessionDetailUpdateMyReviewBtn;

  /// No description provided for @clientSessionDetailPublishMyReviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish Review'**
  String get clientSessionDetailPublishMyReviewBtn;

  /// No description provided for @clientSessionDetailRating1.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get clientSessionDetailRating1;

  /// No description provided for @clientSessionDetailRating2.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get clientSessionDetailRating2;

  /// No description provided for @clientSessionDetailRating3.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get clientSessionDetailRating3;

  /// No description provided for @clientSessionDetailRating4.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get clientSessionDetailRating4;

  /// No description provided for @clientSessionDetailRating5.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get clientSessionDetailRating5;

  /// No description provided for @clientConversationDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get clientConversationDeletedMessage;

  /// No description provided for @clientConversationSelectLimitError.
  ///
  /// In en, this message translates to:
  /// **'Select up to 100 messages at a time.'**
  String get clientConversationSelectLimitError;

  /// No description provided for @clientConversationDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 message?} other{Delete {count} messages?}}'**
  String clientConversationDeleteDialogTitle(int count);

  /// No description provided for @clientConversationDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone is available for your own messages during the first 30 minutes.'**
  String get clientConversationDeleteDialogContent;

  /// No description provided for @clientConversationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientConversationCancel;

  /// No description provided for @clientConversationDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get clientConversationDeleteForMe;

  /// No description provided for @clientConversationDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get clientConversationDeleteForEveryone;

  /// No description provided for @clientConversationDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete messages.'**
  String get clientConversationDeleteFailed;

  /// No description provided for @clientConversationRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh messages. Check your connection.'**
  String get clientConversationRefreshError;

  /// No description provided for @clientConversationSendRetryError.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Your message is ready to retry.'**
  String get clientConversationSendRetryError;

  /// No description provided for @clientConversationAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get clientConversationAttachCamera;

  /// No description provided for @clientConversationAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get clientConversationAttachGallery;

  /// No description provided for @clientConversationCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get clientConversationCaptionHint;

  /// No description provided for @clientConversationSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get clientConversationSend;

  /// No description provided for @clientConversationImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get clientConversationImageUploadFailed;

  /// No description provided for @clientConversationSendPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the photo. Please try again.'**
  String get clientConversationSendPhotoError;

  /// No description provided for @clientConversationBatchLimitError.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 30 photos per batch.'**
  String get clientConversationBatchLimitError;

  /// No description provided for @clientConversationBatchFailedError.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo could not be sent. The others were sent.} other{{count} photos could not be sent. The others were sent.}}'**
  String clientConversationBatchFailedError(int count);

  /// No description provided for @clientConversationAudioUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio upload failed'**
  String get clientConversationAudioUploadFailed;

  /// No description provided for @clientConversationMicPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access for Sirvya in your phone Settings to record voice messages.'**
  String get clientConversationMicPermissionError;

  /// No description provided for @clientConversationAudioRecordError.
  ///
  /// In en, this message translates to:
  /// **'Could not record or send audio. Please try again.'**
  String get clientConversationAudioRecordError;

  /// No description provided for @clientConversationMediaSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send media message'**
  String get clientConversationMediaSendFailed;

  /// No description provided for @clientConversationNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get clientConversationNetworkError;

  /// No description provided for @clientConversationTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get clientConversationTitleFallback;

  /// No description provided for @clientConversationSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Fitness coach'**
  String get clientConversationSubtitleFallback;

  /// No description provided for @clientConversationMenuSelect.
  ///
  /// In en, this message translates to:
  /// **'Select messages'**
  String get clientConversationMenuSelect;

  /// No description provided for @clientConversationMenuRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh messages'**
  String get clientConversationMenuRefresh;

  /// No description provided for @clientConversationMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report Coach'**
  String get clientConversationMenuReport;

  /// No description provided for @clientConversationMenuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block Coach'**
  String get clientConversationMenuBlock;

  /// No description provided for @clientConversationReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get clientConversationReportReasonSpam;

  /// No description provided for @clientConversationReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get clientConversationReportReasonHarassment;

  /// No description provided for @clientConversationReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get clientConversationReportReasonInappropriate;

  /// No description provided for @clientConversationReportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud / Scam'**
  String get clientConversationReportReasonFraud;

  /// No description provided for @clientConversationReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientConversationReportReasonOther;

  /// No description provided for @clientConversationThisCoachFallback.
  ///
  /// In en, this message translates to:
  /// **'this coach'**
  String get clientConversationThisCoachFallback;

  /// No description provided for @clientConversationReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String clientConversationReportTitle(String name);

  /// No description provided for @clientConversationReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this user? We take these reports seriously.'**
  String get clientConversationReportPrompt;

  /// No description provided for @clientConversationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get clientConversationSubmit;

  /// No description provided for @clientConversationIdentifyCoachReportError.
  ///
  /// In en, this message translates to:
  /// **'Unable to identify coach to report'**
  String get clientConversationIdentifyCoachReportError;

  /// No description provided for @clientConversationReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully.'**
  String get clientConversationReportSubmitted;

  /// No description provided for @clientConversationReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get clientConversationReportFailed;

  /// No description provided for @clientConversationBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String clientConversationBlockTitle(String name);

  /// No description provided for @clientConversationBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.'**
  String get clientConversationBlockMessage;

  /// No description provided for @clientConversationBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get clientConversationBlockConfirm;

  /// No description provided for @clientConversationIdentifyCoachBlockError.
  ///
  /// In en, this message translates to:
  /// **'Unable to identify coach to block'**
  String get clientConversationIdentifyCoachBlockError;

  /// No description provided for @clientConversationUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get clientConversationUserBlocked;

  /// No description provided for @clientConversationBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user'**
  String get clientConversationBlockFailed;

  /// No description provided for @coachAccountBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get coachAccountBack;

  /// No description provided for @coachAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachAccountCancel;

  /// No description provided for @coachAccountCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String coachAccountCopiedToClipboard(String label);

  /// No description provided for @coachAccountDeleteCannotNow.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete account right now.'**
  String get coachAccountDeleteCannotNow;

  /// No description provided for @coachAccountDeleteCheckEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the 6-digit confirmation code.'**
  String get coachAccountDeleteCheckEmailSubtitle;

  /// No description provided for @coachAccountDeleteCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired.'**
  String get coachAccountDeleteCodeExpired;

  /// No description provided for @coachAccountDeleteCodeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {mins}:{secs}'**
  String coachAccountDeleteCodeExpiresIn(String mins, String secs);

  /// No description provided for @coachAccountDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get coachAccountDeleteConfirmButton;

  /// No description provided for @coachAccountDeleteEnterCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email to confirm deletion.'**
  String get coachAccountDeleteEnterCodeInstructions;

  /// No description provided for @coachAccountDeleteItem1.
  ///
  /// In en, this message translates to:
  /// **'Your coach profile and public visibility'**
  String get coachAccountDeleteItem1;

  /// No description provided for @coachAccountDeleteItem2.
  ///
  /// In en, this message translates to:
  /// **'Your packages, photos and certifications'**
  String get coachAccountDeleteItem2;

  /// No description provided for @coachAccountDeleteItem3.
  ///
  /// In en, this message translates to:
  /// **'Your conversation history and client links'**
  String get coachAccountDeleteItem3;

  /// No description provided for @coachAccountDeleteItem4.
  ///
  /// In en, this message translates to:
  /// **'All active and past reservation records'**
  String get coachAccountDeleteItem4;

  /// No description provided for @coachAccountDeletePermanentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone.'**
  String get coachAccountDeletePermanentSubtitle;

  /// No description provided for @coachAccountDeleteResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get coachAccountDeleteResendCode;

  /// No description provided for @coachAccountDeleteSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get coachAccountDeleteSendCodeButton;

  /// No description provided for @coachAccountDeleteSendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code. Please try again.'**
  String get coachAccountDeleteSendCodeFailed;

  /// No description provided for @coachAccountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Coach Account'**
  String get coachAccountDeleteTitle;

  /// No description provided for @coachAccountDeleteUnderstandCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand that deleting my account is permanent and irreversible.'**
  String get coachAccountDeleteUnderstandCheckbox;

  /// No description provided for @coachAccountDeleteVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Deletion'**
  String get coachAccountDeleteVerifyTitle;

  /// No description provided for @coachAccountDeleteWhatWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'The following data will be permanently removed:'**
  String get coachAccountDeleteWhatWillBeDeleted;

  /// No description provided for @coachAccountEnterFullCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code.'**
  String get coachAccountEnterFullCode;

  /// No description provided for @coachAccountServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Please check your connection.'**
  String get coachAccountServerUnreachable;

  /// No description provided for @coachAccountThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get coachAccountThemeDark;

  /// No description provided for @coachAccountThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get coachAccountThemeLight;

  /// No description provided for @coachAccountThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get coachAccountThemeSystem;

  /// No description provided for @coachAccountVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get coachAccountVerificationFailed;

  /// No description provided for @coachCalendarActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get coachCalendarActionAccept;

  /// No description provided for @coachCalendarActionAwaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Awaiting client response'**
  String get coachCalendarActionAwaitingClient;

  /// No description provided for @coachCalendarActionCancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reservation'**
  String get coachCalendarActionCancelReservation;

  /// No description provided for @coachCalendarActionProposePrice.
  ///
  /// In en, this message translates to:
  /// **'Propose Price'**
  String get coachCalendarActionProposePrice;

  /// No description provided for @coachCalendarActionReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get coachCalendarActionReject;

  /// No description provided for @coachCalendarAddBlockedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Add Blocked Time'**
  String get coachCalendarAddBlockedPeriod;

  /// No description provided for @coachCalendarAwaitingYourPriceOffer.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your price offer'**
  String get coachCalendarAwaitingYourPriceOffer;

  /// No description provided for @coachCalendarBlockHours.
  ///
  /// In en, this message translates to:
  /// **'Block specific hours'**
  String get coachCalendarBlockHours;

  /// No description provided for @coachCalendarBlockSpecificHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the time interval you want to make unavailable.'**
  String get coachCalendarBlockSpecificHoursSubtitle;

  /// No description provided for @coachCalendarBlockTheseHours.
  ///
  /// In en, this message translates to:
  /// **'Block These Hours'**
  String get coachCalendarBlockTheseHours;

  /// No description provided for @coachCalendarBlockedPeriodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Times you marked as unavailable for clients.'**
  String get coachCalendarBlockedPeriodsSubtitle;

  /// No description provided for @coachCalendarBlockedPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked Periods'**
  String get coachCalendarBlockedPeriodsTitle;

  /// No description provided for @coachCalendarCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachCalendarCancel;

  /// No description provided for @coachCalendarCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reservation'**
  String get coachCalendarCancelDialogTitle;

  /// No description provided for @coachCalendarConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get coachCalendarConfirm;

  /// No description provided for @coachCalendarDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{duration} min'**
  String coachCalendarDurationMinutes(int duration);

  /// No description provided for @coachCalendarEnterReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get coachCalendarEnterReasonHint;

  /// No description provided for @coachCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get coachCalendarFailed;

  /// No description provided for @coachCalendarLegendBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get coachCalendarLegendBlocked;

  /// No description provided for @coachCalendarLegendReservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get coachCalendarLegendReservation;

  /// No description provided for @coachCalendarLocationArranged.
  ///
  /// In en, this message translates to:
  /// **'Location by agreement'**
  String get coachCalendarLocationArranged;

  /// No description provided for @coachCalendarLocationGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get coachCalendarLocationGym;

  /// No description provided for @coachCalendarLocationHome.
  ///
  /// In en, this message translates to:
  /// **'Client\'s Home'**
  String get coachCalendarLocationHome;

  /// No description provided for @coachCalendarNoBlockedPeriods.
  ///
  /// In en, this message translates to:
  /// **'No blocked periods for this date.'**
  String get coachCalendarNoBlockedPeriods;

  /// No description provided for @coachCalendarNoReservationsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No reservations scheduled for this day.'**
  String get coachCalendarNoReservationsThisDay;

  /// No description provided for @coachCalendarNoteOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get coachCalendarNoteOptionalHint;

  /// No description provided for @coachCalendarPriceAwaitingClient.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD proposed · Awaiting client'**
  String coachCalendarPriceAwaitingClient(String price);

  /// No description provided for @coachCalendarPricePerSession.
  ///
  /// In en, this message translates to:
  /// **'{price} MAD / session'**
  String coachCalendarPricePerSession(String price);

  /// No description provided for @coachCalendarPricePerSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per session (MAD)'**
  String get coachCalendarPricePerSessionLabel;

  /// No description provided for @coachCalendarProposePriceBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your proposed price for this session.'**
  String get coachCalendarProposePriceBody;

  /// No description provided for @coachCalendarProposePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose a Price'**
  String get coachCalendarProposePriceTitle;

  /// No description provided for @coachCalendarRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Reservation'**
  String get coachCalendarRejectDialogTitle;

  /// No description provided for @coachCalendarReservationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservation Details'**
  String get coachCalendarReservationDetailsTitle;

  /// No description provided for @coachCalendarReservationNumber.
  ///
  /// In en, this message translates to:
  /// **'Reservation #{id}'**
  String coachCalendarReservationNumber(String id);

  /// No description provided for @coachCalendarReservationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reservation information unavailable.'**
  String get coachCalendarReservationUnavailable;

  /// No description provided for @coachCalendarSendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get coachCalendarSendOffer;

  /// No description provided for @coachCalendarSendPriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price.'**
  String get coachCalendarSendPriceError;

  /// No description provided for @coachCalendarSlotBooked.
  ///
  /// In en, this message translates to:
  /// **'Slot booked'**
  String get coachCalendarSlotBooked;

  /// No description provided for @coachCalendarStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get coachCalendarStatusCancelled;

  /// No description provided for @coachCalendarStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get coachCalendarStatusConfirmed;

  /// No description provided for @coachCalendarStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get coachCalendarStatusExpired;

  /// No description provided for @coachCalendarStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get coachCalendarStatusPending;

  /// No description provided for @coachCalendarStatusPriceDeclined.
  ///
  /// In en, this message translates to:
  /// **'Price declined'**
  String get coachCalendarStatusPriceDeclined;

  /// No description provided for @coachCalendarStatusPriceOffered.
  ///
  /// In en, this message translates to:
  /// **'Price offered'**
  String get coachCalendarStatusPriceOffered;

  /// No description provided for @coachCalendarTabAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get coachCalendarTabAvailability;

  /// No description provided for @coachCalendarTabReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get coachCalendarTabReservations;

  /// No description provided for @coachCalendarTimeEnd.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get coachCalendarTimeEnd;

  /// No description provided for @coachCalendarTimeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get coachCalendarTimeStart;

  /// No description provided for @coachCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get coachCalendarTitle;

  /// No description provided for @coachCalendarWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours: {start}:00 – {end}:00'**
  String coachCalendarWorkingHours(int start, int end);

  /// No description provided for @coachDashboardActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is your coaching activity overview.'**
  String get coachDashboardActivitySubtitle;

  /// No description provided for @coachDashboardAgreedPrices.
  ///
  /// In en, this message translates to:
  /// **'Agreed prices ({period})'**
  String coachDashboardAgreedPrices(String period);

  /// No description provided for @coachDashboardClientFallback.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get coachDashboardClientFallback;

  /// No description provided for @coachDashboardCoachFallback.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachDashboardCoachFallback;

  /// No description provided for @coachDashboardDaysAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String coachDashboardDaysAgoLong(int days);

  /// No description provided for @coachDashboardDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String coachDashboardDaysAgoShort(int days);

  /// No description provided for @coachDashboardFilterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get coachDashboardFilterThisMonth;

  /// No description provided for @coachDashboardFilterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get coachDashboardFilterThisWeek;

  /// No description provided for @coachDashboardFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get coachDashboardFilterToday;

  /// No description provided for @coachDashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get coachDashboardGoodMorning;

  /// No description provided for @coachDashboardHoursAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour ago} other{{hours} hours ago}}'**
  String coachDashboardHoursAgoLong(int hours);

  /// No description provided for @coachDashboardHoursAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String coachDashboardHoursAgoShort(int hours);

  /// No description provided for @coachDashboardInvitationPoints.
  ///
  /// In en, this message translates to:
  /// **'Invitation Points'**
  String get coachDashboardInvitationPoints;

  /// No description provided for @coachDashboardInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get coachDashboardInvitations;

  /// No description provided for @coachDashboardInvitationsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String coachDashboardInvitationsThisWeek(int count);

  /// No description provided for @coachDashboardJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get coachDashboardJustNow;

  /// No description provided for @coachDashboardLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard data. Check your connection.'**
  String get coachDashboardLoadErrorSubtitle;

  /// No description provided for @coachDashboardLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Dashboard'**
  String get coachDashboardLoadErrorTitle;

  /// No description provided for @coachDashboardMinutesAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute ago} other{{minutes} minutes ago}}'**
  String coachDashboardMinutesAgoLong(int minutes);

  /// No description provided for @coachDashboardMinutesAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String coachDashboardMinutesAgoShort(int minutes);

  /// No description provided for @coachDashboardNoNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates and reminders will show up here.'**
  String get coachDashboardNoNotificationsSubtitle;

  /// No description provided for @coachDashboardNoNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get coachDashboardNoNotificationsTitle;

  /// No description provided for @coachDashboardNoUpcomingReservationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings will appear here.'**
  String get coachDashboardNoUpcomingReservationsSubtitle;

  /// No description provided for @coachDashboardNoUpcomingReservationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Upcoming Sessions'**
  String get coachDashboardNoUpcomingReservationsTitle;

  /// No description provided for @coachDashboardNotificationFallback.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get coachDashboardNotificationFallback;

  /// No description provided for @coachDashboardNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get coachDashboardNotificationsTitle;

  /// No description provided for @coachDashboardPeriodClients.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 client ({period})} other{{count} clients ({period})}}'**
  String coachDashboardPeriodClients(int count, String period);

  /// No description provided for @coachDashboardPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get coachDashboardPeriodThisMonth;

  /// No description provided for @coachDashboardPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get coachDashboardPeriodThisWeek;

  /// No description provided for @coachDashboardPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get coachDashboardPeriodToday;

  /// No description provided for @coachDashboardRecentReservations.
  ///
  /// In en, this message translates to:
  /// **'Recent Reservations'**
  String get coachDashboardRecentReservations;

  /// No description provided for @coachDashboardRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachDashboardRetry;

  /// No description provided for @coachDashboardSetYourAvailability.
  ///
  /// In en, this message translates to:
  /// **'Set Your Availability'**
  String get coachDashboardSetYourAvailability;

  /// No description provided for @coachDashboardStatClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get coachDashboardStatClients;

  /// No description provided for @coachDashboardStatReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get coachDashboardStatReservations;

  /// No description provided for @coachDashboardStatRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue (MAD)'**
  String get coachDashboardStatRevenue;

  /// No description provided for @coachDashboardTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier: {tier}'**
  String coachDashboardTierLabel(int tier);

  /// No description provided for @coachDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get coachDashboardTitle;

  /// No description provided for @coachDashboardTotalClients.
  ///
  /// In en, this message translates to:
  /// **'Total Clients'**
  String get coachDashboardTotalClients;

  /// No description provided for @coachDashboardUpcomingReservations.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Sessions'**
  String get coachDashboardUpcomingReservations;

  /// No description provided for @coachDashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get coachDashboardViewAll;

  /// No description provided for @coachDashboardWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect · {timeAgo}'**
  String coachDashboardWantsToConnect(String timeAgo);

  /// No description provided for @coachEditProfileAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get coachEditProfileAdd;

  /// No description provided for @coachEditProfileAddCertificationButton.
  ///
  /// In en, this message translates to:
  /// **'Add Certification'**
  String get coachEditProfileAddCertificationButton;

  /// No description provided for @coachEditProfileAddCertificationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., NASM Certified Personal Trainer'**
  String get coachEditProfileAddCertificationHint;

  /// No description provided for @coachEditProfileAddCertificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Certification'**
  String get coachEditProfileAddCertificationTitle;

  /// No description provided for @coachEditProfileAddGalleryImageButton.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get coachEditProfileAddGalleryImageButton;

  /// No description provided for @coachEditProfileAddPackageButton.
  ///
  /// In en, this message translates to:
  /// **'Add Package'**
  String get coachEditProfileAddPackageButton;

  /// No description provided for @coachEditProfileAddSpecialtyButton.
  ///
  /// In en, this message translates to:
  /// **'Add Specialty'**
  String get coachEditProfileAddSpecialtyButton;

  /// No description provided for @coachEditProfileAddSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'Select or type specialty'**
  String get coachEditProfileAddSpecialtyHint;

  /// No description provided for @coachEditProfileAddSpecialtyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Specialty'**
  String get coachEditProfileAddSpecialtyTitle;

  /// No description provided for @coachEditProfileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Share your coaching philosophy, experience, and what clients can expect.'**
  String get coachEditProfileBioHint;

  /// No description provided for @coachEditProfileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get coachEditProfileBioLabel;

  /// No description provided for @coachEditProfileBioTitle.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get coachEditProfileBioTitle;

  /// No description provided for @coachEditProfileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachEditProfileCancel;

  /// No description provided for @coachEditProfileCertificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showcase your degrees and certifications.'**
  String get coachEditProfileCertificationsSubtitle;

  /// No description provided for @coachEditProfileCertificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get coachEditProfileCertificationsTitle;

  /// No description provided for @coachEditProfileCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Casablanca'**
  String get coachEditProfileCityHint;

  /// No description provided for @coachEditProfileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get coachEditProfileCityLabel;

  /// No description provided for @coachEditProfileDeletePackageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete package \"{name}\"?'**
  String coachEditProfileDeletePackageConfirm(String name);

  /// No description provided for @coachEditProfileDeletePackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Package'**
  String get coachEditProfileDeletePackageTitle;

  /// No description provided for @coachEditProfileDeletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from your gallery?'**
  String get coachEditProfileDeletePhotoConfirm;

  /// No description provided for @coachEditProfileDeletePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get coachEditProfileDeletePhotoTitle;

  /// No description provided for @coachEditProfileExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 5 years'**
  String get coachEditProfileExperienceHint;

  /// No description provided for @coachEditProfileExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get coachEditProfileExperienceLabel;

  /// No description provided for @coachEditProfileGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'High quality photos build client confidence.'**
  String get coachEditProfileGallerySubtitle;

  /// No description provided for @coachEditProfileGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get coachEditProfileGalleryTitle;

  /// No description provided for @coachEditProfileHourlyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 300'**
  String get coachEditProfileHourlyRateHint;

  /// No description provided for @coachEditProfileHourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (MAD)'**
  String get coachEditProfileHourlyRateLabel;

  /// No description provided for @coachEditProfileInstagramHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., coach_fitness'**
  String get coachEditProfileInstagramHint;

  /// No description provided for @coachEditProfileInstagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get coachEditProfileInstagramLabel;

  /// No description provided for @coachEditProfilePackageSessionsChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String coachEditProfilePackageSessionsChip(int count);

  /// No description provided for @coachEditProfilePackagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer multi-session discounts or specialized packs.'**
  String get coachEditProfilePackagesSubtitle;

  /// No description provided for @coachEditProfilePackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Packages'**
  String get coachEditProfilePackagesTitle;

  /// No description provided for @coachEditProfilePersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get coachEditProfilePersonalInfoTitle;

  /// No description provided for @coachEditProfilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get coachEditProfilePhoneLabel;

  /// No description provided for @coachEditProfileProfessionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Title'**
  String get coachEditProfileProfessionalTitle;

  /// No description provided for @coachEditProfileProfessionalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Strength & Conditioning Coach'**
  String get coachEditProfileProfessionalTitleHint;

  /// No description provided for @coachEditProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachEditProfileSave;

  /// No description provided for @coachEditProfileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get coachEditProfileSaveSuccess;

  /// No description provided for @coachEditProfileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coachEditProfileSaving;

  /// No description provided for @coachEditProfileSpecialtiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help clients find you by your areas of expertise.'**
  String get coachEditProfileSpecialtiesSubtitle;

  /// No description provided for @coachEditProfileSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get coachEditProfileSpecialtiesTitle;

  /// No description provided for @coachEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get coachEditProfileTitle;

  /// No description provided for @coachProfileAboutConfigured.
  ///
  /// In en, this message translates to:
  /// **'Biography configured'**
  String get coachProfileAboutConfigured;

  /// No description provided for @coachProfileAboutDefault.
  ///
  /// In en, this message translates to:
  /// **'No biography added yet.'**
  String get coachProfileAboutDefault;

  /// No description provided for @coachProfileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachProfileCancel;

  /// No description provided for @coachProfileCoachFallback.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachProfileCoachFallback;

  /// No description provided for @coachProfileCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Profile completed!'**
  String get coachProfileCompletedSnack;

  /// No description provided for @coachProfileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get coachProfileEditProfile;

  /// No description provided for @coachProfileInfoExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience: {exp}'**
  String coachProfileInfoExperience(String exp);

  /// No description provided for @coachProfileInfoLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages: {lang}'**
  String coachProfileInfoLanguages(String lang);

  /// No description provided for @coachProfileInfoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get coachProfileInfoLocation;

  /// No description provided for @coachProfileInfoProfessionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get coachProfileInfoProfessionalTitle;

  /// No description provided for @coachProfileInfoSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get coachProfileInfoSpecialties;

  /// No description provided for @coachProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load coach profile.'**
  String get coachProfileLoadError;

  /// No description provided for @coachProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get coachProfileLoading;

  /// No description provided for @coachProfileLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get coachProfileLocationNotSet;

  /// No description provided for @coachProfileLogOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get coachProfileLogOutConfirmMessage;

  /// No description provided for @coachProfileLogOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get coachProfileLogOutTitle;

  /// No description provided for @coachProfileMenuAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get coachProfileMenuAboutYou;

  /// No description provided for @coachProfileMenuAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get coachProfileMenuAccount;

  /// No description provided for @coachProfileMenuExpertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise & Specialties'**
  String get coachProfileMenuExpertise;

  /// No description provided for @coachProfileMenuFeedback.
  ///
  /// In en, this message translates to:
  /// **'My feedback'**
  String get coachProfileMenuFeedback;

  /// No description provided for @coachProfileMenuFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Client reviews and ratings'**
  String get coachProfileMenuFeedbackSubtitle;

  /// No description provided for @coachProfileMenuLocations.
  ///
  /// In en, this message translates to:
  /// **'Coaching Locations'**
  String get coachProfileMenuLocations;

  /// No description provided for @coachProfileMenuLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage gyms and training areas'**
  String get coachProfileMenuLocationsSubtitle;

  /// No description provided for @coachProfileMenuPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages & Pricing'**
  String get coachProfileMenuPackages;

  /// No description provided for @coachProfileMenuPackagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your session rates'**
  String get coachProfileMenuPackagesSubtitle;

  /// No description provided for @coachProfileMenuPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get coachProfileMenuPhotos;

  /// No description provided for @coachProfileMenuVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get coachProfileMenuVisibility;

  /// No description provided for @coachProfileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get coachProfileNotSet;

  /// No description provided for @coachProfilePersonalTrainerFallback.
  ///
  /// In en, this message translates to:
  /// **'Personal Trainer'**
  String get coachProfilePersonalTrainerFallback;

  /// No description provided for @coachProfilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get coachProfilePhotoUpdated;

  /// No description provided for @coachProfilePhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String coachProfilePhotosCount(int count);

  /// No description provided for @coachProfilePreviewProfile.
  ///
  /// In en, this message translates to:
  /// **'Preview Public Profile'**
  String get coachProfilePreviewProfile;

  /// No description provided for @coachProfileProfessionalInfoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No professional info provided.'**
  String get coachProfileProfessionalInfoEmpty;

  /// No description provided for @coachProfileProfessionalInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Professional Details'**
  String get coachProfileProfessionalInformationSection;

  /// No description provided for @coachProfilePublicProfileBadge.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get coachProfilePublicProfileBadge;

  /// No description provided for @coachProfileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachProfileRetry;

  /// No description provided for @coachProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile.'**
  String get coachProfileSaveError;

  /// No description provided for @coachProfileStatBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get coachProfileStatBookings;

  /// No description provided for @coachProfileStatClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get coachProfileStatClients;

  /// No description provided for @coachProfileStatPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get coachProfileStatPoints;

  /// No description provided for @coachProfileStepAvatar.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo to your profile.'**
  String get coachProfileStepAvatar;

  /// No description provided for @coachProfileStepBio.
  ///
  /// In en, this message translates to:
  /// **'Add your biography to your profile.'**
  String get coachProfileStepBio;

  /// No description provided for @coachProfileStepCertifications.
  ///
  /// In en, this message translates to:
  /// **'Add certifications to your profile.'**
  String get coachProfileStepCertifications;

  /// No description provided for @coachProfileStepCity.
  ///
  /// In en, this message translates to:
  /// **'Add your city to your profile.'**
  String get coachProfileStepCity;

  /// No description provided for @coachProfileStepClientLevels.
  ///
  /// In en, this message translates to:
  /// **'Specify accepted client levels.'**
  String get coachProfileStepClientLevels;

  /// No description provided for @coachProfileStepCoachingFormats.
  ///
  /// In en, this message translates to:
  /// **'Choose coaching formats.'**
  String get coachProfileStepCoachingFormats;

  /// No description provided for @coachProfileStepEmail.
  ///
  /// In en, this message translates to:
  /// **'Add your email to your profile.'**
  String get coachProfileStepEmail;

  /// No description provided for @coachProfileStepExperience.
  ///
  /// In en, this message translates to:
  /// **'Add your experience to your profile.'**
  String get coachProfileStepExperience;

  /// No description provided for @coachProfileStepFirstName.
  ///
  /// In en, this message translates to:
  /// **'Add your first name to your profile.'**
  String get coachProfileStepFirstName;

  /// No description provided for @coachProfileStepGallery.
  ///
  /// In en, this message translates to:
  /// **'Add photos to your gallery.'**
  String get coachProfileStepGallery;

  /// No description provided for @coachProfileStepGender.
  ///
  /// In en, this message translates to:
  /// **'Specify your gender.'**
  String get coachProfileStepGender;

  /// No description provided for @coachProfileStepGymAddress.
  ///
  /// In en, this message translates to:
  /// **'Add gym location.'**
  String get coachProfileStepGymAddress;

  /// No description provided for @coachProfileStepGymImage.
  ///
  /// In en, this message translates to:
  /// **'Add a gym photo.'**
  String get coachProfileStepGymImage;

  /// No description provided for @coachProfileStepGymName.
  ///
  /// In en, this message translates to:
  /// **'Add your gym name.'**
  String get coachProfileStepGymName;

  /// No description provided for @coachProfileStepInstagram.
  ///
  /// In en, this message translates to:
  /// **'Add your Instagram handle.'**
  String get coachProfileStepInstagram;

  /// No description provided for @coachProfileStepLanguages.
  ///
  /// In en, this message translates to:
  /// **'Add spoken languages.'**
  String get coachProfileStepLanguages;

  /// No description provided for @coachProfileStepLastName.
  ///
  /// In en, this message translates to:
  /// **'Add your last name.'**
  String get coachProfileStepLastName;

  /// No description provided for @coachProfileStepPackage.
  ///
  /// In en, this message translates to:
  /// **'Add a coaching package.'**
  String get coachProfileStepPackage;

  /// No description provided for @coachProfileStepPhone.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number.'**
  String get coachProfileStepPhone;

  /// No description provided for @coachProfileStepProfessionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your professional title.'**
  String get coachProfileStepProfessionalTitle;

  /// No description provided for @coachProfileStepServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Set your coaching zone.'**
  String get coachProfileStepServiceArea;

  /// No description provided for @coachProfileStepSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Select your specialties.'**
  String get coachProfileStepSpecialties;

  /// No description provided for @coachProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach Profile'**
  String get coachProfileTitle;

  /// No description provided for @coachProfileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo.'**
  String get coachProfileUploadFailed;

  /// No description provided for @coachClientDetailDisconnectInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect invitation'**
  String get coachClientDetailDisconnectInviteTitle;

  /// No description provided for @coachClientDetailDisconnectInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Disconnect your invitation with {name}? Clients with bookings remain visible so you can manage their sessions. Their account and sessions are kept.'**
  String coachClientDetailDisconnectInviteMessage(String name);

  /// No description provided for @coachClientDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachClientDetailCancel;

  /// No description provided for @coachClientDetailDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get coachClientDetailDisconnect;

  /// No description provided for @coachClientDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get coachClientDetailTitle;

  /// No description provided for @coachClientDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load client'**
  String get coachClientDetailLoadError;

  /// No description provided for @coachClientDetailRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachClientDetailRetry;

  /// No description provided for @coachClientDetailNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get coachClientDetailNoSessions;

  /// No description provided for @coachClientDetailReport.
  ///
  /// In en, this message translates to:
  /// **'Report Client'**
  String get coachClientDetailReport;

  /// No description provided for @coachClientDetailBlock.
  ///
  /// In en, this message translates to:
  /// **'Block Client'**
  String get coachClientDetailBlock;

  /// No description provided for @coachClientDetailReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String coachClientDetailReportTitle(String name);

  /// No description provided for @coachClientDetailReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this user? We take these reports seriously.'**
  String get coachClientDetailReportSubtitle;

  /// No description provided for @coachClientDetailSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get coachClientDetailSubmit;

  /// No description provided for @coachClientDetailBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String coachClientDetailBlockTitle(String name);

  /// No description provided for @coachClientDetailBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'They will not be able to book sessions or message you again.'**
  String get coachClientDetailBlockMessage;

  /// No description provided for @coachClientDetailBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get coachClientDetailBlockConfirm;

  /// No description provided for @coachDashboardStatConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get coachDashboardStatConfirmed;

  /// No description provided for @coachDashboardStatConfirmedValue.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Sessions'**
  String get coachDashboardStatConfirmedValue;

  /// No description provided for @coachDashboardStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get coachDashboardStatPending;

  /// No description provided for @coachDashboardStatusAcceptedPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String coachDashboardStatusAcceptedPoints(String points);

  /// No description provided for @coachDashboardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get coachDashboardStatusCancelled;

  /// No description provided for @coachDashboardStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get coachDashboardStatusConfirmed;

  /// No description provided for @coachDashboardStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get coachDashboardStatusDeclined;

  /// No description provided for @coachDashboardStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get coachDashboardStatusPending;

  /// No description provided for @coachDashboardStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get coachDashboardStatusUnknown;

  /// No description provided for @coachDashboardTierProgress.
  ///
  /// In en, this message translates to:
  /// **'{progress}% to {nextTier} · {remaining} pts left'**
  String coachDashboardTierProgress(int progress, int nextTier, int remaining);

  /// No description provided for @coachDashboardTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get coachDashboardTomorrow;

  /// No description provided for @coachDashboardYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get coachDashboardYesterday;

  /// No description provided for @coachProfileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get coachProfileCompletionTitle;

  /// No description provided for @coachProfileGalleryPreview.
  ///
  /// In en, this message translates to:
  /// **'Gallery Preview'**
  String get coachProfileGalleryPreview;

  /// No description provided for @coachProfileInfoBio.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get coachProfileInfoBio;

  /// No description provided for @coachProfileInfoCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get coachProfileInfoCertifications;

  /// No description provided for @coachEditProfileAddOtherSpecialty.
  ///
  /// In en, this message translates to:
  /// **'+ Add custom specialty'**
  String get coachEditProfileAddOtherSpecialty;

  /// No description provided for @coachEditProfileAddPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Package'**
  String get coachEditProfileAddPackageTitle;

  /// No description provided for @coachEditProfileBioRequired.
  ///
  /// In en, this message translates to:
  /// **'Biography is required.'**
  String get coachEditProfileBioRequired;

  /// No description provided for @coachEditProfileCertificationExists.
  ///
  /// In en, this message translates to:
  /// **'This certification is already added.'**
  String get coachEditProfileCertificationExists;

  /// No description provided for @coachEditProfileCustomSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Custom Specialties'**
  String get coachEditProfileCustomSpecialties;

  /// No description provided for @coachEditProfileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get coachEditProfileDelete;

  /// No description provided for @coachEditProfileDirectMessagingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow prospective clients to contact you before booking.'**
  String get coachEditProfileDirectMessagingSubtitle;

  /// No description provided for @coachEditProfileDirectMessagingTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Messaging'**
  String get coachEditProfileDirectMessagingTitle;

  /// No description provided for @coachEditProfileEditPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Package'**
  String get coachEditProfileEditPackageTitle;

  /// No description provided for @coachEditProfileEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get coachEditProfileEmailHint;

  /// No description provided for @coachEditProfileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get coachEditProfileEmailInvalid;

  /// No description provided for @coachEditProfileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get coachEditProfileEmailLabel;

  /// No description provided for @coachEditProfileEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get coachEditProfileEmailRequired;

  /// No description provided for @coachEditProfileEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get coachEditProfileEnterFullName;

  /// No description provided for @coachEditProfileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get coachEditProfileFullNameLabel;

  /// No description provided for @coachEditProfileFullNameValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get coachEditProfileFullNameValidator;

  /// No description provided for @coachEditProfileGalleryAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added to gallery.'**
  String get coachEditProfileGalleryAdded;

  /// No description provided for @coachEditProfileGalleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos in your gallery yet.'**
  String get coachEditProfileGalleryEmpty;

  /// No description provided for @coachEditProfileGalleryMaxImages.
  ///
  /// In en, this message translates to:
  /// **'Maximum 12 gallery photos allowed.'**
  String get coachEditProfileGalleryMaxImages;

  /// No description provided for @coachEditProfileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get coachEditProfileGenderFemale;

  /// No description provided for @coachEditProfileGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get coachEditProfileGenderLabel;

  /// No description provided for @coachEditProfileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get coachEditProfileGenderMale;

  /// No description provided for @coachEditProfileGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get coachEditProfileGenderOther;

  /// No description provided for @coachEditProfileGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get coachEditProfileGenericError;

  /// No description provided for @coachEditProfileImageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo removed from gallery.'**
  String get coachEditProfileImageDeleted;

  /// No description provided for @coachEditProfileMaxCertifications.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 certifications allowed.'**
  String get coachEditProfileMaxCertifications;

  /// No description provided for @coachEditProfileMaxPackagesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum packages limit reached.'**
  String get coachEditProfileMaxPackagesReached;

  /// No description provided for @coachEditProfileMaxSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Maximum 8 specialties allowed.'**
  String get coachEditProfileMaxSpecialties;

  /// No description provided for @coachEditProfileNoCertifications.
  ///
  /// In en, this message translates to:
  /// **'No certifications added yet.'**
  String get coachEditProfileNoCertifications;

  /// No description provided for @coachEditProfilePackageAdded.
  ///
  /// In en, this message translates to:
  /// **'Package created successfully.'**
  String get coachEditProfilePackageAdded;

  /// No description provided for @coachEditProfilePackageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Package deleted.'**
  String get coachEditProfilePackageDeleted;

  /// No description provided for @coachEditProfilePackageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what is included in this package...'**
  String get coachEditProfilePackageDescriptionHint;

  /// No description provided for @coachEditProfilePackageDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Description'**
  String get coachEditProfilePackageDescriptionLabel;

  /// No description provided for @coachEditProfilePackageHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden from clients'**
  String get coachEditProfilePackageHidden;

  /// No description provided for @coachEditProfilePackageNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 10-Session Kickstart'**
  String get coachEditProfilePackageNameHint;

  /// No description provided for @coachEditProfilePackageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get coachEditProfilePackageNameLabel;

  /// No description provided for @coachEditProfilePackageNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Package name is required.'**
  String get coachEditProfilePackageNameRequired;

  /// No description provided for @coachEditProfilePackageSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Number of sessions'**
  String get coachEditProfilePackageSessionsHint;

  /// No description provided for @coachEditProfilePackageSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Included Sessions'**
  String get coachEditProfilePackageSessionsLabel;

  /// No description provided for @coachEditProfilePackageSetPriceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clients will see this price when booking.'**
  String get coachEditProfilePackageSetPriceSubtitle;

  /// No description provided for @coachEditProfilePackageSetPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Price'**
  String get coachEditProfilePackageSetPriceTitle;

  /// No description provided for @coachEditProfilePackageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Package updated successfully.'**
  String get coachEditProfilePackageUpdated;

  /// No description provided for @coachEditProfilePackageVisibleToClients.
  ///
  /// In en, this message translates to:
  /// **'Visible to clients on your profile'**
  String get coachEditProfilePackageVisibleToClients;

  /// No description provided for @coachEditProfilePackagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the packs and session offers displayed on your public profile.'**
  String get coachEditProfilePackagesDescription;

  /// No description provided for @coachEditProfilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+212 6XX XXX XXX'**
  String get coachEditProfilePhoneHint;

  /// No description provided for @coachEditProfilePhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Photo ready to save.'**
  String get coachEditProfilePhotoReady;

  /// No description provided for @coachEditProfilePriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get coachEditProfilePriceOnRequest;

  /// No description provided for @coachEditProfileProfessionalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional Title'**
  String get coachEditProfileProfessionalTitleLabel;

  /// No description provided for @coachEditProfilePublicProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow clients to discover your profile in search results.'**
  String get coachEditProfilePublicProfileSubtitle;

  /// No description provided for @coachEditProfilePublicProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get coachEditProfilePublicProfileTitle;

  /// No description provided for @coachEditProfileSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get coachEditProfileSaveChangesButton;

  /// No description provided for @coachEditProfileSectionAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get coachEditProfileSectionAccountSettings;

  /// No description provided for @coachEditProfileSectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get coachEditProfileSectionBasicInfo;

  /// No description provided for @coachEditProfileSectionCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications & Credentials'**
  String get coachEditProfileSectionCertifications;

  /// No description provided for @coachEditProfileSectionContactLocation.
  ///
  /// In en, this message translates to:
  /// **'Contact & Location'**
  String get coachEditProfileSectionContactLocation;

  /// No description provided for @coachEditProfileSectionGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get coachEditProfileSectionGallery;

  /// No description provided for @coachEditProfileSectionPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages & Pricing'**
  String get coachEditProfileSectionPackages;

  /// No description provided for @coachEditProfileSectionSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Coaching Specialties'**
  String get coachEditProfileSectionSpecialties;

  /// No description provided for @coachEditProfileSpecialtiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the training areas you specialize in to match with the right clients.'**
  String get coachEditProfileSpecialtiesDescription;

  /// No description provided for @coachEditProfileSpecialtyExists.
  ///
  /// In en, this message translates to:
  /// **'This specialty is already added.'**
  String get coachEditProfileSpecialtyExists;

  /// No description provided for @coachEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your coaching info updated to attract more clients.'**
  String get coachEditProfileSubtitle;

  /// No description provided for @coachEditProfileUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get coachEditProfileUpdate;

  /// No description provided for @coachEditProfileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get coachEditProfileUpdateError;

  /// No description provided for @coachEditProfileUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get coachEditProfileUpdatedSnack;

  /// No description provided for @coachEditProfileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo.'**
  String get coachEditProfileUploadFailed;

  /// No description provided for @coachDashboardPercentOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of total'**
  String coachDashboardPercentOfTotal(String percent);

  /// No description provided for @coachDashboardVerificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in Progress'**
  String get coachDashboardVerificationPendingTitle;

  /// No description provided for @coachDashboardVerificationPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your credentials are being reviewed by the SIRVYA team.'**
  String get coachDashboardVerificationPendingBody;

  /// No description provided for @coachEditProfileErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {detail}'**
  String coachEditProfileErrorWithDetail(String detail);

  /// No description provided for @coachEditProfileGalleryLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You can only add up to {max} photos.'**
  String coachEditProfileGalleryLimitWarning(int max);

  /// No description provided for @coachEditProfileUploadFailedForFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload {file}'**
  String coachEditProfileUploadFailedForFile(String file);

  /// No description provided for @coachEditProfileImageDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove image.'**
  String get coachEditProfileImageDeleteFailed;

  /// No description provided for @coachEditProfileNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String coachEditProfileNetworkError(String error);

  /// No description provided for @coachProfileErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {detail}'**
  String coachProfileErrorWithDetail(String detail);

  /// No description provided for @coachCalendarBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get coachCalendarBlockAction;

  /// No description provided for @coachAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & referrals'**
  String get coachAccountTitle;

  /// No description provided for @coachAccountReferralTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach Referral'**
  String get coachAccountReferralTitle;

  /// No description provided for @coachAccountReferralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn rewards'**
  String get coachAccountReferralSubtitle;

  /// No description provided for @coachAccountCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get coachAccountCopy;

  /// No description provided for @coachAccountCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get coachAccountCode;

  /// No description provided for @coachAccountScanToInvite.
  ///
  /// In en, this message translates to:
  /// **'Scan to invite'**
  String get coachAccountScanToInvite;

  /// No description provided for @coachAccountCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get coachAccountCopyCode;

  /// No description provided for @coachAccountReferralRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} bonus points for every professional coach you onboard to the SIRVYA ecosystem.'**
  String coachAccountReferralRewardDesc(int points);

  /// No description provided for @coachAccountPrivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Private account'**
  String get coachAccountPrivateAccount;

  /// No description provided for @coachAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get coachAccountEmail;

  /// No description provided for @coachAccountChangeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change email with verification.'**
  String get coachAccountChangeEmailSubtitle;

  /// No description provided for @coachAccountEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully'**
  String get coachAccountEmailUpdated;

  /// No description provided for @coachAccountPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get coachAccountPhone;

  /// No description provided for @coachAccountPhoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone updated successfully'**
  String get coachAccountPhoneUpdated;

  /// No description provided for @coachAccountPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password & security'**
  String get coachAccountPasswordSecurity;

  /// No description provided for @coachAccountPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get coachAccountPasswordUpdated;

  /// No description provided for @coachAccountAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get coachAccountAppearance;

  /// No description provided for @coachAccountChooseAppTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose the app theme'**
  String get coachAccountChooseAppTheme;

  /// No description provided for @coachAccountNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get coachAccountNotifications;

  /// No description provided for @coachAccountBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get coachAccountBlockedUsers;

  /// No description provided for @coachAccountDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get coachAccountDeleteAccount;

  /// No description provided for @coachChatAudioRecordError.
  ///
  /// In en, this message translates to:
  /// **'Could not record voice note. Check permissions.'**
  String get coachChatAudioRecordError;

  /// No description provided for @coachChatAudioUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send audio message.'**
  String get coachChatAudioUploadFailed;

  /// No description provided for @coachChatBatchPartialFail.
  ///
  /// In en, this message translates to:
  /// **'{failed} images could not be sent.'**
  String coachChatBatchPartialFail(int failed);

  /// No description provided for @coachChatBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get coachChatBlock;

  /// No description provided for @coachChatBlockClient.
  ///
  /// In en, this message translates to:
  /// **'Block Client'**
  String get coachChatBlockClient;

  /// No description provided for @coachChatBlockContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this client? They will not be able to message you or book sessions.'**
  String get coachChatBlockContent;

  /// No description provided for @coachChatBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to block client.'**
  String get coachChatBlockFailed;

  /// No description provided for @coachChatBlockIdentifyError.
  ///
  /// In en, this message translates to:
  /// **'Could not identify client to block.'**
  String get coachChatBlockIdentifyError;

  /// No description provided for @coachChatBlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client blocked successfully.'**
  String get coachChatBlockSuccess;

  /// No description provided for @coachChatBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String coachChatBlockTitle(String name);

  /// No description provided for @coachChatCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get coachChatCamera;

  /// No description provided for @coachChatCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachChatCancel;

  /// No description provided for @coachChatCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get coachChatCaptionHint;

  /// No description provided for @coachChatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message.'**
  String get coachChatDeleteFailed;

  /// No description provided for @coachChatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get coachChatDeleteForEveryone;

  /// No description provided for @coachChatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get coachChatDeleteForMe;

  /// No description provided for @coachChatDeleteMessagesContent.
  ///
  /// In en, this message translates to:
  /// **'Delete selected messages?'**
  String get coachChatDeleteMessagesContent;

  /// No description provided for @coachChatDeleteMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{1 message} other{{count} messages}}?'**
  String coachChatDeleteMessagesTitle(int count);

  /// No description provided for @coachChatGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get coachChatGallery;

  /// No description provided for @coachChatHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active client'**
  String get coachChatHeaderSubtitle;

  /// No description provided for @coachChatImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image.'**
  String get coachChatImageUploadFailed;

  /// No description provided for @coachChatMaxBatchPhotos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 photos per message.'**
  String get coachChatMaxBatchPhotos;

  /// No description provided for @coachChatMaxSelection.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 messages can be selected.'**
  String get coachChatMaxSelection;

  /// No description provided for @coachChatMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to record voice notes.'**
  String get coachChatMicrophonePermission;

  /// No description provided for @coachChatNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get coachChatNetworkError;

  /// No description provided for @coachChatPhotoSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send photo.'**
  String get coachChatPhotoSendError;

  /// No description provided for @coachChatReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get coachChatReasonFraud;

  /// No description provided for @coachChatReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get coachChatReasonHarassment;

  /// No description provided for @coachChatReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get coachChatReasonInappropriate;

  /// No description provided for @coachChatReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get coachChatReasonOther;

  /// No description provided for @coachChatReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get coachChatReasonSpam;

  /// No description provided for @coachChatRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh messages.'**
  String get coachChatRefreshError;

  /// No description provided for @coachChatRefreshMessages.
  ///
  /// In en, this message translates to:
  /// **'Refresh messages'**
  String get coachChatRefreshMessages;

  /// No description provided for @coachChatReportClient.
  ///
  /// In en, this message translates to:
  /// **'Report Client'**
  String get coachChatReportClient;

  /// No description provided for @coachChatReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report.'**
  String get coachChatReportFailed;

  /// No description provided for @coachChatReportIdentifyError.
  ///
  /// In en, this message translates to:
  /// **'Could not identify client to report.'**
  String get coachChatReportIdentifyError;

  /// No description provided for @coachChatReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a reason for reporting this user:'**
  String get coachChatReportPrompt;

  /// No description provided for @coachChatReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for keeping SIRVYA safe.'**
  String get coachChatReportSuccess;

  /// No description provided for @coachChatReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String coachChatReportTitle(String name);

  /// No description provided for @coachChatSelectMessages.
  ///
  /// In en, this message translates to:
  /// **'Select messages'**
  String get coachChatSelectMessages;

  /// No description provided for @coachChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get coachChatSend;

  /// No description provided for @coachChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message.'**
  String get coachChatSendFailed;

  /// No description provided for @coachChatSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get coachChatSubmit;

  /// No description provided for @coachChatThisClient.
  ///
  /// In en, this message translates to:
  /// **'this client'**
  String get coachChatThisClient;

  /// No description provided for @coachExpertiseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get coachExpertiseAdd;

  /// No description provided for @coachExpertiseAddCertTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Certification'**
  String get coachExpertiseAddCertTitle;

  /// No description provided for @coachExpertiseAddSpecialtyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Specialty'**
  String get coachExpertiseAddSpecialtyTitle;

  /// No description provided for @coachExpertiseAttachedDocument.
  ///
  /// In en, this message translates to:
  /// **'Document attached'**
  String get coachExpertiseAttachedDocument;

  /// No description provided for @coachExpertiseCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachExpertiseCancel;

  /// No description provided for @coachExpertiseCertDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certification Details'**
  String get coachExpertiseCertDetailsTitle;

  /// No description provided for @coachExpertiseCertNameHint.
  ///
  /// In en, this message translates to:
  /// **'Certification Name'**
  String get coachExpertiseCertNameHint;

  /// No description provided for @coachExpertiseCertProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Issuing Organization'**
  String get coachExpertiseCertProviderHint;

  /// No description provided for @coachExpertiseCertYearHint.
  ///
  /// In en, this message translates to:
  /// **'Year Obtained'**
  String get coachExpertiseCertYearHint;

  /// No description provided for @coachExpertiseCertificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display your verified credentials to clients.'**
  String get coachExpertiseCertificationsSubtitle;

  /// No description provided for @coachExpertiseCertificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get coachExpertiseCertificationsTitle;

  /// No description provided for @coachExpertiseCoachingSince.
  ///
  /// In en, this message translates to:
  /// **'Coaching since'**
  String get coachExpertiseCoachingSince;

  /// No description provided for @coachExpertiseDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get coachExpertiseDetailName;

  /// No description provided for @coachExpertiseDetailProvider.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get coachExpertiseDetailProvider;

  /// No description provided for @coachExpertiseDetailYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get coachExpertiseDetailYear;

  /// No description provided for @coachExpertiseErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String coachExpertiseErrorGeneric(String error);

  /// No description provided for @coachExpertiseExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your total coaching and training experience.'**
  String get coachExpertiseExperienceSubtitle;

  /// No description provided for @coachExpertiseExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get coachExpertiseExperienceTitle;

  /// No description provided for @coachExpertiseExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year} other{{years} years}}'**
  String coachExpertiseExperienceYears(int years);

  /// No description provided for @coachExpertiseFileAttached.
  ///
  /// In en, this message translates to:
  /// **'File attached'**
  String get coachExpertiseFileAttached;

  /// No description provided for @coachExpertiseLevelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Experience levels of clients you work with.'**
  String get coachExpertiseLevelsSubtitle;

  /// No description provided for @coachExpertiseLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client Levels'**
  String get coachExpertiseLevelsTitle;

  /// No description provided for @coachExpertiseNoCerts.
  ///
  /// In en, this message translates to:
  /// **'No certifications added yet.'**
  String get coachExpertiseNoCerts;

  /// No description provided for @coachExpertiseNoSpecialties.
  ///
  /// In en, this message translates to:
  /// **'No specialties selected yet.'**
  String get coachExpertiseNoSpecialties;

  /// No description provided for @coachExpertiseRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachExpertiseRetry;

  /// No description provided for @coachExpertiseSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachExpertiseSave;

  /// No description provided for @coachExpertiseSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expertise updated successfully.'**
  String get coachExpertiseSaveSuccess;

  /// No description provided for @coachExpertiseSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coachExpertiseSaving;

  /// No description provided for @coachExpertiseSelectDoc.
  ///
  /// In en, this message translates to:
  /// **'Upload certificate document'**
  String get coachExpertiseSelectDoc;

  /// No description provided for @coachExpertiseSpecialtiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select areas of training you specialize in.'**
  String get coachExpertiseSpecialtiesSubtitle;

  /// No description provided for @coachExpertiseSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get coachExpertiseSpecialtiesTitle;

  /// No description provided for @coachExpertiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expertise & Credentials'**
  String get coachExpertiseTitle;

  /// No description provided for @coachExpertiseUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document.'**
  String get coachExpertiseUploadFailed;

  /// No description provided for @coachExpertiseYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get coachExpertiseYearsLabel;

  /// No description provided for @coachLocationsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street address or landmark'**
  String get coachLocationsAddressHint;

  /// No description provided for @coachLocationsAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get coachLocationsAddressLabel;

  /// No description provided for @coachLocationsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachLocationsCancel;

  /// No description provided for @coachLocationsCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary City'**
  String get coachLocationsCityTitle;

  /// No description provided for @coachLocationsDetectCityHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to detect your city'**
  String get coachLocationsDetectCityHint;

  /// No description provided for @coachLocationsEditGymDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Gym Location'**
  String get coachLocationsEditGymDialogTitle;

  /// No description provided for @coachLocationsEditLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit Location'**
  String get coachLocationsEditLocation;

  /// No description provided for @coachLocationsFormatGym.
  ///
  /// In en, this message translates to:
  /// **'At the Gym'**
  String get coachLocationsFormatGym;

  /// No description provided for @coachLocationsFormatHome.
  ///
  /// In en, this message translates to:
  /// **'At Client\'s Home'**
  String get coachLocationsFormatHome;

  /// No description provided for @coachLocationsFormatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online Coaching'**
  String get coachLocationsFormatOnline;

  /// No description provided for @coachLocationsFormatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you provide your coaching sessions?'**
  String get coachLocationsFormatsSubtitle;

  /// No description provided for @coachLocationsFormatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Formats'**
  String get coachLocationsFormatsTitle;

  /// No description provided for @coachLocationsGymAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Gym address'**
  String get coachLocationsGymAddressHint;

  /// No description provided for @coachLocationsGymAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Gym Address'**
  String get coachLocationsGymAddressLabel;

  /// No description provided for @coachLocationsGymNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., City Club'**
  String get coachLocationsGymNameHint;

  /// No description provided for @coachLocationsGymNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Gym Name'**
  String get coachLocationsGymNameLabel;

  /// No description provided for @coachLocationsGymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your primary affiliated gym or studio.'**
  String get coachLocationsGymSubtitle;

  /// No description provided for @coachLocationsGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner Gym'**
  String get coachLocationsGymTitle;

  /// No description provided for @coachLocationsRadiusHint.
  ///
  /// In en, this message translates to:
  /// **'Service radius (km)'**
  String get coachLocationsRadiusHint;

  /// No description provided for @coachLocationsRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel Radius (km)'**
  String get coachLocationsRadiusLabel;

  /// No description provided for @coachLocationsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Locations'**
  String get coachLocationsSave;

  /// No description provided for @coachLocationsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Locations updated successfully.'**
  String get coachLocationsSaveSuccess;

  /// No description provided for @coachLocationsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coachLocationsSaving;

  /// No description provided for @coachLocationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Locations'**
  String get coachLocationsTitle;

  /// No description provided for @coachPackagesAddPackage.
  ///
  /// In en, this message translates to:
  /// **'Add Package'**
  String get coachPackagesAddPackage;

  /// No description provided for @coachPackagesAgreeOnPrice.
  ///
  /// In en, this message translates to:
  /// **'Price agreed with client'**
  String get coachPackagesAgreeOnPrice;

  /// No description provided for @coachPackagesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachPackagesCancel;

  /// No description provided for @coachPackagesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get coachPackagesDelete;

  /// No description provided for @coachPackagesDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this package?'**
  String get coachPackagesDeleteContent;

  /// No description provided for @coachPackagesDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete package.'**
  String get coachPackagesDeleteError;

  /// No description provided for @coachPackagesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Package'**
  String get coachPackagesDeleteTitle;

  /// No description provided for @coachPackagesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Package deleted.'**
  String get coachPackagesDeleted;

  /// No description provided for @coachPackagesDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get coachPackagesDurationLabel;

  /// No description provided for @coachPackagesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get coachPackagesEdit;

  /// No description provided for @coachPackagesEditPackage.
  ///
  /// In en, this message translates to:
  /// **'Edit Package'**
  String get coachPackagesEditPackage;

  /// No description provided for @coachPackagesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create packs to encourage repeat sessions and long-term commitment.'**
  String get coachPackagesEmptySubtitle;

  /// No description provided for @coachPackagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Packages Yet'**
  String get coachPackagesEmptyTitle;

  /// No description provided for @coachPackagesNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 10-Session Transformation Pack'**
  String get coachPackagesNameHint;

  /// No description provided for @coachPackagesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get coachPackagesNameLabel;

  /// No description provided for @coachPackagesPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Price in MAD'**
  String get coachPackagesPriceHint;

  /// No description provided for @coachPackagesPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (MAD)'**
  String get coachPackagesPriceLabel;

  /// No description provided for @coachPackagesProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {max} packages'**
  String coachPackagesProgress(int current, int max);

  /// No description provided for @coachPackagesSave.
  ///
  /// In en, this message translates to:
  /// **'Save Package'**
  String get coachPackagesSave;

  /// No description provided for @coachPackagesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save package.'**
  String get coachPackagesSaveError;

  /// No description provided for @coachPackagesSaved.
  ///
  /// In en, this message translates to:
  /// **'Package saved successfully.'**
  String get coachPackagesSaved;

  /// No description provided for @coachPackagesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coachPackagesSaving;

  /// No description provided for @coachPackagesSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String coachPackagesSessionsCount(int count);

  /// No description provided for @coachPackagesSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Number of sessions included'**
  String get coachPackagesSessionsHint;

  /// No description provided for @coachPackagesSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions Included'**
  String get coachPackagesSessionsLabel;

  /// No description provided for @coachPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages & Rates'**
  String get coachPackagesTitle;

  /// No description provided for @coachPhotosAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get coachPhotosAddPhoto;

  /// No description provided for @coachPhotosAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Gym address'**
  String get coachPhotosAddressHint;

  /// No description provided for @coachPhotosAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get coachPhotosAddressLabel;

  /// No description provided for @coachPhotosCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coachPhotosCancel;

  /// No description provided for @coachPhotosCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get coachPhotosCaptionHint;

  /// No description provided for @coachPhotosCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Caption'**
  String get coachPhotosCaptionTitle;

  /// No description provided for @coachPhotosCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coachPhotosCover;

  /// No description provided for @coachPhotosDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get coachPhotosDelete;

  /// No description provided for @coachPhotosEditCaption.
  ///
  /// In en, this message translates to:
  /// **'Edit Caption'**
  String get coachPhotosEditCaption;

  /// No description provided for @coachPhotosEditGymDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Gym Photo'**
  String get coachPhotosEditGymDialogTitle;

  /// No description provided for @coachPhotosErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String coachPhotosErrorGeneric(String error);

  /// No description provided for @coachPhotosGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your coaching environment and workouts.'**
  String get coachPhotosGallerySubtitle;

  /// No description provided for @coachPhotosGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery Photos'**
  String get coachPhotosGalleryTitle;

  /// No description provided for @coachPhotosGymTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym / Studio Photos'**
  String get coachPhotosGymTitle;

  /// No description provided for @coachPhotosNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos in your gallery yet.'**
  String get coachPhotosNoPhotos;

  /// No description provided for @coachPhotosPartialSlots.
  ///
  /// In en, this message translates to:
  /// **'{slots} slots remaining in gallery.'**
  String coachPhotosPartialSlots(int slots);

  /// No description provided for @coachPhotosSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save photo: {error}'**
  String coachPhotosSaveFailed(String error);

  /// No description provided for @coachPhotosSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photos updated successfully.'**
  String get coachPhotosSaveSuccess;

  /// No description provided for @coachPhotosSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get coachPhotosSaving;

  /// No description provided for @coachPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Photos'**
  String get coachPhotosTitle;

  /// No description provided for @coachPhotosUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo.'**
  String get coachPhotosUploadFailed;

  /// No description provided for @mealScannerAddFoodItem.
  ///
  /// In en, this message translates to:
  /// **'Add food item'**
  String get mealScannerAddFoodItem;

  /// No description provided for @mealScannerAddToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add to meal'**
  String get mealScannerAddToMeal;

  /// No description provided for @mealScannerAdjustPortion.
  ///
  /// In en, this message translates to:
  /// **'Adjust portion'**
  String get mealScannerAdjustPortion;

  /// No description provided for @mealScannerApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get mealScannerApply;

  /// No description provided for @mealScannerCalculatedNutrition.
  ///
  /// In en, this message translates to:
  /// **'Calculated Nutrition'**
  String get mealScannerCalculatedNutrition;

  /// No description provided for @mealScannerCaloriesKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get mealScannerCaloriesKcalLabel;

  /// No description provided for @mealScannerCarbsGLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get mealScannerCarbsGLabel;

  /// No description provided for @mealScannerCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mealScannerCategoryAll;

  /// No description provided for @mealScannerCategoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get mealScannerCategoryDairy;

  /// No description provided for @mealScannerCategoryDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get mealScannerCategoryDrinks;

  /// No description provided for @mealScannerCategoryFish.
  ///
  /// In en, this message translates to:
  /// **'Fish & Seafood'**
  String get mealScannerCategoryFish;

  /// No description provided for @mealScannerCategoryGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains & Bread'**
  String get mealScannerCategoryGrains;

  /// No description provided for @mealScannerCategoryMeals.
  ///
  /// In en, this message translates to:
  /// **'Prepared Meals'**
  String get mealScannerCategoryMeals;

  /// No description provided for @mealScannerCategoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat & Poultry'**
  String get mealScannerCategoryMeat;

  /// No description provided for @mealScannerCategoryNuts.
  ///
  /// In en, this message translates to:
  /// **'Nuts & Seeds'**
  String get mealScannerCategoryNuts;

  /// No description provided for @mealScannerCategoryProduce.
  ///
  /// In en, this message translates to:
  /// **'Fruits & Veggies'**
  String get mealScannerCategoryProduce;

  /// No description provided for @mealScannerCategorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks & Sweets'**
  String get mealScannerCategorySnacks;

  /// No description provided for @mealScannerChangesNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Changes saved locally · Not synced yet'**
  String get mealScannerChangesNotSynced;

  /// No description provided for @mealScannerChooseCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose food category'**
  String get mealScannerChooseCategoryHint;

  /// No description provided for @mealScannerChooseDifferentFood.
  ///
  /// In en, this message translates to:
  /// **'Choose a different food'**
  String get mealScannerChooseDifferentFood;

  /// No description provided for @mealScannerCustomFoodDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Custom Food'**
  String get mealScannerCustomFoodDefaultName;

  /// No description provided for @mealScannerCustomFoodNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get mealScannerCustomFoodNameLabel;

  /// No description provided for @mealScannerCustomItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get mealScannerCustomItemFallback;

  /// No description provided for @mealScannerDeleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get mealScannerDeleteMeal;

  /// No description provided for @mealScannerEditMacrosManually.
  ///
  /// In en, this message translates to:
  /// **'Edit macros manually'**
  String get mealScannerEditMacrosManually;

  /// No description provided for @mealScannerEnterFoodNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a food name.'**
  String get mealScannerEnterFoodNameError;

  /// No description provided for @mealScannerEnterValidWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight in grams.'**
  String get mealScannerEnterValidWeightError;

  /// No description provided for @mealScannerFatGLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get mealScannerFatGLabel;

  /// No description provided for @mealScannerFoodMacrosPer100g.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal · P {protein}g · C {carbs}g · F {fat}g'**
  String mealScannerFoodMacrosPer100g(
      int calories, String protein, String carbs, String fat);

  /// No description provided for @mealScannerFoodNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get mealScannerFoodNameLabel;

  /// No description provided for @mealScannerMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get mealScannerMacroCarbs;

  /// No description provided for @mealScannerMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get mealScannerMacroFat;

  /// No description provided for @mealScannerMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get mealScannerMacroProtein;

  /// No description provided for @mealScannerManualValuesActive.
  ///
  /// In en, this message translates to:
  /// **'Manual values active'**
  String get mealScannerManualValuesActive;

  /// No description provided for @mealScannerMealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealScannerMealBreakfast;

  /// No description provided for @mealScannerMealDate.
  ///
  /// In en, this message translates to:
  /// **'Meal date: {date}'**
  String mealScannerMealDate(String date);

  /// No description provided for @mealScannerMealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealScannerMealDinner;

  /// No description provided for @mealScannerMealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealScannerMealLunch;

  /// No description provided for @mealScannerMealMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Meal moved to {meal}'**
  String mealScannerMealMovedTo(String meal);

  /// No description provided for @mealScannerMealSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Meal saved to {meal}'**
  String mealScannerMealSavedTo(String meal);

  /// No description provided for @mealScannerMealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealScannerMealSnack;

  /// No description provided for @mealScannerMoveMeal.
  ///
  /// In en, this message translates to:
  /// **'Move meal'**
  String get mealScannerMoveMeal;

  /// No description provided for @mealScannerNoFoodsFound.
  ///
  /// In en, this message translates to:
  /// **'No food found for \"{query}\"'**
  String mealScannerNoFoodsFound(String query);

  /// No description provided for @mealScannerNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced ({meal})'**
  String mealScannerNotSynced(String meal);

  /// No description provided for @mealScannerOneServing.
  ///
  /// In en, this message translates to:
  /// **'1 serving'**
  String get mealScannerOneServing;

  /// No description provided for @mealScannerOnlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get mealScannerOnlineBadge;

  /// No description provided for @mealScannerOrEnterCustomMacros.
  ///
  /// In en, this message translates to:
  /// **'Or enter custom macros'**
  String get mealScannerOrEnterCustomMacros;

  /// No description provided for @mealScannerProteinGLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get mealScannerProteinGLabel;

  /// No description provided for @mealScannerQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String mealScannerQuantityLabel(String unit);

  /// No description provided for @mealScannerQueryingGlobalDb.
  ///
  /// In en, this message translates to:
  /// **'Querying food database…'**
  String get mealScannerQueryingGlobalDb;

  /// No description provided for @mealScannerResetToAuto.
  ///
  /// In en, this message translates to:
  /// **'Reset to auto calculation'**
  String get mealScannerResetToAuto;

  /// No description provided for @mealScannerSavedIn.
  ///
  /// In en, this message translates to:
  /// **'Saved in {meal}'**
  String mealScannerSavedIn(String meal);

  /// No description provided for @mealScannerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search food or scan barcode…'**
  String get mealScannerSearchHint;

  /// No description provided for @mealScannerSearchMoreOnline.
  ///
  /// In en, this message translates to:
  /// **'Search more foods online'**
  String get mealScannerSearchMoreOnline;

  /// No description provided for @mealScannerSearchOpenFoodFacts.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts search'**
  String get mealScannerSearchOpenFoodFacts;

  /// No description provided for @mealScannerSearchingFor.
  ///
  /// In en, this message translates to:
  /// **'Searching for \"{query}\"…'**
  String mealScannerSearchingFor(String query);

  /// No description provided for @mealScannerSearchingOnlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Searching online database…'**
  String get mealScannerSearchingOnlineBanner;

  /// No description provided for @mealScannerSearchingOnlineShort.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get mealScannerSearchingOnlineShort;

  /// No description provided for @mealScannerSelectedFoodBase.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal · P {protein}g · C {carbs}g · F {fat}g (per 100g)'**
  String mealScannerSelectedFoodBase(
      int calories, String protein, String carbs, String fat);

  /// No description provided for @mealScannerValuesAutoCalculated.
  ///
  /// In en, this message translates to:
  /// **'Values calculated automatically based on weight.'**
  String get mealScannerValuesAutoCalculated;

  /// No description provided for @nutritionGoalAboutMaintenanceKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/day estimated maintenance'**
  String nutritionGoalAboutMaintenanceKcal(int kcal);

  /// No description provided for @nutritionGoalActivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High (daily intense exercise)'**
  String get nutritionGoalActivityHigh;

  /// No description provided for @nutritionGoalActivityLight.
  ///
  /// In en, this message translates to:
  /// **'Light (1-2 workouts/week)'**
  String get nutritionGoalActivityLight;

  /// No description provided for @nutritionGoalActivityLow.
  ///
  /// In en, this message translates to:
  /// **'Sedentary (little to no exercise)'**
  String get nutritionGoalActivityLow;

  /// No description provided for @nutritionGoalActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate (3-5 workouts/week)'**
  String get nutritionGoalActivityModerate;

  /// No description provided for @nutritionGoalAdultWeightError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a realistic target weight.'**
  String get nutritionGoalAdultWeightError;

  /// No description provided for @nutritionGoalAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get nutritionGoalAgeLabel;

  /// No description provided for @nutritionGoalAppliedToast.
  ///
  /// In en, this message translates to:
  /// **'Applied targets: {calories} kcal · P {protein}g · C {carbs}g · F {fat}g'**
  String nutritionGoalAppliedToast(
      int calories, int protein, int carbs, int fat);

  /// No description provided for @nutritionGoalApplyRecommendedBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Recommended Targets'**
  String get nutritionGoalApplyRecommendedBtn;

  /// No description provided for @nutritionGoalBreakfastCheckin.
  ///
  /// In en, this message translates to:
  /// **'Breakfast check-in'**
  String get nutritionGoalBreakfastCheckin;

  /// No description provided for @nutritionGoalCalorieCheckinsSub.
  ///
  /// In en, this message translates to:
  /// **'Receive daily prompts to log meals.'**
  String get nutritionGoalCalorieCheckinsSub;

  /// No description provided for @nutritionGoalCalorieCheckinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Check-in Reminders'**
  String get nutritionGoalCalorieCheckinsTitle;

  /// No description provided for @nutritionGoalCaptionDailyEnergy.
  ///
  /// In en, this message translates to:
  /// **'Daily caloric intake target'**
  String get nutritionGoalCaptionDailyEnergy;

  /// No description provided for @nutritionGoalCaptionHormoneHealth.
  ///
  /// In en, this message translates to:
  /// **'Essential for hormone balance and joints'**
  String get nutritionGoalCaptionHormoneHealth;

  /// No description provided for @nutritionGoalCaptionMuscleRecovery.
  ///
  /// In en, this message translates to:
  /// **'Target for muscle repair and satiety'**
  String get nutritionGoalCaptionMuscleRecovery;

  /// No description provided for @nutritionGoalCompleteProfilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to personalize nutrition targets.'**
  String get nutritionGoalCompleteProfilePrompt;

  /// No description provided for @nutritionGoalDeficitBadge.
  ///
  /// In en, this message translates to:
  /// **'{diff} kcal deficit'**
  String nutritionGoalDeficitBadge(int diff);

  /// No description provided for @nutritionGoalDietBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get nutritionGoalDietBalanced;

  /// No description provided for @nutritionGoalDietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get nutritionGoalDietHalal;

  /// No description provided for @nutritionGoalDietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get nutritionGoalDietVegan;

  /// No description provided for @nutritionGoalDietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get nutritionGoalDietVegetarian;

  /// No description provided for @nutritionGoalDietaryStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preference'**
  String get nutritionGoalDietaryStyleLabel;

  /// No description provided for @nutritionGoalDinnerCheckin.
  ///
  /// In en, this message translates to:
  /// **'Dinner check-in'**
  String get nutritionGoalDinnerCheckin;

  /// No description provided for @nutritionGoalEstimateMaintenanceSub.
  ///
  /// In en, this message translates to:
  /// **'Based on your height, weight, age and activity.'**
  String get nutritionGoalEstimateMaintenanceSub;

  /// No description provided for @nutritionGoalEstimateMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Calories'**
  String get nutritionGoalEstimateMaintenanceTitle;

  /// No description provided for @nutritionGoalEstimatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Calculate personalized calorie and macro targets.'**
  String get nutritionGoalEstimatePrompt;

  /// No description provided for @nutritionGoalFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid value for {field}'**
  String nutritionGoalFieldInvalid(String field);

  /// No description provided for @nutritionGoalFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String nutritionGoalFieldRequired(String field);

  /// No description provided for @nutritionGoalFoodPreferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Food Preference'**
  String get nutritionGoalFoodPreferenceLabel;

  /// No description provided for @nutritionGoalGeneralEstimatesSuitable.
  ///
  /// In en, this message translates to:
  /// **'These estimates provide a science-backed starting point for your journey.'**
  String get nutritionGoalGeneralEstimatesSuitable;

  /// No description provided for @nutritionGoalHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your daily calorie and macro goals.'**
  String get nutritionGoalHeaderSubtitle;

  /// No description provided for @nutritionGoalHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Targets'**
  String get nutritionGoalHeaderTitle;

  /// No description provided for @nutritionGoalHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get nutritionGoalHeightLabel;

  /// No description provided for @nutritionGoalLunchCheckin.
  ///
  /// In en, this message translates to:
  /// **'Lunch check-in'**
  String get nutritionGoalLunchCheckin;

  /// No description provided for @nutritionGoalMacroCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionGoalMacroCalories;

  /// No description provided for @nutritionGoalMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionGoalMacroCarbs;

  /// No description provided for @nutritionGoalMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionGoalMacroFat;

  /// No description provided for @nutritionGoalMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionGoalMacroProtein;

  /// No description provided for @nutritionGoalMaintenanceBadge.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get nutritionGoalMaintenanceBadge;

  /// No description provided for @nutritionGoalMealIdeasSub.
  ///
  /// In en, this message translates to:
  /// **'Get smart recipe and meal suggestions.'**
  String get nutritionGoalMealIdeasSub;

  /// No description provided for @nutritionGoalMealIdeasTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Ideas & Inspiration'**
  String get nutritionGoalMealIdeasTitle;

  /// No description provided for @nutritionGoalMinorSectionSub.
  ///
  /// In en, this message translates to:
  /// **'Preferences and schedule'**
  String get nutritionGoalMinorSectionSub;

  /// No description provided for @nutritionGoalMinorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get nutritionGoalMinorSectionTitle;

  /// No description provided for @nutritionGoalMonthlyReview.
  ///
  /// In en, this message translates to:
  /// **'Monthly Progress Review'**
  String get nutritionGoalMonthlyReview;

  /// No description provided for @nutritionGoalMyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Goal'**
  String get nutritionGoalMyGoalLabel;

  /// No description provided for @nutritionGoalNoteGain.
  ///
  /// In en, this message translates to:
  /// **'Targeting lean muscle growth with a clean caloric surplus.'**
  String get nutritionGoalNoteGain;

  /// No description provided for @nutritionGoalNoteLose.
  ///
  /// In en, this message translates to:
  /// **'Targeting safe, sustainable fat loss with a moderate deficit.'**
  String get nutritionGoalNoteLose;

  /// No description provided for @nutritionGoalNoteMaintain.
  ///
  /// In en, this message translates to:
  /// **'Targeting weight stability, performance and energy.'**
  String get nutritionGoalNoteMaintain;

  /// No description provided for @nutritionGoalQuietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours end'**
  String get nutritionGoalQuietHoursEnd;

  /// No description provided for @nutritionGoalQuietHoursNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications are silenced during your quiet hours.'**
  String get nutritionGoalQuietHoursNote;

  /// No description provided for @nutritionGoalQuietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours start'**
  String get nutritionGoalQuietHoursStart;

  /// No description provided for @nutritionGoalRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Targets'**
  String get nutritionGoalRecommendedTitle;

  /// No description provided for @nutritionGoalRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Manage daily reminders and quiet hours.'**
  String get nutritionGoalRemindersSub;

  /// No description provided for @nutritionGoalRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders & Notifications'**
  String get nutritionGoalRemindersTitle;

  /// No description provided for @nutritionGoalSaveMyGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Nutrition Goal'**
  String get nutritionGoalSaveMyGoal;

  /// No description provided for @nutritionGoalSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get nutritionGoalSaving;

  /// No description provided for @nutritionGoalSectionDailyTargetsSub.
  ///
  /// In en, this message translates to:
  /// **'Customize your daily macronutrient breakdown.'**
  String get nutritionGoalSectionDailyTargetsSub;

  /// No description provided for @nutritionGoalSectionDailyTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Targets'**
  String get nutritionGoalSectionDailyTargetsTitle;

  /// No description provided for @nutritionGoalSectionStatusSub.
  ///
  /// In en, this message translates to:
  /// **'Current status of this nutrition goal.'**
  String get nutritionGoalSectionStatusSub;

  /// No description provided for @nutritionGoalSectionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Status'**
  String get nutritionGoalSectionStatusTitle;

  /// No description provided for @nutritionGoalSectionSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Reminders and coaching recommendations.'**
  String get nutritionGoalSectionSupportSub;

  /// No description provided for @nutritionGoalSectionSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support & Reminders'**
  String get nutritionGoalSectionSupportTitle;

  /// No description provided for @nutritionGoalSectionWhatMattersSub.
  ///
  /// In en, this message translates to:
  /// **'Key nutritional focus for your journey.'**
  String get nutritionGoalSectionWhatMattersSub;

  /// No description provided for @nutritionGoalSectionWhatMattersTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Focus'**
  String get nutritionGoalSectionWhatMattersTitle;

  /// No description provided for @nutritionGoalSetupLaterInProfile.
  ///
  /// In en, this message translates to:
  /// **'You can update these targets anytime in your profile.'**
  String get nutritionGoalSetupLaterInProfile;

  /// No description provided for @nutritionGoalSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get nutritionGoalSexFemale;

  /// No description provided for @nutritionGoalSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get nutritionGoalSexMale;

  /// No description provided for @nutritionGoalSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get nutritionGoalSkipForNow;

  /// No description provided for @nutritionGoalStartFreshSub.
  ///
  /// In en, this message translates to:
  /// **'Reset targets to default recommendations.'**
  String get nutritionGoalStartFreshSub;

  /// No description provided for @nutritionGoalStartFreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Targets'**
  String get nutritionGoalStartFreshTitle;

  /// No description provided for @nutritionGoalStartingWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting Weight (kg)'**
  String get nutritionGoalStartingWeightLabel;

  /// No description provided for @nutritionGoalStatusAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get nutritionGoalStatusAchieved;

  /// No description provided for @nutritionGoalStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get nutritionGoalStatusActive;

  /// No description provided for @nutritionGoalStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get nutritionGoalStatusPaused;

  /// No description provided for @nutritionGoalStyleBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get nutritionGoalStyleBalanced;

  /// No description provided for @nutritionGoalStyleHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get nutritionGoalStyleHighProtein;

  /// No description provided for @nutritionGoalStyleLowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get nutritionGoalStyleLowCarb;

  /// No description provided for @nutritionGoalSurplusBadge.
  ///
  /// In en, this message translates to:
  /// **'{diff} kcal surplus'**
  String nutritionGoalSurplusBadge(int diff);

  /// No description provided for @nutritionGoalTargetDirectionError.
  ///
  /// In en, this message translates to:
  /// **'Target weight direction does not match goal type.'**
  String get nutritionGoalTargetDirectionError;

  /// No description provided for @nutritionGoalTargetWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Weight (kg)'**
  String get nutritionGoalTargetWeightLabel;

  /// No description provided for @nutritionGoalTimeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get nutritionGoalTimeZoneLabel;

  /// No description provided for @nutritionGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Goal'**
  String get nutritionGoalTitle;

  /// No description provided for @nutritionGoalTitleSignup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Nutrition Goal'**
  String get nutritionGoalTitleSignup;

  /// No description provided for @nutritionGoalTypeBalanced.
  ///
  /// In en, this message translates to:
  /// **'General Fitness'**
  String get nutritionGoalTypeBalanced;

  /// No description provided for @nutritionGoalTypeGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get nutritionGoalTypeGain;

  /// No description provided for @nutritionGoalTypeLose.
  ///
  /// In en, this message translates to:
  /// **'Fat Loss'**
  String get nutritionGoalTypeLose;

  /// No description provided for @nutritionGoalTypeMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get nutritionGoalTypeMaintain;

  /// No description provided for @nutritionGoalUnitKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get nutritionGoalUnitKcalPerDay;

  /// No description provided for @nutritionGoalUseThisGoal.
  ///
  /// In en, this message translates to:
  /// **'Use This Goal'**
  String get nutritionGoalUseThisGoal;

  /// No description provided for @nutritionGoalUsualActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Usual Activity Level'**
  String get nutritionGoalUsualActivityLabel;

  /// No description provided for @nutritionGoalWeeklyWeightCheckin.
  ///
  /// In en, this message translates to:
  /// **'Weekly Weight Check-in'**
  String get nutritionGoalWeeklyWeightCheckin;

  /// No description provided for @nutritionGoalYearlyReview.
  ///
  /// In en, this message translates to:
  /// **'Yearly Review'**
  String get nutritionGoalYearlyReview;

  /// No description provided for @nutritionTrackerGoalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your goal. Please try again.'**
  String get nutritionTrackerGoalLoadError;

  /// No description provided for @nutritionTrackerMealRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this meal. Try again.'**
  String get nutritionTrackerMealRemoveError;

  /// No description provided for @nutritionTrackerDailyDiary.
  ///
  /// In en, this message translates to:
  /// **'YOUR DAILY DIARY'**
  String get nutritionTrackerDailyDiary;

  /// No description provided for @nutritionTrackerFuelDay.
  ///
  /// In en, this message translates to:
  /// **'Fuel your day.'**
  String get nutritionTrackerFuelDay;

  /// No description provided for @nutritionTrackerBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get nutritionTrackerBackToToday;

  /// No description provided for @nutritionTrackerRetrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get nutritionTrackerRetrySync;

  /// No description provided for @nutritionTrackerEnergyLogged.
  ///
  /// In en, this message translates to:
  /// **'ENERGY LOGGED'**
  String get nutritionTrackerEnergyLogged;

  /// No description provided for @nutritionTrackerMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 meal logged} other{{count} meals logged}}'**
  String nutritionTrackerMealsLogged(int count);

  /// No description provided for @nutritionTrackerSetDailyTargets.
  ///
  /// In en, this message translates to:
  /// **'Set your own daily targets →'**
  String get nutritionTrackerSetDailyTargets;

  /// No description provided for @nutritionTrackerScanMeal.
  ///
  /// In en, this message translates to:
  /// **'Scan a meal'**
  String get nutritionTrackerScanMeal;

  /// No description provided for @nutritionTrackerAddManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get nutritionTrackerAddManually;

  /// No description provided for @nutritionTrackerMealsMoments.
  ///
  /// In en, this message translates to:
  /// **'Meals & moments'**
  String get nutritionTrackerMealsMoments;

  /// No description provided for @nutritionTrackerDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition diary'**
  String get nutritionTrackerDiaryTitle;

  /// No description provided for @nutritionTrackerNothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get nutritionTrackerNothingLogged;

  /// No description provided for @nutritionTrackerAddMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a meal'**
  String get nutritionTrackerAddMealTitle;

  /// No description provided for @nutritionTrackerAddMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the nutrition on a label or in your recipe.'**
  String get nutritionTrackerAddMealSubtitle;

  /// No description provided for @nutritionTrackerMealNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get nutritionTrackerMealNameLabel;

  /// No description provided for @nutritionTrackerSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get nutritionTrackerSaving;

  /// No description provided for @nutritionTrackerSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get nutritionTrackerSaveMeal;

  /// No description provided for @nutritionTrackerDailyTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily targets'**
  String get nutritionTrackerDailyTargetsTitle;

  /// No description provided for @nutritionTrackerSaveTargets.
  ///
  /// In en, this message translates to:
  /// **'Save targets'**
  String get nutritionTrackerSaveTargets;

  /// No description provided for @coachExpertiseDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get coachExpertiseDetailStatus;

  /// No description provided for @coachExpertiseErrorPickingFile.
  ///
  /// In en, this message translates to:
  /// **'Could not select file. Please try again.'**
  String get coachExpertiseErrorPickingFile;

  /// No description provided for @coachExpertiseErrorUpdating.
  ///
  /// In en, this message translates to:
  /// **'Failed to update credentials.'**
  String get coachExpertiseErrorUpdating;

  /// No description provided for @coachExpertiseFailedLoadDoc.
  ///
  /// In en, this message translates to:
  /// **'Could not load certificate document.'**
  String get coachExpertiseFailedLoadDoc;

  /// No description provided for @coachExpertiseFileUploaded.
  ///
  /// In en, this message translates to:
  /// **'Certificate document uploaded.'**
  String get coachExpertiseFileUploaded;

  /// No description provided for @coachExpertiseLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced athletes'**
  String get coachExpertiseLevelAdvanced;

  /// No description provided for @coachExpertiseLevelBeginners.
  ///
  /// In en, this message translates to:
  /// **'Beginners'**
  String get coachExpertiseLevelBeginners;

  /// No description provided for @coachExpertiseLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get coachExpertiseLevelIntermediate;

  /// No description provided for @coachExpertiseMaxSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Maximum 8 specialties allowed.'**
  String get coachExpertiseMaxSpecialties;

  /// No description provided for @coachExpertisePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get coachExpertisePreview;

  /// No description provided for @coachExpertisePrimaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Primary Discipline'**
  String get coachExpertisePrimaryCategory;

  /// No description provided for @coachExpertiseProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Credentials updated successfully.'**
  String get coachExpertiseProfileUpdated;

  /// No description provided for @coachExpertiseResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Document'**
  String get coachExpertiseResubmit;

  /// No description provided for @coachExpertiseReviewInProgress.
  ///
  /// In en, this message translates to:
  /// **'Under review by SIRVYA team'**
  String get coachExpertiseReviewInProgress;

  /// No description provided for @coachExpertiseReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Certificates are verified by our team within 24-48 hours.'**
  String get coachExpertiseReviewNotice;

  /// No description provided for @coachExpertiseSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachExpertiseSaveChanges;

  /// No description provided for @coachExpertiseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select primary category'**
  String get coachExpertiseSelectCategory;

  /// No description provided for @coachExpertiseSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get coachExpertiseSelectYear;

  /// No description provided for @coachExpertiseSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Kettlebell Training'**
  String get coachExpertiseSpecialtyHint;

  /// No description provided for @coachExpertiseStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get coachExpertiseStatusApproved;

  /// No description provided for @coachExpertiseStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get coachExpertiseStatusRejected;

  /// No description provided for @coachExpertiseStatusReviewing.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get coachExpertiseStatusReviewing;

  /// No description provided for @coachExpertiseStatusSelfReported.
  ///
  /// In en, this message translates to:
  /// **'Self-Reported'**
  String get coachExpertiseStatusSelfReported;

  /// No description provided for @coachExpertiseSubmitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get coachExpertiseSubmitVerification;

  /// No description provided for @coachExpertiseSuggestedBodybuilding.
  ///
  /// In en, this message translates to:
  /// **'Bodybuilding & Hypertrophy'**
  String get coachExpertiseSuggestedBodybuilding;

  /// No description provided for @coachExpertiseSuggestedConditioning.
  ///
  /// In en, this message translates to:
  /// **'Cardio & Conditioning'**
  String get coachExpertiseSuggestedConditioning;

  /// No description provided for @coachExpertiseSuggestedForYou.
  ///
  /// In en, this message translates to:
  /// **'Suggested for your discipline'**
  String get coachExpertiseSuggestedForYou;

  /// No description provided for @coachExpertiseSuggestedFunctional.
  ///
  /// In en, this message translates to:
  /// **'Functional Fitness'**
  String get coachExpertiseSuggestedFunctional;

  /// No description provided for @coachExpertiseSuggestedNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Dietetics'**
  String get coachExpertiseSuggestedNutrition;

  /// No description provided for @coachExpertiseSuggestedPilates.
  ///
  /// In en, this message translates to:
  /// **'Pilates & Core Stability'**
  String get coachExpertiseSuggestedPilates;

  /// No description provided for @coachExpertiseSuggestedPowerlifting.
  ///
  /// In en, this message translates to:
  /// **'Powerlifting & Strength'**
  String get coachExpertiseSuggestedPowerlifting;

  /// No description provided for @coachExpertiseSuggestedRehabilitation.
  ///
  /// In en, this message translates to:
  /// **'Post-Rehabilitation'**
  String get coachExpertiseSuggestedRehabilitation;

  /// No description provided for @coachExpertiseSuggestedYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga & Flexibility'**
  String get coachExpertiseSuggestedYoga;

  /// No description provided for @coachExpertiseTapToPreview.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview certificate'**
  String get coachExpertiseTapToPreview;

  /// No description provided for @coachExpertiseUploadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Upload Certificate (PDF / Image)'**
  String get coachExpertiseUploadCertificate;

  /// No description provided for @coachExpertiseVerifiedBadgeInfo.
  ///
  /// In en, this message translates to:
  /// **'Verified credentials receive a badge on your public profile.'**
  String get coachExpertiseVerifiedBadgeInfo;

  /// No description provided for @coachExpertiseVerifiedCertificate.
  ///
  /// In en, this message translates to:
  /// **'Verified Certificate'**
  String get coachExpertiseVerifiedCertificate;

  /// No description provided for @coachExpertiseViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get coachExpertiseViewDetails;

  /// No description provided for @coachExpertiseWhoYouCoach.
  ///
  /// In en, this message translates to:
  /// **'Who do you typically coach?'**
  String get coachExpertiseWhoYouCoach;

  /// No description provided for @coachLocationsFormatOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors / Parks'**
  String get coachLocationsFormatOutdoors;

  /// No description provided for @coachLocationsGymLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym Location'**
  String get coachLocationsGymLocationTitle;

  /// No description provided for @coachLocationsManageAvailability.
  ///
  /// In en, this message translates to:
  /// **'Manage your daily coaching calendar'**
  String get coachLocationsManageAvailability;

  /// No description provided for @coachLocationsOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Working Hours & Calendar'**
  String get coachLocationsOpenCalendar;

  /// No description provided for @coachLocationsPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get coachLocationsPreview;

  /// No description provided for @coachLocationsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachLocationsSaveChanges;

  /// No description provided for @coachLocationsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save location: {error}'**
  String coachLocationsSaveFailed(String error);

  /// No description provided for @coachLocationsSelectGym.
  ///
  /// In en, this message translates to:
  /// **'Select partner gym'**
  String get coachLocationsSelectGym;

  /// No description provided for @coachLocationsServiceAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Greater Casablanca Area'**
  String get coachLocationsServiceAreaHint;

  /// No description provided for @coachLocationsServiceAreaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Areas where you are available to travel for clients.'**
  String get coachLocationsServiceAreaSubtitle;

  /// No description provided for @coachLocationsServiceAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Area'**
  String get coachLocationsServiceAreaTitle;

  /// No description provided for @coachLocationsUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Map Coordinates'**
  String get coachLocationsUpdateLocation;

  /// No description provided for @coachLocationsUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Gym Photo'**
  String get coachLocationsUploadImage;

  /// No description provided for @coachLocationsUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get coachLocationsUploading;

  /// No description provided for @coachPackagesFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed Session Price'**
  String get coachPackagesFixedPrice;

  /// No description provided for @coachPackagesFixedPriceSub.
  ///
  /// In en, this message translates to:
  /// **'Standard rate applied per coaching session.'**
  String get coachPackagesFixedPriceSub;

  /// No description provided for @coachPackagesIncludedHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Custom diet plan + 24/7 WhatsApp support'**
  String get coachPackagesIncludedHint;

  /// No description provided for @coachPackagesIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get coachPackagesIncludedLabel;

  /// No description provided for @coachPackagesIndividualSession.
  ///
  /// In en, this message translates to:
  /// **'Single session'**
  String get coachPackagesIndividualSession;

  /// No description provided for @coachPackagesLocationGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get coachPackagesLocationGym;

  /// No description provided for @coachPackagesLocationOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get coachPackagesLocationOnline;

  /// No description provided for @coachPackagesLocationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Locations'**
  String get coachPackagesLocationsLabel;

  /// No description provided for @coachPackagesMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get coachPackagesMinutesUnit;

  /// No description provided for @coachPackagesMultipleSessions.
  ///
  /// In en, this message translates to:
  /// **'{sessions, plural, =1{1 session} other{{sessions} sessions}} · {duration} min each'**
  String coachPackagesMultipleSessions(int sessions, int duration);

  /// No description provided for @coachPackagesOnRequest.
  ///
  /// In en, this message translates to:
  /// **'On request'**
  String get coachPackagesOnRequest;

  /// No description provided for @coachPackagesPerSession.
  ///
  /// In en, this message translates to:
  /// **'MAD / session'**
  String get coachPackagesPerSession;

  /// No description provided for @coachPackagesPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get coachPackagesPreview;

  /// No description provided for @coachPackagesPriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on Request'**
  String get coachPackagesPriceOnRequest;

  /// No description provided for @coachPackagesPricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Model'**
  String get coachPackagesPricingLabel;

  /// No description provided for @coachPackagesSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachPackagesSaveChanges;

  /// No description provided for @coachPhotosFormatGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get coachPhotosFormatGym;

  /// No description provided for @coachPhotosFormatHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get coachPhotosFormatHome;

  /// No description provided for @coachPhotosFormatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get coachPhotosFormatOnline;

  /// No description provided for @coachPhotosFormatOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get coachPhotosFormatOutdoors;

  /// No description provided for @coachPhotosGymNameHint.
  ///
  /// In en, this message translates to:
  /// **'Gym Name'**
  String get coachPhotosGymNameHint;

  /// No description provided for @coachPhotosGymNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Gym Name'**
  String get coachPhotosGymNameLabel;

  /// No description provided for @coachPhotosMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 12 photos reached.'**
  String get coachPhotosMaxPhotos;

  /// No description provided for @coachPhotosPortfolioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High quality training photos build trust with prospective clients.'**
  String get coachPhotosPortfolioSubtitle;

  /// No description provided for @coachPhotosPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Portfolio'**
  String get coachPhotosPortfolioTitle;

  /// No description provided for @coachPhotosPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get coachPhotosPreview;

  /// No description provided for @coachPhotosSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachPhotosSave;

  /// No description provided for @coachPhotosSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachPhotosSaveChanges;

  /// No description provided for @coachPhotosUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get coachPhotosUploadImage;

  /// No description provided for @coachPhotosUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get coachPhotosUploading;

  /// No description provided for @coachLocationsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String coachLocationsErrorGeneric(String error);

  /// No description provided for @nutritionGoalBiologicalSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Biological sex'**
  String get nutritionGoalBiologicalSexLabel;

  /// No description provided for @nutritionGoalSexEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Used for basal metabolic rate calculation'**
  String get nutritionGoalSexEstimateLabel;

  /// No description provided for @nutritionGoalGeneralEstimatesSub.
  ///
  /// In en, this message translates to:
  /// **'Standard nutritional equations based on your profile'**
  String get nutritionGoalGeneralEstimatesSub;

  /// No description provided for @nutritionGoalUseMaintenanceBtn.
  ///
  /// In en, this message translates to:
  /// **'Use Maintenance Targets'**
  String get nutritionGoalUseMaintenanceBtn;

  /// No description provided for @nutritionGoalAboutCaloriePlanning.
  ///
  /// In en, this message translates to:
  /// **'About Calorie & Macro Planning'**
  String get nutritionGoalAboutCaloriePlanning;

  /// No description provided for @nutritionTrackerDailyTargetsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Daily targets'**
  String get nutritionTrackerDailyTargetsTooltip;

  /// No description provided for @nutritionTrackerPrevDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get nutritionTrackerPrevDayTooltip;

  /// No description provided for @nutritionTrackerNextDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nutritionTrackerNextDayTooltip;

  /// No description provided for @nutritionTrackerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutritionTrackerToday;

  /// No description provided for @nutritionTrackerTargetSummary.
  ///
  /// In en, this message translates to:
  /// **'{goal} kcal daily target'**
  String nutritionTrackerTargetSummary(int goal);

  /// No description provided for @nutritionTrackerRemaining.
  ///
  /// In en, this message translates to:
  /// **'{diff} remaining'**
  String nutritionTrackerRemaining(int diff);

  /// No description provided for @nutritionTrackerAboveTarget.
  ///
  /// In en, this message translates to:
  /// **'{diff} above target'**
  String nutritionTrackerAboveTarget(int diff);

  /// No description provided for @nutritionTrackerOfGrams.
  ///
  /// In en, this message translates to:
  /// **'of {goal} g'**
  String nutritionTrackerOfGrams(int goal);

  /// No description provided for @nutritionTrackerNoTargetSet.
  ///
  /// In en, this message translates to:
  /// **'No target set'**
  String get nutritionTrackerNoTargetSet;

  /// No description provided for @nutritionTrackerEstimatesNotice.
  ///
  /// In en, this message translates to:
  /// **'Nutrition estimates are based on your saved portions. Meal details sync to your account; photos stay on this device and may be unavailable on another phone. Your diary follows the calendar dates you choose.'**
  String get nutritionTrackerEstimatesNotice;

  /// No description provided for @nutritionTrackerShareMealTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share {name}'**
  String nutritionTrackerShareMealTooltip(String name);

  /// No description provided for @nutritionTrackerRemoveMealTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String nutritionTrackerRemoveMealTooltip(String name);

  /// No description provided for @nutritionTrackerManualNotes.
  ///
  /// In en, this message translates to:
  /// **'Nutrition entered manually.'**
  String get nutritionTrackerManualNotes;

  /// No description provided for @nutritionTrackerOneServing.
  ///
  /// In en, this message translates to:
  /// **'1 serving'**
  String get nutritionTrackerOneServing;

  /// No description provided for @nutritionTrackerSyncError.
  ///
  /// In en, this message translates to:
  /// **'Could not sync your diary. Check your connection and try again.'**
  String get nutritionTrackerSyncError;

  /// No description provided for @nutritionTrackerSyncMealError.
  ///
  /// In en, this message translates to:
  /// **'Could not sync this meal. Your input is still here; retry to save it.'**
  String get nutritionTrackerSyncMealError;

  /// No description provided for @nutritionTrackerEnterMealName.
  ///
  /// In en, this message translates to:
  /// **'Enter a meal name'**
  String get nutritionTrackerEnterMealName;

  /// No description provided for @nutritionTrackerChooseMealTypeNotice.
  ///
  /// In en, this message translates to:
  /// **'Choose Breakfast, Lunch, Dinner or Snack after tapping Save meal.'**
  String get nutritionTrackerChooseMealTypeNotice;

  /// No description provided for @nutritionTrackerEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number, including 0'**
  String get nutritionTrackerEnterValidNumber;

  /// No description provided for @nutritionTrackerSaveTargetsError.
  ///
  /// In en, this message translates to:
  /// **'Could not save targets. Your input is still here.'**
  String get nutritionTrackerSaveTargetsError;

  /// No description provided for @nutritionTrackerSetTargetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the targets that suit your plan. Leave a field empty to track without a target.'**
  String get nutritionTrackerSetTargetsSubtitle;

  /// No description provided for @nutritionTrackerEnterValidDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid daily target'**
  String get nutritionTrackerEnterValidDailyTarget;

  /// No description provided for @themeServiceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeServiceLight;

  /// No description provided for @themeServiceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeServiceDark;

  /// No description provided for @themeServiceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeServiceSystem;

  /// No description provided for @themeSelectorAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeSelectorAppearance;

  /// No description provided for @themeSelectorChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose the app theme'**
  String get themeSelectorChooseTheme;

  /// No description provided for @campaignServiceAnnouncementExpired.
  ///
  /// In en, this message translates to:
  /// **'This announcement has expired or is unavailable.'**
  String get campaignServiceAnnouncementExpired;

  /// No description provided for @campaignServiceOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get campaignServiceOpenLinkFailed;

  /// No description provided for @campaignServiceLocationTbd.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get campaignServiceLocationTbd;

  /// No description provided for @campaignServiceCompanyIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get campaignServiceCompanyIndependent;

  /// No description provided for @locationReminderTitleCoach.
  ///
  /// In en, this message translates to:
  /// **'Help nearby clients find you'**
  String get locationReminderTitleCoach;

  /// No description provided for @locationReminderTitleClient.
  ///
  /// In en, this message translates to:
  /// **'Find coaches closer to you'**
  String get locationReminderTitleClient;

  /// No description provided for @locationReminderBodyCoach.
  ///
  /// In en, this message translates to:
  /// **'Enable location to help clients discover you nearby and see an approximate distance. Only your city and distance are shown; your address stays private.'**
  String get locationReminderBodyCoach;

  /// No description provided for @locationReminderBodyClient.
  ///
  /// In en, this message translates to:
  /// **'Enable location for nearby coach recommendations and approximate distances. Only your city is public; your address stays private.'**
  String get locationReminderBodyClient;

  /// No description provided for @locationReminderNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get locationReminderNotNow;

  /// No description provided for @locationReminderEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get locationReminderEnable;

  /// No description provided for @mealShareServiceMarketingCaption.
  ///
  /// In en, this message translates to:
  /// **'🥗 Just tracked my meal with SIRVYA AI!\n🍽️ {mealName}\n🔥 {cal} kcal · 🥩 {protein}g Protein · 🍚 {carbs}g Carbs · 🥑 {fat}g Fat\n\nScan meals, track your macros & reach your fitness goals with elite coaches on SIRVYA! 💪✨\n📲 Download SIRVYA: https://sirvya.com\n#SIRVYA #Fitness #Nutrition #MealScan #HealthyEating #Coach'**
  String mealShareServiceMarketingCaption(
      String mealName, int cal, int protein, int carbs, int fat);

  /// No description provided for @mealShareServiceSubject.
  ///
  /// In en, this message translates to:
  /// **'Tracked with SIRVYA: {mealName}'**
  String mealShareServiceSubject(String mealName);

  /// No description provided for @mealShareServiceCopiedFallback.
  ///
  /// In en, this message translates to:
  /// **'Meal summary copied to clipboard! You can paste it into WhatsApp or Instagram.'**
  String get mealShareServiceCopiedFallback;

  /// No description provided for @mealShareServiceCaptionCopied.
  ///
  /// In en, this message translates to:
  /// **'Meal caption & SIRVYA link copied to clipboard!'**
  String get mealShareServiceCaptionCopied;

  /// No description provided for @mediaPickerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow camera or photo access for Sirvya in your phone Settings, then try again.'**
  String get mediaPickerPermissionDenied;

  /// No description provided for @mediaPickerOpenPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this photo. Please try again.'**
  String get mediaPickerOpenPhotoFailed;

  /// No description provided for @notificationNavClientFallback.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get notificationNavClientFallback;

  /// No description provided for @notificationNavTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationNavTitleFallback;

  /// No description provided for @notificationNavBodyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get notificationNavBodyUnavailable;

  /// No description provided for @notificationNavClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get notificationNavClose;

  /// No description provided for @notificationServiceChannelName.
  ///
  /// In en, this message translates to:
  /// **'Sirvya Notifications'**
  String get notificationServiceChannelName;

  /// No description provided for @notificationServiceChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'This channel is used for important notifications.'**
  String get notificationServiceChannelDesc;

  /// No description provided for @appleAuthIosOnly.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is currently available on iPhone and iPad.'**
  String get appleAuthIosOnly;

  /// No description provided for @appleAuthFirebaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Firebase authentication failed.'**
  String get appleAuthFirebaseFailed;

  /// No description provided for @appleAuthIdTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve Firebase ID token.'**
  String get appleAuthIdTokenFailed;

  /// No description provided for @appleAuthInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from server.'**
  String get appleAuthInvalidResponse;

  /// No description provided for @appleAuthAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended.'**
  String get appleAuthAccountSuspended;

  /// No description provided for @appleAuthSignInError.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in error ({statusCode})'**
  String appleAuthSignInError(int statusCode);

  /// No description provided for @googleAuthFirebaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Firebase authentication failed.'**
  String get googleAuthFirebaseFailed;

  /// No description provided for @googleAuthIdTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve Firebase ID token.'**
  String get googleAuthIdTokenFailed;

  /// No description provided for @googleAuthInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from server.'**
  String get googleAuthInvalidResponse;

  /// No description provided for @googleAuthAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended.'**
  String get googleAuthAccountSuspended;

  /// No description provided for @googleAuthSignInError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in error ({statusCode})'**
  String googleAuthSignInError(int statusCode);

  /// No description provided for @accountPasswordSheetServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server. Please try again.'**
  String get accountPasswordSheetServerUnreachable;

  /// No description provided for @accountPasswordSheetEnterField.
  ///
  /// In en, this message translates to:
  /// **'Enter {label}'**
  String accountPasswordSheetEnterField(String label);

  /// No description provided for @accountPasswordSheetMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get accountPasswordSheetMinLength;

  /// No description provided for @accountPasswordSheetPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get accountPasswordSheetPasswordsMismatch;

  /// No description provided for @accountPasswordSheetShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountPasswordSheetShowPassword;

  /// No description provided for @accountPasswordSheetHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountPasswordSheetHidePassword;

  /// No description provided for @accountPasswordSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get accountPasswordSheetClose;

  /// No description provided for @accountPasswordSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get accountPasswordSheetTitle;

  /// No description provided for @accountPasswordSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password with at least 8 characters that you don’t use elsewhere.'**
  String get accountPasswordSheetSubtitle;

  /// No description provided for @accountPasswordSheetCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountPasswordSheetCurrentLabel;

  /// No description provided for @accountPasswordSheetNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountPasswordSheetNewLabel;

  /// No description provided for @accountPasswordSheetConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get accountPasswordSheetConfirmLabel;

  /// No description provided for @accountPasswordSheetUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating password…'**
  String get accountPasswordSheetUpdating;

  /// No description provided for @accountPasswordSheetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get accountPasswordSheetUpdate;

  /// No description provided for @appUpdatePromptLinkNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The update link is not configured yet. Please contact Sirvya support.'**
  String get appUpdatePromptLinkNotConfigured;

  /// No description provided for @appUpdatePromptStoreOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store. Please try again or check for the update in your app store.'**
  String get appUpdatePromptStoreOpenFailed;

  /// No description provided for @appUpdatePromptUpdateRequiredBadge.
  ///
  /// In en, this message translates to:
  /// **'UPDATE REQUIRED'**
  String get appUpdatePromptUpdateRequiredBadge;

  /// No description provided for @appUpdatePromptNewVersionBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW VERSION'**
  String get appUpdatePromptNewVersionBadge;

  /// No description provided for @appUpdatePromptMandatoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Sirvya to continue'**
  String get appUpdatePromptMandatoryTitle;

  /// No description provided for @appUpdatePromptOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'A fresh version of Sirvya'**
  String get appUpdatePromptOptionalTitle;

  /// No description provided for @appUpdatePromptMandatoryBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Install the latest version to keep using the app.'**
  String get appUpdatePromptMandatoryBody;

  /// No description provided for @appUpdatePromptOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'The latest version is ready. Update now for the latest improvements.'**
  String get appUpdatePromptOptionalBody;

  /// No description provided for @appUpdatePromptInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed {version}'**
  String appUpdatePromptInstalledVersion(String version);

  /// No description provided for @appUpdatePromptMinimumVersion.
  ///
  /// In en, this message translates to:
  /// **'Minimum {version}'**
  String appUpdatePromptMinimumVersion(String version);

  /// No description provided for @appUpdatePromptOpeningStore.
  ///
  /// In en, this message translates to:
  /// **'Opening the store…'**
  String get appUpdatePromptOpeningStore;

  /// No description provided for @appUpdatePromptUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get appUpdatePromptUpdateNow;

  /// No description provided for @appUpdatePromptChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get appUpdatePromptChecking;

  /// No description provided for @appUpdatePromptCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get appUpdatePromptCheckAgain;

  /// No description provided for @appUpdatePromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdatePromptLater;

  /// No description provided for @campaignDialogExploreNow.
  ///
  /// In en, this message translates to:
  /// **'Explore now'**
  String get campaignDialogExploreNow;

  /// No description provided for @campaignDialogGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get campaignDialogGotIt;

  /// No description provided for @campaignDialogBrandHeader.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA  /  INSIDE'**
  String get campaignDialogBrandHeader;

  /// No description provided for @campaignDialogCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close announcement'**
  String get campaignDialogCloseTooltip;

  /// No description provided for @campaignDialogSelectedForYou.
  ///
  /// In en, this message translates to:
  /// **'SELECTED FOR YOU'**
  String get campaignDialogSelectedForYou;

  /// No description provided for @campaignDialogDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Something new at Sirvya'**
  String get campaignDialogDefaultTitle;

  /// No description provided for @campaignDialogMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get campaignDialogMaybeLater;

  /// No description provided for @clientProfileViewPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'View profile photo'**
  String get clientProfileViewPhotoLabel;

  /// No description provided for @clientProfileChangePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get clientProfileChangePhotoTooltip;

  /// No description provided for @clientProfilePremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA PREMIUM'**
  String get clientProfilePremiumBadge;

  /// No description provided for @clientProfileJourneyBadge.
  ///
  /// In en, this message translates to:
  /// **'YOUR SIRVYA JOURNEY'**
  String get clientProfileJourneyBadge;

  /// No description provided for @clientProfileWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sirvya'**
  String get clientProfileWelcomeTitle;

  /// No description provided for @clientProfileSetCity.
  ///
  /// In en, this message translates to:
  /// **'Set your city'**
  String get clientProfileSetCity;

  /// No description provided for @clientProfilePersonalSpaceNote.
  ///
  /// In en, this message translates to:
  /// **'Your personal space. Built around your progress.'**
  String get clientProfilePersonalSpaceNote;

  /// No description provided for @clientProfileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get clientProfileCompletionTitle;

  /// No description provided for @clientProfileCompletionDetailsAdded.
  ///
  /// In en, this message translates to:
  /// **'Profile completion · {completed} of {total} details added'**
  String clientProfileCompletionDetailsAdded(int completed, int total);

  /// No description provided for @clientProfileCompletionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get clientProfileCompletionSemantic;

  /// No description provided for @clientProfileStepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add your profile photo'**
  String get clientProfileStepPhoto;

  /// No description provided for @clientProfileStepFirstName.
  ///
  /// In en, this message translates to:
  /// **'Add your first name'**
  String get clientProfileStepFirstName;

  /// No description provided for @clientProfileStepLastName.
  ///
  /// In en, this message translates to:
  /// **'Add your last name'**
  String get clientProfileStepLastName;

  /// No description provided for @clientProfileStepEmail.
  ///
  /// In en, this message translates to:
  /// **'Add your email address'**
  String get clientProfileStepEmail;

  /// No description provided for @clientProfileStepPhone.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get clientProfileStepPhone;

  /// No description provided for @clientProfileStepCity.
  ///
  /// In en, this message translates to:
  /// **'Set your city'**
  String get clientProfileStepCity;

  /// No description provided for @clientProfileStepHeight.
  ///
  /// In en, this message translates to:
  /// **'Add your height'**
  String get clientProfileStepHeight;

  /// No description provided for @clientProfileStepInterests.
  ///
  /// In en, this message translates to:
  /// **'Choose your fitness interests'**
  String get clientProfileStepInterests;

  /// No description provided for @connectionRecoveryCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection'**
  String get connectionRecoveryCheckTitle;

  /// No description provided for @connectionRecoveryLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get connectionRecoveryLater;

  /// No description provided for @connectionRecoveryRefreshApp.
  ///
  /// In en, this message translates to:
  /// **'Refresh app'**
  String get connectionRecoveryRefreshApp;

  /// No description provided for @locationPickerFindingCity.
  ///
  /// In en, this message translates to:
  /// **'Finding your city…'**
  String get locationPickerFindingCity;

  /// No description provided for @locationPickerUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationPickerUseCurrent;

  /// No description provided for @locationPickerCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get locationPickerCityLabel;

  /// No description provided for @locationPickerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Detected address (private)'**
  String get locationPickerAddressLabel;

  /// No description provided for @locationPickerPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Use the location button to fill these fields automatically. Only your city appears to other users. Your detailed address and coordinates stay private.'**
  String get locationPickerPrivacyNotice;

  /// No description provided for @locationPickerKeepUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep my location updated'**
  String get locationPickerKeepUpdatedTitle;

  /// No description provided for @locationPickerKeepUpdatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh every 15 minutes. Background updates require Always allow permission.'**
  String get locationPickerKeepUpdatedSubtitle;

  /// No description provided for @mealDiaryMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move your meal'**
  String get mealDiaryMoveTitle;

  /// No description provided for @mealDiarySaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your meal'**
  String get mealDiarySaveTitle;

  /// No description provided for @mealDiaryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mealDiaryCancel;

  /// No description provided for @mealDiaryMoveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose its new place in your diary.'**
  String get mealDiaryMoveSubtitle;

  /// No description provided for @mealDiarySaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to add this meal?'**
  String get mealDiarySaveSubtitle;

  /// No description provided for @mealDiaryTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealDiaryTypeBreakfast;

  /// No description provided for @mealDiaryTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealDiaryTypeLunch;

  /// No description provided for @mealDiaryTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDiaryTypeDinner;

  /// No description provided for @mealDiaryTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealDiaryTypeSnack;

  /// No description provided for @mealDiaryMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {mealType}'**
  String mealDiaryMoveTo(String mealType);

  /// No description provided for @mealDiarySaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to {mealType}'**
  String mealDiarySaveTo(String mealType);

  /// No description provided for @mealDiaryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this meal?'**
  String get mealDiaryDeleteTitle;

  /// No description provided for @mealDiaryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed from your diary and daily totals. This cannot be undone.'**
  String mealDiaryDeleteBody(String name);

  /// No description provided for @mealDiaryKeepMeal.
  ///
  /// In en, this message translates to:
  /// **'Keep meal'**
  String get mealDiaryKeepMeal;

  /// No description provided for @mealDiaryDeleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get mealDiaryDeleteMeal;

  /// No description provided for @mealLiveCameraNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera found. Choose a photo from your gallery.'**
  String get mealLiveCameraNoCamera;

  /// No description provided for @mealLiveCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in your device or browser settings, then retry.'**
  String get mealLiveCameraPermissionDenied;

  /// No description provided for @mealLiveCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable. Retry or choose a photo from your gallery.'**
  String get mealLiveCameraUnavailable;

  /// No description provided for @mealLiveCameraCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not capture the photo. Try again.'**
  String get mealLiveCameraCaptureFailed;

  /// No description provided for @mealLiveCameraStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get mealLiveCameraStarting;

  /// No description provided for @mealLiveCameraRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry camera'**
  String get mealLiveCameraRetry;

  /// No description provided for @mealScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sirvya nutrition'**
  String get mealScannerTitle;

  /// No description provided for @mealScannerSavedMealsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved meals'**
  String get mealScannerSavedMealsTooltip;

  /// No description provided for @mealScannerDiscoverButton.
  ///
  /// In en, this message translates to:
  /// **'Discover your meal'**
  String get mealScannerDiscoverButton;

  /// No description provided for @mealScannerFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Photo sent for AI analysis · Nutrition is estimated'**
  String get mealScannerFooterDisclaimer;

  /// No description provided for @mealScannerMeetYourMealChip.
  ///
  /// In en, this message translates to:
  /// **'MEET YOUR MEAL'**
  String get mealScannerMeetYourMealChip;

  /// No description provided for @mealScannerHeading.
  ///
  /// In en, this message translates to:
  /// **'Your plate,\nunderstood.'**
  String get mealScannerHeading;

  /// No description provided for @mealScannerSubheading.
  ///
  /// In en, this message translates to:
  /// **'A little clarity for every bite.\nFrom everyday favorites to Moroccan classics.'**
  String get mealScannerSubheading;

  /// No description provided for @mealScannerStepCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get mealScannerStepCapture;

  /// No description provided for @mealScannerStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get mealScannerStepReview;

  /// No description provided for @mealScannerStepDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get mealScannerStepDiscover;

  /// No description provided for @mealScannerLetsTakeALook.
  ///
  /// In en, this message translates to:
  /// **'Let’s take a look'**
  String get mealScannerLetsTakeALook;

  /// No description provided for @mealScannerGoodLightHint.
  ///
  /// In en, this message translates to:
  /// **'Good light. Whole plate. One photo.'**
  String get mealScannerGoodLightHint;

  /// No description provided for @mealScannerKeepWholePlate.
  ///
  /// In en, this message translates to:
  /// **'Keep the whole plate in view'**
  String get mealScannerKeepWholePlate;

  /// No description provided for @mealScannerPhotoReady.
  ///
  /// In en, this message translates to:
  /// **'Photo ready for analysis'**
  String get mealScannerPhotoReady;

  /// No description provided for @mealScannerAnalyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting to know your meal'**
  String get mealScannerAnalyzingTitle;

  /// No description provided for @mealScannerAnalyzingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients first. Nutrition next.'**
  String get mealScannerAnalyzingSubtitle;

  /// No description provided for @mealScannerFromGalleryTooltip.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get mealScannerFromGalleryTooltip;

  /// No description provided for @mealScannerGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get mealScannerGalleryLabel;

  /// No description provided for @mealScannerRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get mealScannerRetakePhoto;

  /// No description provided for @mealScannerCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get mealScannerCapturePhoto;

  /// No description provided for @mealScannerPortionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much are you eating?'**
  String get mealScannerPortionQuestion;

  /// No description provided for @mealScannerPortionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your portion of the food in this photo.'**
  String get mealScannerPortionSubtitle;

  /// No description provided for @mealScannerPortionHalf.
  ///
  /// In en, this message translates to:
  /// **'½ plate'**
  String get mealScannerPortionHalf;

  /// No description provided for @mealScannerPortionOne.
  ///
  /// In en, this message translates to:
  /// **'1 plate'**
  String get mealScannerPortionOne;

  /// No description provided for @mealScannerPortionOneHalf.
  ///
  /// In en, this message translates to:
  /// **'1½ plates'**
  String get mealScannerPortionOneHalf;

  /// No description provided for @mealScannerPortionTwo.
  ///
  /// In en, this message translates to:
  /// **'2 plates'**
  String get mealScannerPortionTwo;

  /// No description provided for @mealScannerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Anything we can’t see?'**
  String get mealScannerNotesLabel;

  /// No description provided for @mealScannerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Extra olive oil, sauces, sugar…'**
  String get mealScannerNotesHint;

  /// No description provided for @mealScanLimitPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal scans are paused'**
  String get mealScanLimitPausedTitle;

  /// No description provided for @mealScanLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re all scanned for today'**
  String get mealScanLimitReachedTitle;

  /// No description provided for @mealScanLimitUsedToday.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} scans used today'**
  String mealScanLimitUsedToday(int used, int total);

  /// No description provided for @mealScanLimitPerDay.
  ///
  /// In en, this message translates to:
  /// **'{dailyLimit, plural, =1{1 scan per day} other{{dailyLimit} scans per day}}'**
  String mealScanLimitPerDay(int dailyLimit);

  /// No description provided for @mealScanLimitPerDayWithBonus.
  ///
  /// In en, this message translates to:
  /// **'{dailyLimit, plural, =1{1 scan per day} other{{dailyLimit} scans per day}} + {bonus} extra today'**
  String mealScanLimitPerDayWithBonus(int dailyLimit, int bonus);

  /// No description provided for @mealScanLimitPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Meal scanning is currently disabled for your account. Your admin can update your allowance.'**
  String get mealScanLimitPausedBody;

  /// No description provided for @mealScanLimitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached your allowance for today. Come back after midnight UTC for your next daily scans, or ask your admin for extra scans.'**
  String get mealScanLimitReachedBody;

  /// No description provided for @mealScanLimitGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get mealScanLimitGotIt;

  /// No description provided for @mealShareCardCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get mealShareCardCalories;

  /// No description provided for @mealShareCardProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get mealShareCardProtein;

  /// No description provided for @mealShareCardCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get mealShareCardCarbs;

  /// No description provided for @mealShareCardFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get mealShareCardFat;

  /// No description provided for @mealShareModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Your Meal'**
  String get mealShareModalTitle;

  /// No description provided for @mealShareModalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sirvya photo overlay for Stories & Posts'**
  String get mealShareModalSubtitle;

  /// No description provided for @mealShareModalClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mealShareModalClose;

  /// No description provided for @mealShareModalStoryTab.
  ///
  /// In en, this message translates to:
  /// **'Story (9:16)'**
  String get mealShareModalStoryTab;

  /// No description provided for @mealShareModalPostTab.
  ///
  /// In en, this message translates to:
  /// **'Post Card'**
  String get mealShareModalPostTab;

  /// No description provided for @mealShareModalStyleOverlay.
  ///
  /// In en, this message translates to:
  /// **'Sirvya Overlay'**
  String get mealShareModalStyleOverlay;

  /// No description provided for @mealShareModalStyleCard.
  ///
  /// In en, this message translates to:
  /// **'Card View'**
  String get mealShareModalStyleCard;

  /// No description provided for @mealShareModalIncludeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Include Ingredients Breakdown'**
  String get mealShareModalIncludeIngredients;

  /// No description provided for @mealShareModalShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share Story / Post'**
  String get mealShareModalShareButton;

  /// No description provided for @mealShareModalCopyCaptionButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Caption & Link'**
  String get mealShareModalCopyCaptionButton;

  /// No description provided for @mealVisualsIngredientIllustration.
  ///
  /// In en, this message translates to:
  /// **'{name} illustration'**
  String mealVisualsIngredientIllustration(String name);

  /// No description provided for @mealVisualsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal analysis'**
  String get mealVisualsAnalysisTitle;

  /// No description provided for @mealVisualsShareMealTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share meal'**
  String get mealVisualsShareMealTooltip;

  /// No description provided for @mealVisualsBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mealVisualsBackTooltip;

  /// No description provided for @mealVisualsChipManualDiary.
  ///
  /// In en, this message translates to:
  /// **'YOUR MEAL DIARY'**
  String get mealVisualsChipManualDiary;

  /// No description provided for @mealVisualsChipScan.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA MEAL SCAN'**
  String get mealVisualsChipScan;

  /// No description provided for @mealVisualsManualServing.
  ///
  /// In en, this message translates to:
  /// **'1 serving · Entered nutrition'**
  String get mealVisualsManualServing;

  /// No description provided for @mealVisualsEstimatedOnePlate.
  ///
  /// In en, this message translates to:
  /// **'1 plate · Estimated nutrition'**
  String get mealVisualsEstimatedOnePlate;

  /// No description provided for @mealVisualsEstimatedPlates.
  ///
  /// In en, this message translates to:
  /// **'{portion} plates · Estimated nutrition'**
  String mealVisualsEstimatedPlates(String portion);

  /// No description provided for @mealVisualsInsideYourPlate.
  ///
  /// In en, this message translates to:
  /// **'Inside your plate'**
  String get mealVisualsInsideYourPlate;

  /// No description provided for @mealVisualsIngredientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
  String mealVisualsIngredientsCount(int count);

  /// No description provided for @mealVisualsFineTunePortions.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune portions to make this estimate yours.'**
  String get mealVisualsFineTunePortions;

  /// No description provided for @mealVisualsAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add an ingredient'**
  String get mealVisualsAddIngredient;

  /// No description provided for @mealVisualsManualDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nutrition is based on the values you entered for this serving.'**
  String get mealVisualsManualDisclaimer;

  /// No description provided for @mealVisualsScanDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Ingredient images are illustrations. Nutrition is estimated from your meal photo and portion details.'**
  String get mealVisualsScanDisclaimer;

  /// No description provided for @mealVisualsTotalEnergy.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ENERGY'**
  String get mealVisualsTotalEnergy;

  /// No description provided for @mealVisualsNutritionEntered.
  ///
  /// In en, this message translates to:
  /// **'Nutrition you entered'**
  String get mealVisualsNutritionEntered;

  /// No description provided for @mealVisualsEstimateOfPortion.
  ///
  /// In en, this message translates to:
  /// **'An estimate of this portion'**
  String get mealVisualsEstimateOfPortion;

  /// No description provided for @mealVisualsMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get mealVisualsMacroProtein;

  /// No description provided for @mealVisualsMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get mealVisualsMacroCarbs;

  /// No description provided for @mealVisualsMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get mealVisualsMacroFat;

  /// No description provided for @mealVisualsShareToTitle.
  ///
  /// In en, this message translates to:
  /// **'Share to'**
  String get mealVisualsShareToTitle;

  /// No description provided for @mealVisualsShareToSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post your meal & macros to Instagram, WhatsApp & more'**
  String get mealVisualsShareToSubtitle;

  /// No description provided for @mealVisualsChannelStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get mealVisualsChannelStory;

  /// No description provided for @mealVisualsChannelWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get mealVisualsChannelWhatsApp;

  /// No description provided for @mealVisualsChannelPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get mealVisualsChannelPost;

  /// No description provided for @mealVisualsEditIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String mealVisualsEditIngredientTooltip(String name);

  /// No description provided for @mealVisualsMoreOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More options for {name}'**
  String mealVisualsMoreOptionsTooltip(String name);

  /// No description provided for @mealVisualsRemoveIngredient.
  ///
  /// In en, this message translates to:
  /// **'Remove ingredient'**
  String get mealVisualsRemoveIngredient;

  /// No description provided for @mealVisualsContextTitle.
  ///
  /// In en, this message translates to:
  /// **'A little context'**
  String get mealVisualsContextTitle;

  /// No description provided for @mealVisualsConfidenceManual.
  ///
  /// In en, this message translates to:
  /// **'Entered manually'**
  String get mealVisualsConfidenceManual;

  /// No description provided for @mealVisualsConfidenceLevel.
  ///
  /// In en, this message translates to:
  /// **'{level} confidence'**
  String mealVisualsConfidenceLevel(String level);

  /// No description provided for @mealVisualsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get mealVisualsSaveChanges;

  /// No description provided for @mealVisualsSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get mealVisualsSaveMeal;

  /// No description provided for @mealVisualsSaveBarFooter.
  ///
  /// In en, this message translates to:
  /// **'Account diary · Photos stay on this device'**
  String get mealVisualsSaveBarFooter;

  /// No description provided for @notificationCardCatNutrition.
  ///
  /// In en, this message translates to:
  /// **'YOUR NUTRITION'**
  String get notificationCardCatNutrition;

  /// No description provided for @notificationCardCatPricing.
  ///
  /// In en, this message translates to:
  /// **'PRICING'**
  String get notificationCardCatPricing;

  /// No description provided for @notificationCardCatMessage.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get notificationCardCatMessage;

  /// No description provided for @notificationCardCatFeedback.
  ///
  /// In en, this message translates to:
  /// **'FEEDBACK'**
  String get notificationCardCatFeedback;

  /// No description provided for @notificationCardCatSessions.
  ///
  /// In en, this message translates to:
  /// **'YOUR SESSIONS'**
  String get notificationCardCatSessions;

  /// No description provided for @notificationCardCatConnections.
  ///
  /// In en, this message translates to:
  /// **'CONNECTIONS'**
  String get notificationCardCatConnections;

  /// No description provided for @notificationCardCatUpdate.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA UPDATE'**
  String get notificationCardCatUpdate;

  /// No description provided for @notificationCardView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get notificationCardView;

  /// No description provided for @notificationCardJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationCardJustNow;

  /// No description provided for @notificationCardMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String notificationCardMinutesAgo(int minutes);

  /// No description provided for @notificationCardHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour ago} other{{hours} hours ago}}'**
  String notificationCardHoursAgo(int hours);

  /// No description provided for @notificationCardYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationCardYesterday;

  /// No description provided for @notificationInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Your latest updates'**
  String get notificationInboxTitle;

  /// No description provided for @notificationInboxAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up.'**
  String get notificationInboxAllCaughtUp;

  /// No description provided for @notificationInboxUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread · Keep your journey moving.'**
  String notificationInboxUnreadCount(int count);

  /// No description provided for @nutritionGoalCardTitle.
  ///
  /// In en, this message translates to:
  /// **'My nutrition goal'**
  String get nutritionGoalCardTitle;

  /// No description provided for @nutritionGoalCardSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get nutritionGoalCardSetGoal;

  /// No description provided for @nutritionGoalCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get nutritionGoalCardEdit;

  /// No description provided for @nutritionGoalCardLoadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load your goal · Retry'**
  String get nutritionGoalCardLoadFailedRetry;

  /// No description provided for @nutritionGoalCardEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose your goal and optional reminders. Start with balanced habits or set a personal weight goal.'**
  String get nutritionGoalCardEmptyPrompt;

  /// No description provided for @nutritionGoalCardPersonalGoal.
  ///
  /// In en, this message translates to:
  /// **'Your personal goal'**
  String get nutritionGoalCardPersonalGoal;

  /// No description provided for @nutritionGoalLabelBalanced.
  ///
  /// In en, this message translates to:
  /// **'Build balanced habits'**
  String get nutritionGoalLabelBalanced;

  /// No description provided for @nutritionGoalLabelLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight gradually'**
  String get nutritionGoalLabelLose;

  /// No description provided for @nutritionGoalLabelGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight gradually'**
  String get nutritionGoalLabelGain;

  /// No description provided for @nutritionGoalLabelMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain my weight'**
  String get nutritionGoalLabelMaintain;

  /// No description provided for @nutritionGoalCardStatusAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal reached · Choose a new goal when ready'**
  String get nutritionGoalCardStatusAchieved;

  /// No description provided for @nutritionGoalCardStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused · Resume whenever you like'**
  String get nutritionGoalCardStatusPaused;

  /// No description provided for @nutritionGoalCardStatusActiveRemindersOn.
  ///
  /// In en, this message translates to:
  /// **'Active · Reminders follow your preferences'**
  String get nutritionGoalCardStatusActiveRemindersOn;

  /// No description provided for @nutritionGoalCardStatusActiveRemindersOff.
  ///
  /// In en, this message translates to:
  /// **'Active · Reminders off'**
  String get nutritionGoalCardStatusActiveRemindersOff;

  /// No description provided for @nutritionGoalCardAddWeighInHint.
  ///
  /// In en, this message translates to:
  /// **'Add a recent weigh-in to track your goal.'**
  String get nutritionGoalCardAddWeighInHint;

  /// No description provided for @nutritionGoalCardBasedOnWeighIns.
  ///
  /// In en, this message translates to:
  /// **'Based on your saved weigh-ins. Completion uses recent check-ins, not a promised date.'**
  String get nutritionGoalCardBasedOnWeighIns;

  /// No description provided for @nutritionGoalCardProgressButton.
  ///
  /// In en, this message translates to:
  /// **'Monthly & yearly progress'**
  String get nutritionGoalCardProgressButton;

  /// No description provided for @nutritionReviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this review. Try again.'**
  String get nutritionReviewLoadError;

  /// No description provided for @nutritionReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress review'**
  String get nutritionReviewTitle;

  /// No description provided for @nutritionReviewMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get nutritionReviewMonthly;

  /// No description provided for @nutritionReviewYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get nutritionReviewYearly;

  /// No description provided for @nutritionReviewPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get nutritionReviewPreviousPeriod;

  /// No description provided for @nutritionReviewNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get nutritionReviewNextPeriod;

  /// No description provided for @nutritionReviewDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day logged} other{{count} days logged}}'**
  String nutritionReviewDaysLogged(int count);

  /// No description provided for @nutritionReviewSavedMeals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved meal} other{{count} saved meals}}'**
  String nutritionReviewSavedMeals(int count);

  /// No description provided for @nutritionReviewDailyAveragesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily averages'**
  String get nutritionReviewDailyAveragesTitle;

  /// No description provided for @nutritionReviewDailyAveragesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only days with saved meals are included. Unlogged days are not treated as zero intake.'**
  String get nutritionReviewDailyAveragesSubtitle;

  /// No description provided for @nutritionReviewWeightCheckInsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight check-ins'**
  String get nutritionReviewWeightCheckInsTitle;

  /// No description provided for @nutritionReviewWeightCheckInsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 check-in in this period} other{{count} check-ins in this period}}'**
  String nutritionReviewWeightCheckInsSubtitle(int count);

  /// No description provided for @nutritionReviewWeightRange.
  ///
  /// In en, this message translates to:
  /// **'{first} to {latest} kg'**
  String nutritionReviewWeightRange(String first, String latest);

  /// No description provided for @nutritionReviewFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is your logged history, not a complete measure of your intake. Small, consistent check-ins can help you understand your routine.'**
  String get nutritionReviewFooterDisclaimer;

  /// No description provided for @profileCompletedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile completed'**
  String get profileCompletedBadgeLabel;

  /// No description provided for @weightProgressHeaderTag.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROGRESS'**
  String get weightProgressHeaderTag;

  /// No description provided for @weightProgressHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Every check-in counts.'**
  String get weightProgressHeaderTitle;

  /// No description provided for @weightProgressLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get weightProgressLogTooltip;

  /// No description provided for @weightProgressRefreshHistory.
  ///
  /// In en, this message translates to:
  /// **'Refresh history'**
  String get weightProgressRefreshHistory;

  /// No description provided for @weightProgressCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get weightProgressCurrentWeight;

  /// No description provided for @weightProgressFirstWeighInHint.
  ///
  /// In en, this message translates to:
  /// **'Your first weigh-in starts here.'**
  String get weightProgressFirstWeighInHint;

  /// No description provided for @weightProgressLatestWeighIn.
  ///
  /// In en, this message translates to:
  /// **'Latest weigh-in · {date}'**
  String weightProgressLatestWeighIn(String date);

  /// No description provided for @weightProgressSinceFirst.
  ///
  /// In en, this message translates to:
  /// **'since your first weigh-in'**
  String get weightProgressSinceFirst;

  /// No description provided for @weightProgressStartingWeight.
  ///
  /// In en, this message translates to:
  /// **'Starting weight'**
  String get weightProgressStartingWeight;

  /// No description provided for @weightProgressWeighInsLogged.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins logged'**
  String get weightProgressWeighInsLogged;

  /// No description provided for @weightProgressTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight trend'**
  String get weightProgressTrendTitle;

  /// No description provided for @weightProgressTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little perspective on your journey.'**
  String get weightProgressTrendSubtitle;

  /// No description provided for @weightProgressPeriod7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get weightProgressPeriod7Days;

  /// No description provided for @weightProgressPeriod30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get weightProgressPeriod30Days;

  /// No description provided for @weightProgressPeriodRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get weightProgressPeriodRecent;

  /// No description provided for @weightProgressChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Weight trend, {count} weigh-ins. Selected {weight} kilograms on {date}.'**
  String weightProgressChartSemantics(int count, String weight, String date);

  /// No description provided for @weightProgressChartSinglePointHint.
  ///
  /// In en, this message translates to:
  /// **'Your first point is on the chart. Add another to see a trend. Dates in UTC.'**
  String get weightProgressChartSinglePointHint;

  /// No description provided for @weightProgressChartMultiPointHint.
  ///
  /// In en, this message translates to:
  /// **'Tap or slide across the chart to explore your weigh-ins. Dates in UTC.'**
  String get weightProgressChartMultiPointHint;

  /// No description provided for @weightProgressEmptyStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your story starts with one log.'**
  String get weightProgressEmptyStoryTitle;

  /// No description provided for @weightProgressEmptyPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins in this period.'**
  String get weightProgressEmptyPeriodTitle;

  /// No description provided for @weightProgressEmptyStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log a weight to start your personal trend.'**
  String get weightProgressEmptyStorySubtitle;

  /// No description provided for @weightProgressEmptyPeriodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Recent to see your latest available records.'**
  String get weightProgressEmptyPeriodSubtitle;

  /// No description provided for @weightProgressRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent weigh-ins'**
  String get weightProgressRecentTitle;

  /// No description provided for @weightProgressInViewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in view'**
  String weightProgressInViewCount(int count);

  /// No description provided for @weightProgressEmptyRecords.
  ///
  /// In en, this message translates to:
  /// **'Your recorded weights will appear here.'**
  String get weightProgressEmptyRecords;

  /// No description provided for @weightProgressFirstInView.
  ///
  /// In en, this message translates to:
  /// **'First in this view'**
  String get weightProgressFirstInView;

  /// No description provided for @weightProgressChangeFromPrevious.
  ///
  /// In en, this message translates to:
  /// **'{change} from previous'**
  String weightProgressChangeFromPrevious(String change);

  /// No description provided for @weightProgressChartLimitFooter.
  ///
  /// In en, this message translates to:
  /// **'Chart: up to the latest 90 saved weigh-ins. List: latest 5 in this view.'**
  String get weightProgressChartLimitFooter;

  /// No description provided for @weightProgressKeepRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a record, at your pace.'**
  String get weightProgressKeepRecordTitle;

  /// No description provided for @weightProgressKeepRecordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick check-in adds another point to your story.'**
  String get weightProgressKeepRecordSubtitle;

  /// No description provided for @weightProgressLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log a weigh-in'**
  String get weightProgressLogButton;

  /// No description provided for @weightProgressBmiLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI · {bmi}'**
  String weightProgressBmiLabel(String bmi);

  /// No description provided for @weightProgressBmiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From your latest weight and saved height.'**
  String get weightProgressBmiSubtitle;

  /// No description provided for @weightLogInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight between 0 and 500 kg.'**
  String get weightLogInvalidError;

  /// No description provided for @weightLogSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your entry is still here—please try again.'**
  String get weightLogSaveError;

  /// No description provided for @weightLogSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'A moment for you.'**
  String get weightLogSheetTitle;

  /// No description provided for @weightLogCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get weightLogCloseTooltip;

  /// No description provided for @weightLogSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your weight and keep your journey in view.'**
  String get weightLogSheetSubtitle;

  /// No description provided for @weightLogInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightLogInputLabel;

  /// No description provided for @weightLogRecordedTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded for today. You can use a dot or a comma.'**
  String get weightLogRecordedTodayHint;

  /// No description provided for @weightLogLastRecordedHint.
  ///
  /// In en, this message translates to:
  /// **'Last recorded: {weight} kg · Recorded for today.'**
  String weightLogLastRecordedHint(String weight);

  /// No description provided for @weightLogSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get weightLogSaving;

  /// No description provided for @weightLogSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save weigh-in'**
  String get weightLogSaveButton;

  /// No description provided for @announcementClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get announcementClose;

  /// No description provided for @announcementWhatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What’s new at Sirvya'**
  String get announcementWhatsNewTitle;

  /// No description provided for @announcementDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss announcements'**
  String get announcementDismissTooltip;

  /// No description provided for @announcementSirvyaUpdate.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA UPDATE'**
  String get announcementSirvyaUpdate;

  /// No description provided for @announcementExploreCoaches.
  ///
  /// In en, this message translates to:
  /// **'Explore coaches'**
  String get announcementExploreCoaches;

  /// No description provided for @announcementLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get announcementLearnMore;

  /// No description provided for @announcementReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get announcementReadMore;

  /// No description provided for @chatImageBatchSendPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 photo} other{Send {count} photos}}'**
  String chatImageBatchSendPhotos(int count);

  /// No description provided for @chatImageBatchCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Caption for the first photo (optional)'**
  String get chatImageBatchCaptionHint;

  /// No description provided for @chatImageBatchCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatImageBatchCancel;

  /// No description provided for @chatSelectionSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String chatSelectionSelectedCount(int count);

  /// No description provided for @chatSelectionSelectAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select all loaded messages'**
  String get chatSelectionSelectAllTooltip;

  /// No description provided for @chatSelectionDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete messages'**
  String get chatSelectionDeleteTooltip;

  /// No description provided for @clientNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get clientNavHome;

  /// No description provided for @clientNavExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get clientNavExplore;

  /// No description provided for @clientNavSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get clientNavSessions;

  /// No description provided for @clientNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get clientNavProfile;

  /// No description provided for @clientNavScanMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan your meal'**
  String get clientNavScanMealLabel;

  /// No description provided for @coachHeaderNotificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String coachHeaderNotificationsUnread(int count);

  /// No description provided for @coachHeaderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get coachHeaderNotifications;

  /// No description provided for @coachHeaderOpenProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Coach Profile'**
  String get coachHeaderOpenProfileLabel;

  /// No description provided for @coachNavbarDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get coachNavbarDashboard;

  /// No description provided for @coachNavbarCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get coachNavbarCalendar;

  /// No description provided for @coachNavbarChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get coachNavbarChats;

  /// No description provided for @coachNavbarClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get coachNavbarClients;

  /// No description provided for @coachNavbarProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get coachNavbarProfile;

  /// No description provided for @conversationSendingPhotoBatch.
  ///
  /// In en, this message translates to:
  /// **'Sending photo {current} of {total}…'**
  String conversationSendingPhotoBatch(int current, int total);

  /// No description provided for @conversationSendingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Sending your attachment…'**
  String get conversationSendingAttachment;

  /// No description provided for @conversationSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Sending message…'**
  String get conversationSendingMessage;

  /// No description provided for @conversationRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. Your messages are still here.'**
  String get conversationRefreshError;

  /// No description provided for @conversationRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get conversationRetry;

  /// No description provided for @conversationNewUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String conversationNewUnread(int count);

  /// No description provided for @conversationBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get conversationBackTooltip;

  /// No description provided for @conversationStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'Photos and voice notes stay on this device'**
  String get conversationStorageNotice;

  /// No description provided for @conversationDismissNoticeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss storage notice'**
  String get conversationDismissNoticeTooltip;

  /// No description provided for @conversationLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation…'**
  String get conversationLoading;

  /// No description provided for @conversationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get conversationEmptyTitle;

  /// No description provided for @conversationEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A little hello goes a long way.'**
  String get conversationEmptySubtitle;

  /// No description provided for @conversationRetryOlder.
  ///
  /// In en, this message translates to:
  /// **'Retry older messages'**
  String get conversationRetryOlder;

  /// No description provided for @conversationDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get conversationDayToday;

  /// No description provided for @conversationDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get conversationDayYesterday;

  /// No description provided for @conversationDeletedByYou.
  ///
  /// In en, this message translates to:
  /// **'You deleted this message'**
  String get conversationDeletedByYou;

  /// No description provided for @conversationDeletedByOther.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get conversationDeletedByOther;

  /// No description provided for @conversationAttachPhotosTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach photos'**
  String get conversationAttachPhotosTooltip;

  /// No description provided for @conversationRecordingTimer.
  ///
  /// In en, this message translates to:
  /// **'Recording {time}'**
  String conversationRecordingTimer(String time);

  /// No description provided for @conversationWriteMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get conversationWriteMessageHint;

  /// No description provided for @conversationPhotoGalleryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Photo gallery'**
  String get conversationPhotoGalleryTooltip;

  /// No description provided for @conversationStopRecordingSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop recording and send'**
  String get conversationStopRecordingSendTooltip;

  /// No description provided for @conversationSendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get conversationSendMessageTooltip;

  /// No description provided for @conversationRecordVoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get conversationRecordVoiceTooltip;

  /// No description provided for @exploreCoachGridRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get exploreCoachGridRemoveFavorite;

  /// No description provided for @exploreCoachGridAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get exploreCoachGridAddFavorite;

  /// No description provided for @exploreCoachGridNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get exploreCoachGridNew;

  /// No description provided for @exploreCoachGridFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price} MAD'**
  String exploreCoachGridFromPrice(int price);

  /// No description provided for @exploreCoachGridPriceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get exploreCoachGridPriceOnRequest;

  /// No description provided for @exploreCoachGridViewAndBook.
  ///
  /// In en, this message translates to:
  /// **'View & Book'**
  String get exploreCoachGridViewAndBook;

  /// No description provided for @exploreCoachMapLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the map. Please try again.'**
  String get exploreCoachMapLoadError;

  /// No description provided for @exploreCoachMapCoachesInArea.
  ///
  /// In en, this message translates to:
  /// **'Coaches in this area'**
  String get exploreCoachMapCoachesInArea;

  /// No description provided for @exploreCoachMapViewAndBook.
  ///
  /// In en, this message translates to:
  /// **'View & Book'**
  String get exploreCoachMapViewAndBook;

  /// No description provided for @exploreCoachMapRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get exploreCoachMapRetry;

  /// No description provided for @exploreCoachMapYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get exploreCoachMapYourLocation;

  /// No description provided for @exploreCoachMapCoachesInAreaSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coach in this area} other{{count} coaches in this area}}'**
  String exploreCoachMapCoachesInAreaSemantics(int count);

  /// No description provided for @exploreCoachMapOsmCopyright.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get exploreCoachMapOsmCopyright;

  /// No description provided for @exploreCoachMapTilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map tiles unavailable. Check your connection.'**
  String get exploreCoachMapTilesUnavailable;

  /// No description provided for @exploreCoachMapNoCoachesMatch.
  ///
  /// In en, this message translates to:
  /// **'No coaches with a saved location match your filters.'**
  String get exploreCoachMapNoCoachesMatch;

  /// No description provided for @exploreCoachMapApproximateLocations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coach · Approximate location} other{{count} coaches · Approximate locations}}'**
  String exploreCoachMapApproximateLocations(int count);

  /// No description provided for @exploreCoachMapSetYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get exploreCoachMapSetYourLocation;

  /// No description provided for @exploreCoachMapNearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get exploreCoachMapNearMe;

  /// No description provided for @exploreCoachMapShowAllCoaches.
  ///
  /// In en, this message translates to:
  /// **'Show all coaches'**
  String get exploreCoachMapShowAllCoaches;

  /// No description provided for @exploreCoachMapRefreshMap.
  ///
  /// In en, this message translates to:
  /// **'Refresh map'**
  String get exploreCoachMapRefreshMap;

  /// No description provided for @exploreCoachMapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get exploreCoachMapZoomOut;

  /// No description provided for @exploreCoachMapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get exploreCoachMapZoomIn;

  /// No description provided for @localChatMediaDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from this phone?'**
  String get localChatMediaDeleteTitle;

  /// No description provided for @localChatMediaDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The message stays in your history. Once the server copy is removed, this file cannot be downloaded again.'**
  String get localChatMediaDeleteBody;

  /// No description provided for @localChatMediaCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get localChatMediaCancel;

  /// No description provided for @localChatMediaDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get localChatMediaDeleteFile;

  /// No description provided for @localChatMediaMissingError.
  ///
  /// In en, this message translates to:
  /// **'This file was stored on the original device. Deleting the app removes local photos and voice notes. Ask the sender to resend it.'**
  String get localChatMediaMissingError;

  /// No description provided for @localChatMediaNotOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not on this device'**
  String get localChatMediaNotOnDevice;

  /// No description provided for @localChatMediaSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get localChatMediaSending;

  /// No description provided for @localChatMediaRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get localChatMediaRetryDownload;

  /// No description provided for @localChatMediaDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get localChatMediaDownloading;

  /// No description provided for @localChatMediaLoadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Loading photo…'**
  String get localChatMediaLoadingPhoto;

  /// No description provided for @managerHeaderRoleBadge.
  ///
  /// In en, this message translates to:
  /// **'MANAGER'**
  String get managerHeaderRoleBadge;

  /// No description provided for @managerNavbarDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get managerNavbarDashboard;

  /// No description provided for @managerNavbarClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get managerNavbarClients;

  /// No description provided for @managerNavbarCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get managerNavbarCoaches;

  /// No description provided for @managerNavbarReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get managerNavbarReservations;

  /// No description provided for @managerNavbarMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get managerNavbarMore;

  /// No description provided for @voiceNoteTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get voiceNoteTapToRetry;

  /// No description provided for @voiceNoteLoadingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Loading voice message'**
  String get voiceNoteLoadingTooltip;

  /// No description provided for @voiceNoteRetryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Retry voice message'**
  String get voiceNoteRetryTooltip;

  /// No description provided for @voiceNotePauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause voice message'**
  String get voiceNotePauseTooltip;

  /// No description provided for @voiceNotePlayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get voiceNotePlayTooltip;

  /// No description provided for @voiceNoteSeekBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice message seek bar'**
  String get voiceNoteSeekBarLabel;

  /// No description provided for @voiceNoteSeekBarValue.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent'**
  String voiceNoteSeekBarValue(int percent);

  /// No description provided for @voiceNoteLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get voiceNoteLoading;

  /// No description provided for @voiceNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNoteLabel;

  /// No description provided for @blockedUsersListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users'**
  String get blockedUsersListLoadFailed;

  /// No description provided for @blockedUsersListNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String blockedUsersListNetworkError(String error);

  /// No description provided for @blockedUsersListUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String blockedUsersListUnblockTitle(String name);

  /// No description provided for @blockedUsersListUnblockMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be able to see your profile and send you messages again.'**
  String get blockedUsersListUnblockMessage;

  /// No description provided for @blockedUsersListCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get blockedUsersListCancel;

  /// No description provided for @blockedUsersListUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUsersListUnblock;

  /// No description provided for @blockedUsersListUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been unblocked'**
  String blockedUsersListUnblocked(String name);

  /// No description provided for @blockedUsersListUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user'**
  String get blockedUsersListUnblockFailed;

  /// No description provided for @blockedUsersListTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsersListTitle;

  /// No description provided for @blockedUsersListRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get blockedUsersListRetry;

  /// No description provided for @blockedUsersListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get blockedUsersListEmptyTitle;

  /// No description provided for @blockedUsersListEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When you block someone, they will appear here.'**
  String get blockedUsersListEmptyMessage;

  /// No description provided for @blockedUsersListBlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedUsersListBlockedLabel;

  /// No description provided for @clientNotificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get clientNotificationsLoadFailed;

  /// No description provided for @clientNotificationsMarkReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark notifications read.'**
  String get clientNotificationsMarkReadFailed;

  /// No description provided for @clientNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientNotificationsTitle;

  /// No description provided for @clientNotificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get clientNotificationsMarkAllRead;

  /// No description provided for @clientNotificationsErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'{error} · Retry'**
  String clientNotificationsErrorRetry(String error);

  /// No description provided for @clientNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get clientNotificationsEmpty;

  /// No description provided for @coachInvitationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String coachInvitationsMinutesAgo(int minutes);

  /// No description provided for @coachInvitationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String coachInvitationsHoursAgo(int hours);

  /// No description provided for @coachInvitationsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get coachInvitationsYesterday;

  /// No description provided for @coachInvitationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String coachInvitationsDaysAgo(int days);

  /// No description provided for @coachInvitationsGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again.'**
  String get coachInvitationsGenericError;

  /// No description provided for @coachInvitationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invitations clicked yet'**
  String get coachInvitationsEmpty;

  /// No description provided for @coachInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get coachInvitationsTitle;

  /// No description provided for @coachInvitationsPointsHeader.
  ///
  /// In en, this message translates to:
  /// **'Client Invitation Points'**
  String get coachInvitationsPointsHeader;

  /// No description provided for @coachInvitationsPointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String coachInvitationsPointsValue(int points);

  /// No description provided for @coachInvitationsAcceptedClients.
  ///
  /// In en, this message translates to:
  /// **'accepted clients'**
  String get coachInvitationsAcceptedClients;

  /// No description provided for @coachInvitationsPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String coachInvitationsPointsEarned(int points);

  /// No description provided for @coachInvitationsDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get coachInvitationsDeclined;

  /// No description provided for @coachInvitationsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get coachInvitationsDecline;

  /// No description provided for @coachInvitationsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get coachInvitationsAccept;

  /// No description provided for @welcomePage1Tag.
  ///
  /// In en, this message translates to:
  /// **'COACHING'**
  String get welcomePage1Tag;

  /// No description provided for @welcomePage1Title.
  ///
  /// In en, this message translates to:
  /// **'Your Coach,'**
  String get welcomePage1Title;

  /// No description provided for @welcomePage1Accent.
  ///
  /// In en, this message translates to:
  /// **'On Demand.'**
  String get welcomePage1Accent;

  /// No description provided for @welcomePage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find certified coaches near you and book a session in seconds.'**
  String get welcomePage1Subtitle;

  /// No description provided for @welcomePage2Tag.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get welcomePage2Tag;

  /// No description provided for @welcomePage2Title.
  ///
  /// In en, this message translates to:
  /// **'Track Every'**
  String get welcomePage2Title;

  /// No description provided for @welcomePage2Accent.
  ///
  /// In en, this message translates to:
  /// **'Milestone.'**
  String get welcomePage2Accent;

  /// No description provided for @welcomePage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor your sessions and measure your growth day after day.'**
  String get welcomePage2Subtitle;

  /// No description provided for @welcomePage3Tag.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY'**
  String get welcomePage3Tag;

  /// No description provided for @welcomePage3Title.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get welcomePage3Title;

  /// No description provided for @welcomePage3Accent.
  ///
  /// In en, this message translates to:
  /// **'SIRVYA.'**
  String get welcomePage3Accent;

  /// No description provided for @welcomePage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with top coaches and transform your body for good.'**
  String get welcomePage3Subtitle;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get welcomeLogIn;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE AN ACCOUNT'**
  String get welcomeCreateAccount;

  /// No description provided for @coachInviteClientsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load invitations. Please try again.'**
  String get coachInviteClientsLoadError;

  /// No description provided for @coachInviteClientsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get coachInviteClientsCopied;

  /// No description provided for @coachInviteClientsShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Join me on SIRVYA'**
  String get coachInviteClientsShareTitle;

  /// No description provided for @coachInviteClientsShareText.
  ///
  /// In en, this message translates to:
  /// **'You are invited to join me on SIRVYA. Find your coach or grow your coaching business.\n\n{link}\n\nInvitation code: {code}'**
  String coachInviteClientsShareText(String link, String code);

  /// No description provided for @coachInviteClientsShareFallback.
  ///
  /// In en, this message translates to:
  /// **'Join me on SIRVYA: {link}\nInvitation code: {code}'**
  String coachInviteClientsShareFallback(String link, String code);

  /// No description provided for @coachInviteClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite & grow'**
  String get coachInviteClientsTitle;

  /// No description provided for @coachInviteClientsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachInviteClientsRetry;

  /// No description provided for @coachInviteClientsHeading.
  ///
  /// In en, this message translates to:
  /// **'Grow your SIRVYA network'**
  String get coachInviteClientsHeading;

  /// No description provided for @coachInviteClientsIntro.
  ///
  /// In en, this message translates to:
  /// **'One code for clients and coaches. Track the people who successfully sign up through your invitation.'**
  String get coachInviteClientsIntro;

  /// No description provided for @coachInviteClientsYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your invitation code'**
  String get coachInviteClientsYourCode;

  /// No description provided for @coachInviteClientsCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get coachInviteClientsCopyCode;

  /// No description provided for @coachInviteClientsCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get coachInviteClientsCopyLink;

  /// No description provided for @coachInviteClientsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get coachInviteClientsShare;

  /// No description provided for @coachInviteClientsClientsJoined.
  ///
  /// In en, this message translates to:
  /// **'Clients joined'**
  String get coachInviteClientsClientsJoined;

  /// No description provided for @coachInviteClientsCoachesJoined.
  ///
  /// In en, this message translates to:
  /// **'Coaches joined'**
  String get coachInviteClientsCoachesJoined;

  /// No description provided for @coachInviteClientsPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} point} other{{count} points}}'**
  String coachInviteClientsPoints(int count);

  /// No description provided for @coachInviteClientsRewardBalance.
  ///
  /// In en, this message translates to:
  /// **'Your total reward balance'**
  String get coachInviteClientsRewardBalance;

  /// No description provided for @coachInviteClientsHowRewards.
  ///
  /// In en, this message translates to:
  /// **'How rewards work'**
  String get coachInviteClientsHowRewards;

  /// No description provided for @coachInviteClientsRewardRules.
  ///
  /// In en, this message translates to:
  /// **'Coach: 40 points after a new account is created.\nClient: 20 points when you accept their connection in Clients. Sharing or opening a link does not earn points.'**
  String get coachInviteClientsRewardRules;

  /// No description provided for @coachInviteClientsPeopleInvited.
  ///
  /// In en, this message translates to:
  /// **'People you invited'**
  String get coachInviteClientsPeopleInvited;

  /// No description provided for @coachInviteClientsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get coachInviteClientsFilterAll;

  /// No description provided for @coachInviteClientsFilterClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get coachInviteClientsFilterClients;

  /// No description provided for @coachInviteClientsFilterCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get coachInviteClientsFilterCoaches;

  /// No description provided for @coachInviteClientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No signups in this category yet. Share your link to get started.'**
  String get coachInviteClientsEmpty;

  /// No description provided for @coachInviteClientsRoleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachInviteClientsRoleCoach;

  /// No description provided for @coachInviteClientsRoleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get coachInviteClientsRoleClient;

  /// No description provided for @coachInviteClientsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Connection pending'**
  String get coachInviteClientsStatusPending;

  /// No description provided for @coachInviteClientsStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get coachInviteClientsStatusConnected;

  /// No description provided for @coachInviteClientsStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Connection declined'**
  String get coachInviteClientsStatusDeclined;

  /// No description provided for @coachInviteClientsStatusRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get coachInviteClientsStatusRegistered;

  /// No description provided for @coachInviteClientsRoleStatus.
  ///
  /// In en, this message translates to:
  /// **'{role} • {status}'**
  String coachInviteClientsRoleStatus(String role, String status);

  /// No description provided for @coachInviteClientsPointsAwarded.
  ///
  /// In en, this message translates to:
  /// **'+{count} {count, plural, =1{pt} other{pts}}'**
  String coachInviteClientsPointsAwarded(int count);

  /// No description provided for @coachClientsInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted: +20 points. The client is now available in Chats.'**
  String get coachClientsInviteAccepted;

  /// No description provided for @coachClientsInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get coachClientsInviteDeclined;

  /// No description provided for @coachClientsInviteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update invitation.'**
  String get coachClientsInviteUpdateFailed;

  /// No description provided for @coachClientsYourClients.
  ///
  /// In en, this message translates to:
  /// **'YOUR CLIENTS'**
  String get coachClientsYourClients;

  /// No description provided for @coachClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Clients'**
  String get coachClientsTitle;

  /// No description provided for @coachClientsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get coachClientsLoading;

  /// No description provided for @coachClientsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings and invitations bring your clients here'**
  String get coachClientsEmptySubtitle;

  /// No description provided for @coachClientsCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 client • Sessions and conversations} other{{count} clients • Sessions and conversations}}'**
  String coachClientsCountSubtitle(int count);

  /// No description provided for @coachClientsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get coachClientsInvite;

  /// No description provided for @coachClientsStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get coachClientsStatTotal;

  /// No description provided for @coachClientsStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get coachClientsStatPending;

  /// No description provided for @coachClientsStatUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get coachClientsStatUpcoming;

  /// No description provided for @coachClientsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get coachClientsFilterAll;

  /// No description provided for @coachClientsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get coachClientsSearchHint;

  /// No description provided for @coachClientsSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get coachClientsSort;

  /// No description provided for @coachClientsSortAz.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get coachClientsSortAz;

  /// No description provided for @coachClientsSortZa.
  ///
  /// In en, this message translates to:
  /// **'Name Z–A'**
  String get coachClientsSortZa;

  /// No description provided for @coachClientsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest connected'**
  String get coachClientsSortNewest;

  /// No description provided for @coachClientsInvitations.
  ///
  /// In en, this message translates to:
  /// **'CLIENT INVITATIONS'**
  String get coachClientsInvitations;

  /// No description provided for @coachClientsPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String coachClientsPendingCount(int count);

  /// No description provided for @coachClientsClientFallback.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get coachClientsClientFallback;

  /// No description provided for @coachClientsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get coachClientsStatusPending;

  /// No description provided for @coachClientsStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted · +{points} pts'**
  String coachClientsStatusAccepted(String points);

  /// No description provided for @coachClientsStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get coachClientsStatusDeclined;

  /// No description provided for @coachClientsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get coachClientsDecline;

  /// No description provided for @coachClientsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get coachClientsAccept;

  /// No description provided for @coachClientsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get coachClientsJustNow;

  /// No description provided for @coachClientsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String coachClientsMinutesAgo(int count);

  /// No description provided for @coachClientsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String coachClientsHoursAgo(int count);

  /// No description provided for @coachClientsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String coachClientsDaysAgo(int count);

  /// No description provided for @coachClientsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your coaching clients will appear here'**
  String get coachClientsEmptyTitle;

  /// No description provided for @coachClientsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Clients appear when they book with you or when you accept their invitation.'**
  String get coachClientsEmptyBody;

  /// No description provided for @coachClientsUpcomingSession.
  ///
  /// In en, this message translates to:
  /// **'Upcoming session'**
  String get coachClientsUpcomingSession;

  /// No description provided for @coachClientsNextSession.
  ///
  /// In en, this message translates to:
  /// **'Next: {date} at {time}'**
  String coachClientsNextSession(String date, String time);

  /// No description provided for @coachClientsSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'{sessions, plural, =1{1 session} other{{sessions} sessions}} • {upcoming} upcoming • {pending} pending'**
  String coachClientsSessionSummary(int sessions, int upcoming, int pending);

  /// No description provided for @coachClientsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load clients'**
  String get coachClientsLoadError;

  /// No description provided for @coachClientsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachClientsRetry;

  /// No description provided for @coachClientsNoMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No clients match your search.'**
  String get coachClientsNoMatchSearch;

  /// No description provided for @coachClientsNoMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No clients match this filter.'**
  String get coachClientsNoMatchFilter;

  /// No description provided for @clientChangeEmailInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get clientChangeEmailInvalidEmail;

  /// No description provided for @clientChangeEmailInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code.'**
  String get clientChangeEmailInvalidCode;

  /// No description provided for @clientChangeEmailVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get clientChangeEmailVerifyFailed;

  /// No description provided for @clientChangeEmailCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent.'**
  String get clientChangeEmailCodeSent;

  /// No description provided for @clientChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get clientChangeEmailTitle;

  /// No description provided for @clientChangeEmailStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String clientChangeEmailStepOf(int step, int total);

  /// No description provided for @clientChangeEmailHeadingNew.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address'**
  String get clientChangeEmailHeadingNew;

  /// No description provided for @clientChangeEmailHeadingVerifyCurrent.
  ///
  /// In en, this message translates to:
  /// **'Verify your current email'**
  String get clientChangeEmailHeadingVerifyCurrent;

  /// No description provided for @clientChangeEmailHeadingVerifyNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new email'**
  String get clientChangeEmailHeadingVerifyNew;

  /// No description provided for @clientChangeEmailIntroStart.
  ///
  /// In en, this message translates to:
  /// **'We will send a verification code to your current email ({email}) first.'**
  String clientChangeEmailIntroStart(String email);

  /// No description provided for @clientChangeEmailIntroCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}.'**
  String clientChangeEmailIntroCode(String email);

  /// No description provided for @clientChangeEmailNewEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get clientChangeEmailNewEmailLabel;

  /// No description provided for @clientChangeEmailCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit verification code'**
  String get clientChangeEmailCodeLabel;

  /// No description provided for @clientChangeEmailPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get clientChangeEmailPleaseWait;

  /// No description provided for @clientChangeEmailSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get clientChangeEmailSendCodeButton;

  /// No description provided for @clientChangeEmailVerifySendButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & send to new email'**
  String get clientChangeEmailVerifySendButton;

  /// No description provided for @clientChangeEmailConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm email change'**
  String get clientChangeEmailConfirmButton;

  /// No description provided for @clientChangeEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get clientChangeEmailResend;

  /// No description provided for @clientChangeEmailStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get clientChangeEmailStartAgain;

  /// No description provided for @clientConversationListUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get clientConversationListUnknown;

  /// No description provided for @clientConversationListError.
  ///
  /// In en, this message translates to:
  /// **'Error ({code})'**
  String clientConversationListError(int code);

  /// No description provided for @clientConversationListServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach server. Check your connection.'**
  String get clientConversationListServerUnreachable;

  /// No description provided for @clientConversationListTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get clientConversationListTitle;

  /// No description provided for @clientConversationListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with your coaches'**
  String get clientConversationListSubtitle;

  /// No description provided for @clientConversationListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientConversationListFilterAll;

  /// No description provided for @clientConversationListFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get clientConversationListFilterUnread;

  /// No description provided for @clientConversationListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get clientConversationListSearchHint;

  /// No description provided for @clientConversationListRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get clientConversationListRetry;

  /// No description provided for @clientConversationListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get clientConversationListEmptyTitle;

  /// No description provided for @clientConversationListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your messages with coaches will appear here.'**
  String get clientConversationListEmptySubtitle;

  /// No description provided for @clientConversationListNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String clientConversationListNoResults(String query);

  /// No description provided for @clientConversationListFooter.
  ///
  /// In en, this message translates to:
  /// **'Your personal messages are end-to-end private'**
  String get clientConversationListFooter;

  /// No description provided for @clientConversationListTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open conversation'**
  String get clientConversationListTapToOpen;

  /// No description provided for @clientConversationListYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get clientConversationListYesterday;

  /// No description provided for @clientQrScannerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Align the coach\'s QR code within the frame'**
  String get clientQrScannerPrompt;

  /// No description provided for @coachChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get coachChangeEmailTitle;

  /// No description provided for @coachChangeEmailLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to load email. Tap to retry.'**
  String get coachChangeEmailLoadRetry;

  /// No description provided for @coachConversationsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get coachConversationsYesterday;

  /// No description provided for @coachConversationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get coachConversationsEmpty;

  /// No description provided for @coachConversationsFooter.
  ///
  /// In en, this message translates to:
  /// **'Your client messages are private and secure'**
  String get coachConversationsFooter;

  /// No description provided for @coachConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get coachConversationsTitle;

  /// No description provided for @coachConversationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations with your clients'**
  String get coachConversationsSubtitle;

  /// No description provided for @coachConversationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get coachConversationsFilterAll;

  /// No description provided for @coachConversationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get coachConversationsFilterUnread;

  /// No description provided for @coachConversationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get coachConversationsSearchHint;

  /// No description provided for @coachConversationsTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open conversation'**
  String get coachConversationsTapToOpen;

  /// No description provided for @coachVisibilityUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update visibility settings.'**
  String get coachVisibilityUpdateFailed;

  /// No description provided for @coachVisibilityNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get coachVisibilityNetworkError;

  /// No description provided for @coachVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get coachVisibilityTitle;

  /// No description provided for @coachVisibilitySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coachVisibilitySave;

  /// No description provided for @coachVisibilityProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Search & Discovery'**
  String get coachVisibilityProfileSection;

  /// No description provided for @coachVisibilityProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Control whether clients can find your profile in search results and recommendations.'**
  String get coachVisibilityProfileDesc;

  /// No description provided for @coachVisibilityPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get coachVisibilityPublicProfile;

  /// No description provided for @coachVisibilityPublicProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow clients to discover and view your profile'**
  String get coachVisibilityPublicProfileDesc;

  /// No description provided for @coachVisibilityMessagingSection.
  ///
  /// In en, this message translates to:
  /// **'Messaging Preferences'**
  String get coachVisibilityMessagingSection;

  /// No description provided for @coachVisibilityMessagingDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose who can start a conversation with you directly.'**
  String get coachVisibilityMessagingDesc;

  /// No description provided for @coachVisibilityDirectMessaging.
  ///
  /// In en, this message translates to:
  /// **'Direct Messaging'**
  String get coachVisibilityDirectMessaging;

  /// No description provided for @coachVisibilityDirectMessagingDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow clients to message you before booking'**
  String get coachVisibilityDirectMessagingDesc;

  /// No description provided for @coachChangePhoneErrorMissing.
  ///
  /// In en, this message translates to:
  /// **'Please enter both country code and phone number.'**
  String get coachChangePhoneErrorMissing;

  /// No description provided for @coachChangePhoneErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update phone number.'**
  String get coachChangePhoneErrorFailed;

  /// No description provided for @coachChangePhoneErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please check your connection.'**
  String get coachChangePhoneErrorServer;

  /// No description provided for @coachChangePhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get coachChangePhoneTitle;

  /// No description provided for @coachChangePhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the phone number linked to your account.'**
  String get coachChangePhoneSubtitle;

  /// No description provided for @coachChangePhoneSave.
  ///
  /// In en, this message translates to:
  /// **'Save Phone Number'**
  String get coachChangePhoneSave;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'YOUR FITNESS JOURNEY'**
  String get splashTagline;

  /// No description provided for @mainLayoutNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get mainLayoutNavHome;

  /// No description provided for @mainLayoutNavExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get mainLayoutNavExplore;

  /// No description provided for @mainLayoutNavSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get mainLayoutNavSessions;

  /// No description provided for @mainLayoutNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get mainLayoutNavProfile;

  /// No description provided for @mainLayoutPlaceholderItem.
  ///
  /// In en, this message translates to:
  /// **'{title} — Item #{index}'**
  String mainLayoutPlaceholderItem(String title, int index);

  /// No description provided for @mainLayoutPlaceholderHint.
  ///
  /// In en, this message translates to:
  /// **'Screen under construction'**
  String get mainLayoutPlaceholderHint;

  /// No description provided for @userLocationSettingsDetectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please detect or select a city and coordinates first.'**
  String get userLocationSettingsDetectPrompt;

  /// No description provided for @userLocationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get userLocationSettingsTitle;

  /// No description provided for @userLocationSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your saved location.'**
  String get userLocationSettingsLoadError;

  /// No description provided for @userLocationSettingsBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Location Permission'**
  String get userLocationSettingsBackgroundTitle;

  /// No description provided for @userLocationSettingsBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage location access in system settings'**
  String get userLocationSettingsBackgroundSubtitle;

  /// No description provided for @userLocationSettingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get userLocationSettingsSaving;

  /// No description provided for @userLocationSettingsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get userLocationSettingsContinue;

  /// No description provided for @userLocationSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get userLocationSettingsSave;

  /// No description provided for @coachChangePasswordAllRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required.'**
  String get coachChangePasswordAllRequired;

  /// No description provided for @coachChangePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get coachChangePasswordMismatch;

  /// No description provided for @coachChangePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get coachChangePasswordTooShort;

  /// No description provided for @coachChangePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password.'**
  String get coachChangePasswordFailed;

  /// No description provided for @coachChangePasswordServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please check your connection.'**
  String get coachChangePasswordServerError;

  /// No description provided for @coachChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password & Security'**
  String get coachChangePasswordTitle;

  /// No description provided for @coachChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your account password.'**
  String get coachChangePasswordSubtitle;

  /// No description provided for @coachChangePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get coachChangePasswordCurrent;

  /// No description provided for @coachChangePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get coachChangePasswordNew;

  /// No description provided for @coachChangePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get coachChangePasswordConfirm;

  /// No description provided for @coachChangePasswordUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get coachChangePasswordUpdate;

  /// No description provided for @coachNotificationsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications'**
  String get coachNotificationsUpdateFailed;

  /// No description provided for @coachNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get coachNotificationsTitle;

  /// No description provided for @coachNotificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get coachNotificationsMarkAllRead;

  /// No description provided for @coachNotificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications'**
  String get coachNotificationsLoadError;

  /// No description provided for @coachNotificationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachNotificationsRetry;

  /// No description provided for @coachNotificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get coachNotificationsEmptyTitle;

  /// No description provided for @coachNotificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Messages, reservations and session reminders will appear here.'**
  String get coachNotificationsEmptyBody;

  /// No description provided for @accountSecurityPasswordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your password. Please try again.'**
  String get accountSecurityPasswordUpdateFailed;

  /// No description provided for @apiServiceNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get apiServiceNetworkError;

  /// No description provided for @connectionRecoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Your connection may be weak or interrupted, or the server may be temporarily unavailable. Check your Wi-Fi or mobile data, then try again.'**
  String get connectionRecoveryMessage;

  /// No description provided for @conversationActivityTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get conversationActivityTyping;

  /// No description provided for @conversationActivityRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording a voice message…'**
  String get conversationActivityRecording;

  /// No description provided for @socialAuthNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in is not available yet. Please use email and password.'**
  String socialAuthNotAvailable(String provider);

  /// No description provided for @socialAuthAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in using your original method.'**
  String get socialAuthAccountExists;

  /// No description provided for @socialAuthNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get socialAuthNetwork;

  /// No description provided for @socialAuthNotVerified.
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in could not be verified. Please try again.'**
  String socialAuthNotVerified(String provider);

  /// No description provided for @socialAuthUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is unavailable. Please contact support.'**
  String get socialAuthUserDisabled;

  /// No description provided for @socialAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in failed. Please try again.'**
  String socialAuthFailed(String provider);
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
