// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSystem => 'System default';

  @override
  String get loginErrorEmptyEmail => 'Enter your email address.';

  @override
  String get loginErrorEmptyPassword => 'Enter your password.';

  @override
  String get loginErrorInvalidToken =>
      'Invalid token received from the server.';

  @override
  String get loginErrorMissingUserData => 'User data is missing.';

  @override
  String get loginErrorIncompleteUserInfo => 'Incomplete user information.';

  @override
  String get loginErrorSocialAccount =>
      'This account uses Google or Apple sign-in. Continue with your original sign-in method below.';

  @override
  String loginErrorCode(int code) {
    return 'Login error ($code)';
  }

  @override
  String get loginErrorCheckConnection => 'Check your connection.';

  @override
  String loginErrorUnrecognizedRole(String role) {
    return 'Unrecognized role: $role';
  }

  @override
  String get loginErrorGoogleFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get loginErrorAppleFailed => 'Apple sign-in failed. Please try again.';

  @override
  String get loginErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get loginErrorSuspended => 'This account is suspended.';

  @override
  String get loginErrorFillAllFields => 'Please fill in all fields.';

  @override
  String get loginErrorAccountNotFound => 'No account found with this email.';

  @override
  String get loginBadgeSignIn => 'SIGN IN';

  @override
  String get loginHeadingTitle => 'Welcome back';

  @override
  String get loginHeadingSubtitle =>
      'Log in to access your space and manage your activities.';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginEmailHint => 'your@email.com';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginCtaLogIn => 'LOG IN';

  @override
  String get loginOr => 'OR';

  @override
  String get loginContinueGoogle => 'CONTINUE WITH GOOGLE';

  @override
  String get loginContinueApple => 'CONTINUE WITH APPLE';

  @override
  String get loginNotRegisteredYet => 'Not registered yet?';

  @override
  String get loginCreateAccount => 'CREATE AN ACCOUNT';

  @override
  String get loginBackTo => 'Back to ';

  @override
  String get loginBackToHome => 'home';

  @override
  String get loginSetPasswordErrorMinLength =>
      'Password must be at least 6 characters.';

  @override
  String get loginSetPasswordErrorMismatch => 'Passwords do not match.';

  @override
  String get loginSetPasswordErrorFailed => 'Failed to set password.';

  @override
  String get loginSetPasswordErrorConnection => 'Connection error.';

  @override
  String get loginSetPasswordSuccessTitle => 'Password set!';

  @override
  String get loginSetPasswordSuccessMessage =>
      'You can now log in with your email and password.';

  @override
  String get loginSetPasswordDone => 'Done';

  @override
  String get loginSetPasswordTitle => 'Set a Password';

  @override
  String get loginSetPasswordSubtitle =>
      'Optionally set a password so you can also log in with your email later.';

  @override
  String get loginSetPasswordNewLabel => 'New Password';

  @override
  String get loginSetPasswordConfirmLabel => 'Confirm Password';

  @override
  String get loginSetPasswordSkip => 'Skip';

  @override
  String get loginSetPasswordSubmit => 'Set Password';

  @override
  String get registerInterestsDialogTitle => 'Your interests';

  @override
  String get registerCancel => 'Cancel';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerErrorSelectRole => 'Select your role to continue';

  @override
  String get registerErrorAcceptTerms =>
      'You must accept the Sirvya Legal & Compliance Framework to create an account.';

  @override
  String get registerErrorFirstNameRequired => 'First name required';

  @override
  String get registerErrorLastNameRequired => 'Last name required';

  @override
  String get registerErrorInvalidEmail => 'Invalid email';

  @override
  String get registerErrorHeightRequired => 'Height required';

  @override
  String get registerErrorInvalidHeight => 'Invalid height';

  @override
  String get registerErrorInvalidWeight => 'Enter a valid weight in kg';

  @override
  String get registerErrorChooseInterest =>
      'Choose at least one interest (up to 5)';

  @override
  String get registerErrorLocationRequired =>
      'Press Use my current location to fill your location';

  @override
  String get registerErrorChooseSpecialty =>
      'Please select at least one specialty (up to 5)';

  @override
  String get registerErrorPasswordTooShort =>
      'Password too short (min 6 chars)';

  @override
  String get registerErrorPasswordsMismatch => 'Passwords do not match';

  @override
  String get registerErrorSelectGender => 'Select your gender to continue';

  @override
  String get registerErrorOtpLength =>
      'Enter 6-digit verification code sent to your email';

  @override
  String get registerErrorSendOtpFailed => 'Failed to send verification code';

  @override
  String get registerErrorServerUnreachable => 'Unable to reach the server';

  @override
  String get registerErrorInvalidOtp => 'Invalid verification code';

  @override
  String get registerErrorVerifyOtpNetwork => 'Network error verifying code';

  @override
  String get registerErrorFailed => 'Registration failed';

  @override
  String get registerErrorSelectRoleGoogle =>
      'Select your role before continuing with Google.';

  @override
  String get registerErrorSelectRoleApple =>
      'Select your role before continuing with Apple.';

  @override
  String get registerErrorAgreeTermsSocial =>
      'Please agree to the Terms of Service to sign up.';

  @override
  String registerErrorUnrecognizedRole(String role) {
    return 'Unrecognized role: $role';
  }

  @override
  String get registerErrorGoogleFailed =>
      'Google sign-up failed. Please try again.';

  @override
  String get registerErrorAppleFailed =>
      'Apple sign-up failed. Please try again.';

  @override
  String get registerSuccessTitle => 'Account created!';

  @override
  String registerSuccessPendingApproval(String firstName) {
    return 'Welcome $firstName. Your account is pending approval.';
  }

  @override
  String get registerLogInButton => 'Log in';

  @override
  String registerSuccessWelcomePrefix(String firstName) {
    return 'Welcome $firstName. ';
  }

  @override
  String get registerSuccessCoachBadgeNote =>
      'You can now log in. Your Sirvya verified badge is pending verification, which can take up to 48 hours.';

  @override
  String get registerSuccessAdvisorPendingNote =>
      'Your account is pending approval.';

  @override
  String get registerSuccessClientNote => 'You can now log in.';

  @override
  String get registerStep1Label => 'STEP 1 / 5';

  @override
  String get registerStep2Label => 'STEP 2 / 5';

  @override
  String get registerStep3Label => 'STEP 3 / 5';

  @override
  String get registerStep4Label => 'STEP 4 / 5';

  @override
  String get registerStep5Label => 'STEP 5 / 5';

  @override
  String get registerStep1Title => 'What is\nyour role?';

  @override
  String get registerStep2Title => 'Who are you?';

  @override
  String get registerStep3Title => 'Secure\nyour account';

  @override
  String get registerStep4Title => 'Terms &\nPreferences';

  @override
  String get registerStep5Title => 'Verify your\nemail OTP';

  @override
  String get registerStep1Sub => 'Choose how you\'ll use SIRVYA.';

  @override
  String get registerStep2Sub => 'Tell us what to call you.';

  @override
  String get registerStep3Sub => 'Create a strong password.';

  @override
  String get registerStep4Sub => 'Personalize & agree to legal terms.';

  @override
  String get registerStep5Sub =>
      'Enter the 6-digit code sent to your email address.';

  @override
  String get registerOtpLabel => '6-digit OTP Code';

  @override
  String get registerOtpHint => '123456';

  @override
  String registerOtpSentTo(String email) {
    return 'Code sent to $email via noreply@devunivers.com';
  }

  @override
  String get registerOtpResend => 'Resend Code';

  @override
  String get registerRoleClientLabel => 'Client';

  @override
  String get registerRoleClientDesc => 'Find a coach and book sessions.';

  @override
  String get registerRoleCoachLabel => 'Coach';

  @override
  String get registerRoleCoachDesc =>
      'Manage your clients and grow your business.';

  @override
  String get registerInviterCodeLabel => 'Inviter code (optional)';

  @override
  String get registerInviterCodeHint => 'Enter your coach’s invitation code';

  @override
  String get registerOr => 'OR';

  @override
  String get registerSelectRoleFirst => 'SELECT A ROLE FIRST';

  @override
  String get registerContinueGoogle => 'CONTINUE WITH GOOGLE';

  @override
  String get registerContinueApple => 'CONTINUE WITH APPLE';

  @override
  String get registerFirstNameLabel => 'First name';

  @override
  String get registerFirstNameHint => 'Anas';

  @override
  String get registerLastNameLabel => 'Last name';

  @override
  String get registerLastNameHint => 'Benali';

  @override
  String get registerEmailLabel => 'Email address';

  @override
  String get registerEmailHint => 'you@email.ma';

  @override
  String get registerHeightLabel => 'Height (cm)';

  @override
  String get registerHeightHint => '175';

  @override
  String get registerWeightLabel => 'Weight (kg)';

  @override
  String get registerWeightHint => '70';

  @override
  String get registerNutritionGoalTitle => 'Your nutrition goal (optional)';

  @override
  String get registerNutritionGoalBalanced => 'Build balanced habits';

  @override
  String get registerNutritionGoalLose => 'Lose weight gradually';

  @override
  String get registerNutritionGoalGain => 'Gain weight gradually';

  @override
  String get registerNutritionGoalMaintain => 'Maintain my weight';

  @override
  String get registerNutritionGoalPersonal => 'Personal goal';

  @override
  String get registerNutritionGoalSkipped =>
      'Skipped · You can set this up later in your profile';

  @override
  String get registerNutritionGoalOptional =>
      'Optional · Tap to configure or skip for now';

  @override
  String get registerNutritionGoalClearTooltip => 'Clear goal';

  @override
  String get registerNutritionGoalSkip => 'Skip';

  @override
  String registerInterestsHeader(int count) {
    return 'Your interests ($count/5)';
  }

  @override
  String registerSpecialtiesHeader(int count) {
    return 'Coaching specialties ($count/5)';
  }

  @override
  String get registerInterestsSub =>
      'Choose up to 5 interests to personalize your coach recommendations.';

  @override
  String get registerSpecialtiesSub => 'Choose up to 5 specialties.';

  @override
  String get registerSpecialtyStrength => 'Strength Training';

  @override
  String get registerSpecialtyWeightLoss => 'Weight Loss';

  @override
  String get registerSpecialtyYoga => 'Yoga';

  @override
  String get registerSpecialtyCrossFit => 'CrossFit';

  @override
  String get registerSpecialtyBoxing => 'Boxing';

  @override
  String get registerSpecialtyNutrition => 'Nutrition';

  @override
  String get registerSpecialtyPilates => 'Pilates';

  @override
  String get registerSpecialtyCardio => 'Cardio';

  @override
  String get registerSpecialtyStretching => 'Stretching';

  @override
  String get registerSpecialtyFunctional => 'Functional Training';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordHint => '••••••••';

  @override
  String get registerConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerConfirmPasswordHint => '••••••••';

  @override
  String get registerGenderMale => 'Male';

  @override
  String get registerGenderFemale => 'Female';

  @override
  String get registerGenderOther => 'Other';

  @override
  String get registerInvitationCodeLabel => 'Invitation code (optional)';

  @override
  String get registerInvitationCodeHint => 'e.g. A1B2C3D4E5F6';

  @override
  String get registerInvitationCodeHelper =>
      'Invited by a coach? Enter their code to credit your signup.';

  @override
  String get registerInvitationCodeInvalid => 'This code is not recognized.';

  @override
  String get registerInvitationCodeValid => 'Valid coach code';

  @override
  String get registerTermsAgreePrefix => 'I agree to the ';

  @override
  String get registerTermsAgreeLink =>
      'Sirvya Master Legal & Compliance Framework';

  @override
  String get registerTermsAgreeSuffix =>
      ' including Terms of Service, Privacy Policy & Disclaimers.';

  @override
  String get registerTermsReadButton => 'Read Full Framework';

  @override
  String get registerTermsModalHeader => 'SIRVYA MASTER LEGAL FRAMEWORK';

  @override
  String get registerTermsSecGeneralTitle => 'General Information';

  @override
  String get registerTermsSecGeneralBody =>
      'Effective Date: November 2026\nVersion: 1.0.3\nOperating Entity: DevUnivers (Morocco)\nContact: privacy@devunivers.com | support@devunivers.com\nPlatform: Sirvya Mobile Application & Associated Infrastructure';

  @override
  String get registerTermsSecScopeTitle =>
      'Legal Framework & International Scope';

  @override
  String get registerTermsSecScopeBody =>
      'Sirvya is operated by DevUnivers in Morocco and designed for global accessibility. This comprehensive legal framework governs your use of Sirvya worldwide. It adheres to Moroccan privacy regulations (Law 09-08 / CNDP) and aligns with international data protection benchmarks including the EU General Data Protection Regulation (GDPR) and global consumer protection standards.';

  @override
  String get registerTermsSecDefsTitle => 'Definitions';

  @override
  String get registerTermsSecDefsBody =>
      '• Platform: Refers to the Sirvya application, its associated web infrastructure, AI services, and systems provided by DevUnivers.\n• Company: Refers to DevUnivers, the operating legal entity.\n• User: Any individual creating an account on the Platform to track nutrition, workouts, book services, or interact with Coaches/Gyms.\n• Coach: An independent fitness professional or personal trainer offering services or advice via the Platform.\n• Gym: An independent fitness facility or studio listed on the Platform.';

  @override
  String get registerTermsSecTosTitle => '1. Terms of Service (ToS)';

  @override
  String get registerTermsSecTosBody =>
      '1.1 Acceptance of Terms\nBy accessing, creating an account, or using Sirvya, you agree to be bound by these Terms of Service. If you do not agree to these terms, you must discontinue use and uninstall the app.\n\n1.2 Eligibility & Age Requirements\nUsers must be at least 18 years old (or the legal age of majority in their jurisdiction) to independently register. Minors between 13 and 17 may only use the platform under parental/guardian supervision and verifiable consent. Sirvya is strictly not intended for children under 13.\n\n1.3 Account Security & Integrity\nYou are responsible for safeguarding your credentials. Account sharing, selling, automated scraping, reverse engineering, security tampering, or unauthorized commercial exploitation is strictly prohibited.\n\n1.4 Subscription & Marketplace Terms\nWhile certain core features are currently provided free or in beta, Sirvya reserves the right to introduce optional premium features, subscriptions, or transaction fees with clear prior notice.\n\n1.5 Limitation of Liability\nTo the maximum extent permitted by applicable law, DevUnivers, Sirvya, and their affiliates shall not be liable for indirect, incidental, punitive, or consequential damages resulting from app usage, workout activities, nutritional tracking, or interactions with independent third parties.\n\n1.6 Governing Law & International Users\nThese Terms are governed by and construed in accordance with the laws of the Kingdom of Morocco. If you are an individual consumer residing outside Morocco (such as in the European Union, United Kingdom, United States, or GCC), nothing in these Terms deprives you of the mandatory statutory consumer protections provided by the laws of your country of habitual residence. In case of any concern, we encourage contacting support@devunivers.com for informal amicable resolution.';

  @override
  String get registerTermsSecPrivacyTitle =>
      '2. Privacy Policy & Data Protection';

  @override
  String get registerTermsSecPrivacyBody =>
      '2.1 Data Collection & Purpose\nWe collect personal and health-related fitness data exclusively to provide personalized fitness tracking, coach discovery, and nutrition analytics (name, email, age, height, weight, BMI, meal logs, macros, booking records, and chat communications).\n\n2.2 Health & Biometric Data Consent\nTracking nutrition, calories, body weight, and workout metrics involves health-related data. By using these optional features, you provide your explicit consent for Sirvya to store and process this data to display your diary, calculate calorie targets, and track fitness progress.\n\n2.3 AI Meal Scanning & Microsoft Azure\nOptional meal photo analysis transmits stripped image data via secure TLS encryption to Microsoft Azure AI (GPT-4 mini) solely to estimate foods, portions, and macros. Photos are processed ephemerally in memory and are not retained in Sirvya server storage.\n\n2.4 Location & OpenStreetMap Nominatim\nWhen granted permission, device location is accessed to detect your city and display nearby coaches. Reverse geocoding is powered by OpenStreetMap Nominatim under OSM privacy safeguards. Your precise GPS coordinates are never broadcast to other users.\n\n2.5 International & GDPR User Rights\nRegardless of your country of residence, you have full control over your personal data:\n• Right to Access: Request a copy of your personal data.\n• Right to Rectification: Correct or update any inaccurate information.\n• Right to Erasure: Request total deletion of your account and linked records.\n• Right to Withdraw Consent: Discontinue health/location tracking at any time.\n• In-App Deletion: You can permanently delete your account directly inside the app settings under your profile.\nFor any privacy inquiry, contact privacy@devunivers.com.';

  @override
  String get registerTermsSecHealthTitle =>
      '3. Health, Medical & Allergen Disclaimers';

  @override
  String get registerTermsSecHealthBody =>
      '3.1 NOT A HEALTHCARE PROVIDER\nSIRVYA IS NOT A MEDICAL PLATFORM, MEDICAL DEVICE, OR HEALTHCARE PROVIDER. App content, AI estimates, and Coach services are for informational and lifestyle purposes only and must NEVER replace qualified medical diagnosis or professional healthcare advice.\n\n3.2 CRITICAL ALLERGY WARNING\nNEITHER SIRVYA, ITS AI IMAGE SCANNER, NOR ITS INGREDIENT DATABASES DETECT OR VERIFY ALLERGENS (such as peanuts, tree nuts, gluten, dairy, shellfish, soy, or eggs). NEVER rely on Sirvya or photo scans if you have food allergies, celiac disease, or medical dietary restrictions. Always check manufacturer labels.\n\n3.3 Assumption of Physical Risk\nPhysical exercise entails inherent risks of injury. Consult a licensed physician prior to starting any new training or nutrition regimen. You voluntarily assume all physical risks associated with workouts.\n\n3.4 Emergency Services\nIn the event of a medical emergency, immediately contact your local emergency response services (such as 15/190 in Morocco, 112 in the EU, or 911 in the US).';

  @override
  String get registerTermsSecOpenSourceTitle =>
      '4. Open Source & Third-Party Database Attribution';

  @override
  String get registerTermsSecOpenSourceBody =>
      'Food and nutritional information in Sirvya is powered in part by the Open Food Facts global collaborative database (openfoodfacts.org), made available under the Open Database License (ODbL 1.0) and Database Contents License (DbCL). Open Food Facts is an independent open-data project and does not endorse Sirvya.';

  @override
  String get registerTermsSecCoachTitle =>
      '5. Coach & Gym Terms (Independent Contractors)';

  @override
  String get registerTermsSecCoachBody =>
      '5.1 Independent Status\nSirvya is a neutral technology platform connecting users with fitness providers. Coaches and Gyms operate as independent businesses and are solely responsible for their sessions, guidance, and qualifications.\n\n5.2 Zero Tolerance for Fraudulent Credentials\nFalsification of professional certifications or misrepresentation results in immediate account expulsion and potential legal reporting.';

  @override
  String get registerTermsSecCommunityTitle =>
      '6. Community Guidelines & Intellectual Property';

  @override
  String get registerTermsSecCommunityBody =>
      '6.1 Community Standards: Zero tolerance for harassment, hate speech, spam, offensive media, or unauthorized commercial solicitation.\n\n6.2 Intellectual Property: Sirvya brand assets, designs, code, and interfaces are the proprietary property of DevUnivers. Users retain ownership of their personal workout content.';

  @override
  String get registerTermsSecBookingTitle => '7. Booking & Cancellation Policy';

  @override
  String get registerTermsSecBookingBody =>
      '7.1 Commitment: Automated systems detect and prevent fraudulent bookings.\n7.2 Provider Policies: Individual session cancellations are governed by the specific Coach or Gym policy selected at booking.';

  @override
  String get registerTermsAcceptButton => 'I AGREE & ACCEPT TERMS';

  @override
  String get registerCtaContinue => 'CONTINUE';

  @override
  String get registerCtaVerifyCreate => 'VERIFY & CREATE ACCOUNT';

  @override
  String get registerAlreadyRegistered => 'Already registered?';

  @override
  String get registerCtaLogIn => 'LOG IN';

  @override
  String get registerPasswordWeak => 'Weak';

  @override
  String get registerPasswordMedium => 'Medium';

  @override
  String get registerPasswordGood => 'Good';

  @override
  String get registerPasswordStrong => 'Strong';

  @override
  String registerPasswordSecurity(String strength) {
    return 'Security: $strength';
  }

  @override
  String get clientForgotErrorInvalidEmail => 'Invalid email address';

  @override
  String get clientForgotErrorOtpLength => 'Enter 6-digit verification code';

  @override
  String get clientForgotErrorPasswordShort =>
      'Password too short (min 6 chars)';

  @override
  String get clientForgotErrorPasswordsMismatch => 'Passwords do not match';

  @override
  String get clientForgotErrorEmailNotFound => 'Email not found';

  @override
  String get clientForgotErrorServerUnreachable => 'Unable to reach the server';

  @override
  String get clientForgotErrorInvalidOtp => 'Invalid verification code';

  @override
  String get clientForgotErrorResetFailed => 'Error while resetting password';

  @override
  String get clientForgotSuccessTitle => 'Password updated';

  @override
  String get clientForgotSuccessMessage =>
      'You can now log in with your new password.';

  @override
  String get clientForgotLogInCta => 'LOG IN';

  @override
  String get clientForgotStep1Label => 'STEP 1 / 3';

  @override
  String get clientForgotStep2Label => 'STEP 2 / 3';

  @override
  String get clientForgotStep3Label => 'STEP 3 / 3';

  @override
  String get clientForgotStep1Title => 'Your\nemail address';

  @override
  String get clientForgotStep2Title => 'Verification\ncode';

  @override
  String get clientForgotStep3Title => 'New\npassword';

  @override
  String get clientForgotStep1Sub =>
      'Enter your email to receive a password reset code.';

  @override
  String get clientForgotStep2Sub =>
      'Enter the 6-digit code sent to your email.';

  @override
  String get clientForgotStep3Sub => 'Choose a new secure password.';

  @override
  String get clientForgotEmailLabel => 'Email address';

  @override
  String get clientForgotEmailHint => 'you@email.ma';

  @override
  String get clientForgotOtpLabel => '6-digit OTP code';

  @override
  String get clientForgotOtpHint => '123456';

  @override
  String get clientForgotResendCode => 'Resend code';

  @override
  String get clientForgotNewPasswordLabel => 'New password';

  @override
  String get clientForgotNewPasswordHint => '••••••••';

  @override
  String get clientForgotConfirmPasswordLabel => 'Confirm password';

  @override
  String get clientForgotConfirmPasswordHint => '••••••••';

  @override
  String get clientForgotCtaSendCode => 'SEND CODE';

  @override
  String get clientForgotCtaVerifyCode => 'VERIFY CODE';

  @override
  String get clientForgotCtaResetPassword => 'RESET PASSWORD';

  @override
  String get clientForgotRememberPassword => 'Remember your password? ';

  @override
  String get clientForgotLogInLink => 'Log in';

  @override
  String get clientForgotPasswordWeak => 'Weak';

  @override
  String get clientForgotPasswordMedium => 'Medium';

  @override
  String get clientForgotPasswordGood => 'Good';

  @override
  String get clientForgotPasswordStrong => 'Strong';

  @override
  String clientForgotPasswordSecurity(String strength) {
    return 'Security: $strength';
  }

  @override
  String get headerFooterNavHome => 'Home';

  @override
  String get headerFooterNavExplore => 'Explore';

  @override
  String get headerFooterNavSessions => 'Sessions';

  @override
  String get headerFooterNavProfile => 'Profile';

  @override
  String headerFooterHomeContent(int index) {
    return 'Home Content $index';
  }

  @override
  String get coachOnboardingErrorInvalidQr =>
      'This QR code is not a valid coach invitation.';

  @override
  String get coachOnboardingErrorInvalidCode =>
      'This invitation code is not recognized.';

  @override
  String get coachOnboardingErrorUploadFailed => 'Upload failed.';

  @override
  String get coachOnboardingLogOut => 'Log out';

  @override
  String get coachOnboardingOfflineTitle => 'Unable to verify your account';

  @override
  String get coachOnboardingOfflineSubtitle =>
      'Check your connection and try again.';

  @override
  String get coachOnboardingRetry => 'RETRY';

  @override
  String get coachOnboardingBadgeVerification => 'VERIFICATION';

  @override
  String get coachOnboardingChoicesTitle => 'Verify your\ncoach account';

  @override
  String get coachOnboardingChoicesSubtitle =>
      'This step is required to access SIRVYA as a coach.';

  @override
  String get coachOnboardingQrTag => 'INSTANT ACCESS';

  @override
  String get coachOnboardingQrTitle => 'Scan an invitation QR code';

  @override
  String get coachOnboardingQrDesc =>
      'Scan the QR code of the coach who invited you and enter right away.';

  @override
  String get coachOnboardingOr => 'OR';

  @override
  String get coachOnboardingCertTag => 'REVIEW · UP TO 48H';

  @override
  String get coachOnboardingCertTitle => 'Take a photo of your certificate';

  @override
  String get coachOnboardingCertDesc =>
      'Our team checks your credentials. You enter once your request is approved.';

  @override
  String get coachOnboardingPrivacyNotice =>
      'Your documents are only used to verify your identity as a coach.';

  @override
  String get coachOnboardingBadgePending => 'PENDING REVIEW';

  @override
  String get coachOnboardingWaitingTitle => 'Waiting for\napproval';

  @override
  String get coachOnboardingWaitingSubtitle =>
      'Your certificate was sent. You will get access as soon as our team approves it.';

  @override
  String get coachOnboardingStepSentTitle => 'Certificate sent';

  @override
  String get coachOnboardingStepSentSub => 'We received your photo.';

  @override
  String get coachOnboardingStepReviewTitle => 'Under review';

  @override
  String get coachOnboardingStepReviewSub => 'Usually within 48 hours.';

  @override
  String get coachOnboardingStepApprovedTitle => 'Approved';

  @override
  String get coachOnboardingStepApprovedSub => 'You get full access to SIRVYA.';

  @override
  String get coachOnboardingCheckStatus => 'CHECK STATUS';

  @override
  String get coachOnboardingSendAnotherPhoto => 'Send another photo';

  @override
  String get coachAboutYouErrorUploadFailed => 'Upload failed';

  @override
  String get coachAboutYouPhotoReady => 'Photo ready. Save to confirm.';

  @override
  String coachAboutYouErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get coachAboutYouSelectLanguageTitle => 'Select Language';

  @override
  String get coachAboutYouLanguageAlreadyAdded => 'Language already added';

  @override
  String get coachAboutYouLangArabic => 'Arabic';

  @override
  String get coachAboutYouLangFrench => 'French';

  @override
  String get coachAboutYouLangEnglish => 'English';

  @override
  String get coachAboutYouLangSpanish => 'Spanish';

  @override
  String get coachAboutYouLangTamazight => 'Tamazight';

  @override
  String get coachAboutYouLangGerman => 'German';

  @override
  String get coachAboutYouLangItalian => 'Italian';

  @override
  String get coachAboutYouLangDutch => 'Dutch';

  @override
  String get coachAboutYouLangPortuguese => 'Portuguese';

  @override
  String get coachAboutYouLangRussian => 'Russian';

  @override
  String get coachAboutYouErrorFullName => 'Please enter your full name';

  @override
  String get coachAboutYouProfileUpdated => 'Profile updated';

  @override
  String get coachAboutYouErrorUpdating => 'Error while updating';

  @override
  String get coachAboutYouTitle => 'About you';

  @override
  String get coachAboutYouPreview => 'Preview';

  @override
  String get coachAboutYouChangePhoto => 'Change photo';

  @override
  String get coachAboutYouFullNameLabel => 'Full name';

  @override
  String get coachAboutYouProfessionalTitleLabel => 'Professional title';

  @override
  String get coachAboutYouBioLabel => 'About me';

  @override
  String get coachAboutYouLanguagesLabel => 'Languages';

  @override
  String get coachAboutYouAddLanguage => 'Add';

  @override
  String get coachAboutYouGenderLabel => 'Gender (optional)';

  @override
  String get coachAboutYouGenderMale => 'Male';

  @override
  String get coachAboutYouGenderFemale => 'Female';

  @override
  String get coachAboutYouGenderOther => 'Other';

  @override
  String get coachAboutYouGenderHint =>
      'Choose whether this appears on your public profile.';

  @override
  String get coachAboutYouShowOnProfile => 'Show on profile';

  @override
  String get coachAboutYouInstagramDialogTitle => 'Instagram handle';

  @override
  String get coachAboutYouInstagramHint => 'e.g. mouad.coach';

  @override
  String get coachAboutYouCancel => 'Cancel';

  @override
  String get coachAboutYouSave => 'Save';

  @override
  String get coachAboutYouErrorAddInstagramFirst =>
      'Please add your Instagram handle first';

  @override
  String get coachAboutYouErrorLaunchInstagram => 'Could not launch Instagram';

  @override
  String get coachAboutYouContactTitle => 'Contact';

  @override
  String get coachAboutYouInstagramTitle => 'Instagram';

  @override
  String get coachAboutYouAddInstagram => 'Add Instagram';

  @override
  String get coachAboutYouOpen => 'Open';

  @override
  String get coachAboutYouEmailPhoneManaged =>
      'Email and phone are managed\nin Account settings.';

  @override
  String get coachAboutYouAccountSettings => 'Account settings';

  @override
  String get coachAboutYouSaveChanges => 'Save changes';

  @override
  String get clientHomeSessionFallback => 'Session';

  @override
  String get clientHomeUpdateFavoritesFailed => 'Unable to update favorites';

  @override
  String clientHomeErrorCode(int statusCode) {
    return 'Error ($statusCode)';
  }

  @override
  String get clientHomeLoadRecommendationsFailed =>
      'Could not load recommendations. Please try again.';

  @override
  String get clientHomeConnectFailed => 'Unable to connect. Please try again.';

  @override
  String get clientHomeServerUnreachable => 'Server unreachable';

  @override
  String get clientHomeNutritionDiaryTitle => 'Your nutrition diary';

  @override
  String get clientHomeNutritionDiarySubtitle =>
      'Calories, macros & every meal';

  @override
  String get clientHomeSectionMyFavorites => 'My Favorites';

  @override
  String get clientHomeSectionRecommended => 'Recommended for You';

  @override
  String get clientHomeSetLocationDistances => 'Set location to see distances';

  @override
  String get clientHomeSectionUpcomingSessions => 'Upcoming Sessions';

  @override
  String get clientHomeSectionCoachingCompanies => 'Coaching companies';

  @override
  String get clientHomeHeroTitle => 'Your\nGoals.\nOur Coaches.';

  @override
  String get clientHomeHeroSubtitle =>
      'Find the right coach, book a\nsession and start your journey.';

  @override
  String get clientHomeFindYourCoach => 'Find your coach';

  @override
  String get clientHomeTagline => 'TRAIN • CONNECT • PROGRESS';

  @override
  String get clientHomeSetLocation => 'Set Location';

  @override
  String get clientHomeActionBookSession => 'Book a\nSession';

  @override
  String get clientHomeActionFindCoach => 'Find a\nCoach';

  @override
  String get clientHomeActionScanQr => 'Scan\nQR';

  @override
  String get clientHomeActionScanMeal => 'Sirvya AI\nScan meal';

  @override
  String get clientHomeSeeAll => 'See all';

  @override
  String get clientHomeCategoryAll => 'All';

  @override
  String get clientHomeNoCoachesAvailable => 'No coaches available';

  @override
  String get clientHomeRetry => 'Retry';

  @override
  String clientHomeSessionTodayAt(String time) {
    return 'Today • $time';
  }

  @override
  String clientHomeSessionTomorrowAt(String time) {
    return 'Tomorrow • $time';
  }

  @override
  String clientHomeSessionDateAt(String date, String time) {
    return '$date • $time';
  }

  @override
  String clientHomeWithCoach(String coachName) {
    return 'With $coachName';
  }

  @override
  String get clientHomeNoCompaniesAvailable => 'No companies available';

  @override
  String get clientHomeNewBadge => 'New';

  @override
  String clientHomeCoachCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coaches',
      one: '1 coach',
    );
    return '$_temp0';
  }

  @override
  String get clientHomeCoachingDefault => 'Coaching';

  @override
  String get clientHomeCountryDefault => 'Morocco';

  @override
  String clientHomeCompanyReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return ' ($_temp0)';
  }

  @override
  String get clientHomeViewCoaches => 'VIEW COACHES';

  @override
  String get clientListLocationServicesDisabled =>
      'Location services are disabled.';

  @override
  String get clientListLocationPermissionDenied =>
      'Location permissions are denied';

  @override
  String get clientListLocationPermissionDeniedForever =>
      'Location permissions are permanently denied.';

  @override
  String get clientListFetchingLocation => 'Fetching location...';

  @override
  String clientListGetLocationFailed(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String clientListServerError(int statusCode) {
    return 'Server error ($statusCode)';
  }

  @override
  String get clientListLoadRecommendationsFailed =>
      'Could not load recommendations. Please try again.';

  @override
  String get clientListConnectFailed => 'Unable to connect. Please try again.';

  @override
  String get clientListServerUnreachable => 'Server unreachable.';

  @override
  String get clientListFiltersButton => 'Filters';

  @override
  String get clientListAllSpecialties => 'All specialties';

  @override
  String get clientListFindACoach => 'Find a coach';

  @override
  String get clientListMapToggle => 'Map';

  @override
  String get clientListListToggle => 'List';

  @override
  String get clientListSearchHint => 'Search coaches, specialties...';

  @override
  String get clientListVerifiedOnly => 'Verified only';

  @override
  String clientListMinRatingChip(String rating) {
    return '$rating+ Stars';
  }

  @override
  String get clientListFilterCoachesTitle => 'Filter coaches';

  @override
  String get clientListDone => 'Done';

  @override
  String get clientListVerifiedOnlySubtitle =>
      'Show coaches verified by Sirvya';

  @override
  String get clientListSortByLabel => 'SORT BY';

  @override
  String get clientListSortRecommended => 'Recommended for you';

  @override
  String get clientListSortPoints => 'Points';

  @override
  String get clientListSortAlphabetical => 'Alphabetical';

  @override
  String get clientListSortTopRated => 'Top rated';

  @override
  String get clientListMinRatingLabel => 'MINIMUM RATING';

  @override
  String get clientListClear => 'Clear';

  @override
  String get clientListAll => 'All';

  @override
  String get clientListCityLabel => 'CITY';

  @override
  String get clientListLocationToBeDefined => 'To be defined';

  @override
  String get clientListCompanyIndependent => 'Independent';

  @override
  String clientListNoCoachesInCity(String city) {
    return 'No coaches found in $city';
  }

  @override
  String get clientListNoCoachesFound => 'No coaches found';

  @override
  String clientListCoachesFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coaches found',
      one: '1 coach found',
    );
    return '$_temp0';
  }

  @override
  String get clientListListViewTooltip => 'List view';

  @override
  String get clientListGridViewTooltip => 'Grid view';

  @override
  String get clientListSortAction => 'Sort';

  @override
  String clientListNoCompaniesInCity(String city) {
    return 'No companies found in $city';
  }

  @override
  String get clientListNoCompaniesFound => 'No companies found';

  @override
  String get clientListRetry => 'Retry';

  @override
  String get clientListReset => 'Reset';

  @override
  String get clientListPremiumBadge => 'PREMIUM';

  @override
  String get clientListNewBadge => 'New';

  @override
  String get clientListAvailableToday => 'Available today';

  @override
  String get clientListPriceFrom => 'From';

  @override
  String clientListPriceCurrency(int price) {
    return '$price MAD';
  }

  @override
  String get clientListPriceLabel => 'Price';

  @override
  String get clientListPriceOnRequest => 'Price on request';

  @override
  String get clientListViewAndBook => 'View & book';

  @override
  String get clientListCodeCopied => 'Code copied';

  @override
  String get clientListNumberCopied => 'Number copied';

  @override
  String get clientListViewCoachesBadge => 'View coaches';

  @override
  String get clientListViewProfile => 'VIEW PROFILE';

  @override
  String clientCoachFavoritesServerError(int statusCode) {
    return 'Server error ($statusCode)';
  }

  @override
  String get clientCoachFavoritesServerUnreachable => 'Server unreachable';

  @override
  String get clientCoachFavoritesUpdateFailed => 'Unable to update favorites';

  @override
  String get clientCoachFavoritesLocationToBeDefined => 'To be defined';

  @override
  String get clientCoachFavoritesCompanyIndependent => 'Independent';

  @override
  String get clientCoachFavoritesTitle => 'My Favorites';

  @override
  String get clientCoachFavoritesLoading => 'Loading…';

  @override
  String get clientCoachFavoritesEmptySubtitle =>
      'Coaches you like will appear here';

  @override
  String clientCoachFavoritesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coaches saved',
      one: '1 coach saved',
    );
    return '$_temp0';
  }

  @override
  String get clientCoachFavoritesSearchHint =>
      'Search your favorite coaches...';

  @override
  String get clientCoachFavoritesRetry => 'Retry';

  @override
  String get clientCoachFavoritesEmptyTitle => 'No favorite coaches yet';

  @override
  String get clientCoachFavoritesEmptyMessage =>
      'Tap the heart on a coach to save them here.';

  @override
  String get clientCoachFavoritesFindACoach => 'Find a coach';

  @override
  String get clientCoachFavoritesNoResults => 'No coach matches your search';

  @override
  String get clientCoachFavoritesReset => 'Reset';

  @override
  String get clientCoachFavoritesNewBadge => 'New';

  @override
  String get clientCoachFavoritesViewProfile => 'VIEW PROFILE';

  @override
  String get clientCoachReviewsLoadFailed =>
      'Could not load feedback. Pull down to retry.';

  @override
  String get clientCoachReviewsMyFeedbackTitle => 'My feedback';

  @override
  String get clientCoachReviewsTitle => 'Reviews & Ratings';

  @override
  String clientCoachReviewsAllCount(int count) {
    return 'All Reviews ($count)';
  }

  @override
  String clientCoachReviewsStarCount(int stars, int count) {
    return '$stars Star Reviews ($count)';
  }

  @override
  String get clientCoachReviewsClearFilter => 'Clear filter';

  @override
  String clientCoachReviewsTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String clientCoachReviewsFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String clientCoachReviewsEmptyStarFilter(int stars) {
    return 'No reviews with $stars stars yet';
  }

  @override
  String get clientCoachReviewsEmptyCoachView =>
      'Your client feedback will appear here';

  @override
  String get clientCoachReviewsEmptyClientView => 'No reviews found';

  @override
  String get clientCoachReviewsMyReviewBadge => 'My review';

  @override
  String get clientCompanyDetailNotFound => 'Advisor not found';

  @override
  String clientCompanyDetailLoadError(int statusCode) {
    return 'Error loading advisor ($statusCode)';
  }

  @override
  String get clientCompanyDetailVerifiedBadge => 'VERIFIED';

  @override
  String get clientCompanyDetailStatCoaches => 'Coaches';

  @override
  String get clientCompanyDetailStatInvitations => 'Invitations';

  @override
  String get clientCompanyDetailStatPoints => 'Points';

  @override
  String clientCompanyDetailTabCoaches(int count) {
    return 'COACHES ($count)';
  }

  @override
  String get clientCompanyDetailTabAbout => 'ABOUT';

  @override
  String clientCompanyDetailTabGallery(int count) {
    return 'GALLERY ($count)';
  }

  @override
  String get clientCompanyDetailTabLocation => 'LOCATION';

  @override
  String get clientCompanyDetailNoCoaches => 'No coaches linked yet';

  @override
  String get clientCompanyDetailCertifiedCoach => 'Certified coach';

  @override
  String get clientCompanyDetailSectionProfile => 'PROFILE';

  @override
  String get clientCompanyDetailFullName => 'Full name';

  @override
  String get clientCompanyDetailEmail => 'Email';

  @override
  String get clientCompanyDetailSpecialty => 'Specialty';

  @override
  String get clientCompanyDetailCity => 'City';

  @override
  String get clientCompanyDetailGymName => 'Gym name';

  @override
  String get clientCompanyDetailAddress => 'Address';

  @override
  String get clientCompanyDetailSectionStatistics => 'STATISTICS';

  @override
  String get clientCompanyDetailStatTeamCoaches => 'Coaches on the team';

  @override
  String get clientCompanyDetailStatTotalInvitations => 'Total invitations';

  @override
  String get clientCompanyDetailStatTotalPoints => 'Total points';

  @override
  String get clientCompanyDetailNoGalleryImages => 'No gym images yet';

  @override
  String get clientCompanyDetailSectionAddress => 'ADDRESS';

  @override
  String get clientCompanyDetailAddressNotProvided => 'Address not provided';

  @override
  String get clientCompanyDetailSectionMap => 'MAP';

  @override
  String get clientCompanyDetailLocationNotAvailable =>
      'Location not available';

  @override
  String get clientCompanyDetailGymDefault => 'Gym';

  @override
  String get clientCompanyDetailOpenMap => 'OPEN';

  @override
  String get clientCompanyDetailLoadingErrorTitle => 'Loading error';

  @override
  String get clientCompanyDetailRetry => 'RETRY';

  @override
  String get clientCompanyDetailViewProfile => 'VIEW PROFILE';

  @override
  String get clientCompanyDetailCoachDefault => 'Coach';

  @override
  String get clientCompanyDetailAnywhere => 'Anywhere';

  @override
  String get clientCompanyDetailNewBadge => 'New';

  @override
  String clientCompanyDetailReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String clientCompanyDetailInvitationsShort(int count) {
    return '$count inv.';
  }

  @override
  String clientCompanyDetailPointsShort(int count) {
    return '$count pts';
  }

  @override
  String clientProfilServerError(int statusCode) {
    return 'Server error ($statusCode)';
  }

  @override
  String get clientProfilCheckConnection =>
      'Check your connection and try again.';

  @override
  String get clientProfilLoadFailed =>
      'Unable to load your profile. Please try again.';

  @override
  String get clientProfilWeightLoadFailed =>
      'Could not load your latest records. Tap Refresh history to try again.';

  @override
  String get clientProfilWeightSaveFailed => 'Could not save weight.';

  @override
  String get clientProfilWeightSaved => 'Weight saved ✓';

  @override
  String get clientProfilPhotoSaveFailed =>
      'Could not save your photo. Please try again.';

  @override
  String get clientProfilPhotoUpdated => 'Profile photo updated ✓';

  @override
  String get clientProfilUploadError => 'Upload error';

  @override
  String clientProfilGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get clientProfilNameRequired => 'Please add your first and last name.';

  @override
  String get clientProfilInvalidHeight =>
      'Enter a valid height in centimetres.';

  @override
  String get clientProfilSaveFailed => 'Error while saving.';

  @override
  String get clientProfilServerUnreachable => 'Unable to reach the server.';

  @override
  String get clientProfilDeleteBlockedDefault =>
      'Cannot delete account right now.';

  @override
  String get clientProfilSendCodeFailed => 'Failed to send code.';

  @override
  String get clientProfilEnterFullCode => 'Please enter the full 6-digit code.';

  @override
  String get clientProfilVerificationFailed => 'Verification failed.';

  @override
  String get clientProfilDeleteAccountTitle => 'Delete Account';

  @override
  String get clientProfilDeletePermanentSubtitle => 'This action is permanent';

  @override
  String get clientProfilDeleteWhatWillBeDeleted => 'What will be deleted:';

  @override
  String get clientProfilDeleteItemProfile =>
      'Your profile and personal information';

  @override
  String get clientProfilDeleteItemSessions =>
      'All sessions and booking history';

  @override
  String get clientProfilDeleteItemMessages => 'Messages and conversations';

  @override
  String get clientProfilDeleteItemWeight => 'Weight progress and fitness data';

  @override
  String get clientProfilDeleteUnderstandCheckbox =>
      'I understand this action is irreversible and all my data will be permanently deleted.';

  @override
  String get clientProfilCancel => 'Cancel';

  @override
  String get clientProfilSendCode => 'SEND CODE';

  @override
  String get clientProfilVerifyIdentityTitle => 'Verify your identity';

  @override
  String get clientProfilVerifyCheckEmailSubtitle =>
      'Check your email for the code';

  @override
  String get clientProfilVerifyInstructions =>
      'Enter the 6-digit code sent to your email address to confirm account deletion.';

  @override
  String clientProfilCodeExpiresIn(String minutes, String seconds) {
    return 'Code expires in $minutes:$seconds';
  }

  @override
  String get clientProfilCodeExpired => 'Code expired';

  @override
  String get clientProfilResendCode => 'Resend code';

  @override
  String get clientProfilBack => 'Back';

  @override
  String get clientProfilDeleteAccountBtn => 'DELETE ACCOUNT';

  @override
  String get clientProfilGenderMale => 'Male';

  @override
  String get clientProfilGenderFemale => 'Female';

  @override
  String get clientProfilGenderOther => 'Other';

  @override
  String get clientProfilPasswordUpdated => 'Password updated ✓';

  @override
  String get clientProfilLoadingProfile => 'Loading profile...';

  @override
  String get clientProfilRetry => 'Retry';

  @override
  String get clientProfilSaving => 'Saving…';

  @override
  String get clientProfilSaveChanges => 'Save changes';

  @override
  String get clientProfilHeaderTitle => 'My profile';

  @override
  String get clientProfilHeaderSavedSubtitle => 'Your changes are saved.';

  @override
  String get clientProfilHeaderDefaultSubtitle =>
      'A little more you. A stronger journey.';

  @override
  String get clientProfilCancelEditingTooltip => 'Cancel editing';

  @override
  String get clientProfilEditProfileTooltip => 'Edit profile';

  @override
  String get clientProfilStatSessions => 'Sessions';

  @override
  String get clientProfilStatCurrentWeight => 'Current weight';

  @override
  String clientProfilWeightValueKg(String weight) {
    return '$weight kg';
  }

  @override
  String get clientProfilStatHeight => 'Height';

  @override
  String clientProfilHeightValueCm(String height) {
    return '$height cm';
  }

  @override
  String get clientProfilTabMyDetails => 'My details';

  @override
  String get clientProfilTabMyProgress => 'My progress';

  @override
  String get clientProfilTabNutrition => 'Nutrition';

  @override
  String get clientProfilEditInstructions =>
      'Make your changes below, then tap Save changes.';

  @override
  String get clientProfilGroupAboutTitle => 'About you';

  @override
  String get clientProfilGroupAboutSubtitle =>
      'The details that make this space yours.';

  @override
  String get clientProfilFirstName => 'First name';

  @override
  String get clientProfilLastName => 'Last name';

  @override
  String get clientProfilHeightCm => 'Height (cm)';

  @override
  String get clientProfilGroupInterestsTitle => 'Your fitness interests';

  @override
  String get clientProfilGroupInterestsSubtitle =>
      'Choose up to 5 things you enjoy. We’ll use them to help you discover coaches.';

  @override
  String get clientProfilGroupAccountTitle => 'Account & location';

  @override
  String get clientProfilGroupAccountSubtitle =>
      'Keep your contact details up to date.';

  @override
  String get clientProfilEmailAddress => 'Email address';

  @override
  String get clientProfilAddEmail => 'Add your email';

  @override
  String get clientProfilPhoneNumber => 'Phone number';

  @override
  String get clientProfilAddPhone => 'Add your phone number';

  @override
  String get clientProfilMyLocation => 'My location';

  @override
  String get clientProfilSetCity => 'Set your city';

  @override
  String get clientProfilGroupSirvyaTitle => 'Your Sirvya';

  @override
  String get clientProfilGroupSirvyaSubtitle =>
      'Your people, your preferences, your peace of mind.';

  @override
  String get clientProfilFavoriteCoaches => 'Favorite coaches';

  @override
  String get clientProfilFavoriteCoachesSubtitle => 'Keep your favorites close';

  @override
  String get clientProfilNotifications => 'Notifications';

  @override
  String get clientProfilNotificationsSubtitle => 'Updates about your activity';

  @override
  String get clientProfilPasswordSecurity => 'Password & security';

  @override
  String get clientProfilPasswordSecuritySubtitle => 'Manage your password';

  @override
  String get clientProfilBlockedAccounts => 'Blocked accounts';

  @override
  String get clientProfilBlockedAccountsSubtitle =>
      'Manage who can contact you';

  @override
  String get clientProfilLogOut => 'Log out';

  @override
  String get clientProfilDeleteMyAccount => 'Delete my account';

  @override
  String get clientProfilChooseInterests => 'Choose your interests';

  @override
  String get clientProfilInterestsLoadFailed =>
      'Interests could not be loaded. Try again to choose from the catalog.';

  @override
  String get clientProfilTryAgain => 'Try again';

  @override
  String get clientProfilMaxInterests => 'Choose up to 5 interests.';

  @override
  String get clientProfilGender => 'Gender';

  @override
  String get clientProfilNotAddedYet => 'Not added yet';

  @override
  String get clientBookingHomeVisitLocation =>
      'Home visit — arrange address with coach in messages';

  @override
  String get clientBookingDefaultLocation =>
      'Location to be arranged with coach in messages';

  @override
  String clientBookingSessionLabel(int number) {
    return 'Session $number';
  }

  @override
  String get clientBookingLeadTimeError =>
      'Choose a session more than one hour from now.';

  @override
  String clientBookingMultipleBookedSuccess(int count) {
    return 'All $count sessions booked successfully!';
  }

  @override
  String get clientBookingSingleBookedSuccess => 'Booking sent successfully!';

  @override
  String clientBookingErrorCode(int code) {
    return 'Error ($code)';
  }

  @override
  String get clientBookingServerUnreachable => 'Unable to reach the server.';

  @override
  String get clientBookingChoosePackageTitle => 'Choose a Package';

  @override
  String get clientBookingSelectPackageHeading => 'Select a Package';

  @override
  String get clientBookingSelectPackageSubtitle =>
      'Choose the package that fits you best, or book without a package.';

  @override
  String get clientBookingContinueToBooking => 'Continue to Booking';

  @override
  String clientBookingPackageSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String clientBookingPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String get clientBookingPriceToDiscuss => 'Price to discuss';

  @override
  String get clientBookingBookWithoutPackage => 'Book without a package';

  @override
  String get clientBookingBookWithoutPackageSub =>
      'Single session — price discussed with coach';

  @override
  String clientBookingBannerPackagePrice(String name, int price) {
    return '$name · $price MAD';
  }

  @override
  String clientBookingBannerPackageRequest(String name) {
    return '$name · Price on request';
  }

  @override
  String get clientBookingNoPackageSelected => 'No package selected';

  @override
  String get clientBookingPackageSessionsTitle => 'Package Sessions';

  @override
  String clientBookingScheduledProgress(int completed, int total) {
    return '$completed of $total scheduled';
  }

  @override
  String clientBookingSelectDatesWithPrice(int price) {
    return 'Select a date & time for each session ($price MAD / session):';
  }

  @override
  String clientBookingSelectDatesNoPrice(int total) {
    return 'Select a date & time for each of the $total sessions included in your package:';
  }

  @override
  String clientBookingSessionWithPrice(int number, int price) {
    return 'Session $number · $price MAD';
  }

  @override
  String get clientBookingSelectingNow => 'Selecting now...';

  @override
  String get clientBookingTapToSelect => 'Tap to select';

  @override
  String get clientBookingHeaderTitle => 'Book a session';

  @override
  String get clientBookingCoachFallback => 'Coach';

  @override
  String get clientBookingAnywhereFallback => 'Anywhere';

  @override
  String get clientBookingNewCoach => 'New';

  @override
  String clientBookingReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String clientBookingPricePerSession(int price) {
    return '$price MAD/session';
  }

  @override
  String clientBookingSessionDateHeader(int number, String month) {
    return 'Session $number Date · $month';
  }

  @override
  String get clientBookingWeekdayMon => 'M';

  @override
  String get clientBookingWeekdayTue => 'T';

  @override
  String get clientBookingWeekdayWed => 'W';

  @override
  String get clientBookingWeekdayThu => 'T';

  @override
  String get clientBookingWeekdayFri => 'F';

  @override
  String get clientBookingWeekdaySat => 'S';

  @override
  String get clientBookingWeekdaySun => 'S';

  @override
  String get clientBookingSessionLocationTitle => 'Session location';

  @override
  String get clientBookingLocationHomeTitle => 'My home';

  @override
  String get clientBookingLocationHomeSubtitle =>
      'Arrange your address with the coach in messages';

  @override
  String get clientBookingLocationGymSubtitle =>
      'Coach’s gym · confirm directions in messages';

  @override
  String get clientBookingLocationTbdTitle => 'To be defined';

  @override
  String get clientBookingLocationTbdSubtitle =>
      'Agree on the meeting place with your coach in messages';

  @override
  String clientBookingSessionTimeSlotTitle(int number) {
    return 'Session $number Time slot';
  }

  @override
  String get clientBookingTimeSlotsTitle => 'Time slots';

  @override
  String clientBookingAvailableSlotsCount(int count) {
    return '$count available';
  }

  @override
  String get clientBookingSlotsFull => 'Full';

  @override
  String clientBookingDateForSession(String date, int number) {
    return '$date · for Session $number';
  }

  @override
  String get clientBookingSlotSelected => '✓ Selected';

  @override
  String get clientBookingSlotDuration => '1h';

  @override
  String get clientBookingSlotBlocked => 'Blocked';

  @override
  String get clientBookingSlotBooked => 'Booked';

  @override
  String get clientBookingLegendFree => 'Free';

  @override
  String get clientBookingLegendUnavailable => 'Unavailable';

  @override
  String clientBookingConfirmAllSessions(int total) {
    return 'CONFIRM ALL $total SESSIONS';
  }

  @override
  String clientBookingSelectAllSessions(int completed, int total) {
    return 'SELECT ALL SESSIONS ($completed/$total CHOSEN)';
  }

  @override
  String clientBookingConfirmWithTime(String time) {
    return 'CONFIRM · $time';
  }

  @override
  String get clientBookingChooseASlot => 'CHOOSE A SLOT';

  @override
  String clientBookingSelectDateAndTimePrompt(int number) {
    return 'Please select a date & time for Session $number';
  }

  @override
  String get clientBookingLocationYourGym => 'Your gym';

  @override
  String get clientBookingConfirmDialogTitle => 'Confirm booking';

  @override
  String get clientBookingNotYetRated => 'Not yet rated';

  @override
  String get clientBookingLabelDate => 'Date';

  @override
  String get clientBookingLabelTime => 'Time';

  @override
  String clientBookingScheduledSessionsCount(int count) {
    return 'Scheduled Sessions ($count)';
  }

  @override
  String clientBookingSessionDateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get clientBookingNotScheduledYet => 'Not scheduled yet';

  @override
  String get clientBookingLabelLocation => 'Location';

  @override
  String get clientBookingLabelPackage => 'Package';

  @override
  String get clientBookingLabelTotalPrice => 'Total Price';

  @override
  String clientBookingTotalPriceMulti(int total, int perSession) {
    return '$total MAD ($perSession MAD / session)';
  }

  @override
  String clientBookingTotalPriceSingle(int total) {
    return '$total MAD / session';
  }

  @override
  String get clientBookingBtnCancel => 'CANCEL';

  @override
  String get clientBookingBtnConfirm => 'CONFIRM';

  @override
  String get clientCoachDetailRemovedFavorite => 'Removed from favorites';

  @override
  String get clientCoachDetailAddedFavorite => 'Added to favorites ✓';

  @override
  String get clientCoachDetailFavoriteUpdateFailed =>
      'Failed to update favorites';

  @override
  String get clientCoachDetailConnectionFailed => 'Connection failed';

  @override
  String clientCoachDetailErrorCode(int code) {
    return 'Error $code';
  }

  @override
  String get clientCoachDetailServerUnreachable =>
      'Unable to reach the server.';

  @override
  String get clientCoachDetailSelectRatingFirst => 'Select a rating first';

  @override
  String get clientCoachDetailReviewSaved => 'Review saved ✓';

  @override
  String get clientCoachDetailServerError => 'Server error';

  @override
  String get clientCoachDetailInvitationSent =>
      'Invitation sent to the coach ✓';

  @override
  String get clientCoachDetailInvitationAlreadySent =>
      'Invitation already sent';

  @override
  String get clientCoachDetailLoginToMessage =>
      'Please login to message the coach';

  @override
  String get clientCoachDetailConversationStartFailed =>
      'Unable to start conversation. Please try again.';

  @override
  String get clientCoachDetailReportReasonSpam => 'Spam';

  @override
  String get clientCoachDetailReportReasonHarassment => 'Harassment';

  @override
  String get clientCoachDetailReportReasonInappropriate =>
      'Inappropriate content';

  @override
  String get clientCoachDetailReportReasonFraud => 'Fraud / Scam';

  @override
  String get clientCoachDetailReportReasonOther => 'Other';

  @override
  String clientCoachDetailReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get clientCoachDetailReportPrompt =>
      'Why are you reporting this user? We take these reports seriously.';

  @override
  String get clientCoachDetailCancel => 'Cancel';

  @override
  String get clientCoachDetailSubmit => 'Submit';

  @override
  String get clientCoachDetailReportSubmitted =>
      'Report submitted successfully.';

  @override
  String get clientCoachDetailReportFailed => 'Failed to submit report';

  @override
  String get clientCoachDetailNetworkError => 'Network error';

  @override
  String clientCoachDetailBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get clientCoachDetailBlockMessage =>
      'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.';

  @override
  String get clientCoachDetailBlockConfirm => 'Block';

  @override
  String get clientCoachDetailUserBlocked => 'User blocked.';

  @override
  String get clientCoachDetailBlockFailed => 'Failed to block user';

  @override
  String get clientCoachDetailQrTitle => 'Coach QR Code';

  @override
  String get clientCoachDetailCertificationsTitle => 'Certifications';

  @override
  String get clientCoachDetailVerifiedBySirvya => 'Verified by Sirvya';

  @override
  String get clientCoachDetailSelfReported => 'Self-reported';

  @override
  String get clientCoachDetailCoachingPackagesTitle => 'Coaching packages';

  @override
  String get clientCoachDetailNoPackagesAvailable =>
      'No packages available for this coach.';

  @override
  String clientCoachDetailPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String clientCoachDetailPackageSessionInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions · 60 min each',
      one: '1 session · 60 min',
    );
    return '$_temp0';
  }

  @override
  String get clientCoachDetailChooseAndBook => 'Book';

  @override
  String get clientCoachDetailSeeAll => 'See all >';

  @override
  String get clientCoachDetailAgreeOnPriceNote =>
      'Agree on the price before confirmation.';

  @override
  String get clientCoachDetailOnRequest => 'On request';

  @override
  String get clientCoachDetailBookChip => 'Book >';

  @override
  String get clientCoachDetailAvailableToday => 'Available today';

  @override
  String get clientCoachDetailReportCoachMenu => 'Report Coach';

  @override
  String get clientCoachDetailBlockCoachMenu => 'Block Coach';

  @override
  String get clientCoachDetailStatRating => 'Rating';

  @override
  String get clientCoachDetailStatReviews => 'Reviews';

  @override
  String get clientCoachDetailStatClients => 'Clients';

  @override
  String clientCoachDetailPriceFrom(String price) {
    return 'From $price MAD';
  }

  @override
  String get clientCoachDetailPriceOnRequest => 'Price on request';

  @override
  String clientCoachDetailSessionRatesFrom(String price) {
    return 'Session rates starting from $price MAD';
  }

  @override
  String get clientCoachDetailContactForRates =>
      'Contact the coach for session rates';

  @override
  String get clientCoachDetailMessageBtn => 'Message';

  @override
  String get clientCoachDetailRequestBookingBtn => 'Book';

  @override
  String get clientCoachDetailSpecialtiesTitle => 'Specialties';

  @override
  String get clientCoachDetailAboutTitle => 'About';

  @override
  String get clientCoachDetailGalleryTitle => 'Coaching gallery';

  @override
  String clientCoachDetailViewAllCount(int count) {
    return 'View all ($count)';
  }

  @override
  String get clientCoachDetailCoachingFallback => 'Coaching';

  @override
  String get clientCoachDetailAvailabilityTitle => 'Availability';

  @override
  String get clientCoachDetailNoSlotsAvailable => 'No slots available';

  @override
  String get clientCoachDetailAssociatedGymTitle => 'Associated gym';

  @override
  String get clientCoachDetailPracticalInfoTitle => 'Practical info';

  @override
  String get clientCoachDetailCityDefault => 'Casablanca';

  @override
  String get clientCoachDetailQrRowLabel => 'Coach QR code';

  @override
  String get clientCoachDetailTapToEnlarge => 'Tap to enlarge';

  @override
  String get clientCoachDetailClientReviewsTitle => 'Client reviews';

  @override
  String clientCoachDetailRatingSummary(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$rating · $_temp0 >';
  }

  @override
  String get clientCoachDetailEditMyReview => 'Edit my review';

  @override
  String get clientCoachDetailLeaveAReview => 'Leave a review';

  @override
  String clientCoachDetailViewAllReviewsBtn(int count) {
    return 'View all $count reviews';
  }

  @override
  String get clientCoachDetailYourRatingLabel => 'Your rating';

  @override
  String get clientCoachDetailCommentOptionalLabel => 'Comment (optional)';

  @override
  String get clientCoachDetailReviewHint =>
      'Share your experience with this coach…';

  @override
  String get clientCoachDetailUpdateReviewBtn => 'Update review';

  @override
  String get clientCoachDetailPublishReviewBtn => 'Publish review';

  @override
  String get clientCoachDetailMyReviewBadge => 'My review';

  @override
  String get clientCoachDetailNoReviewsYet => 'No reviews yet';

  @override
  String get clientCoachDetailBeFirstToReview =>
      'Be the first to share your experience';

  @override
  String get clientCoachDetailRetry => 'Retry';

  @override
  String clientSessionsServerError(int code) {
    return 'Server error ($code)';
  }

  @override
  String get clientSessionsCheckConnectionError =>
      'Check your connection and try again.';

  @override
  String get clientSessionsLoadError =>
      'Unable to load your sessions. Please try again.';

  @override
  String get clientSessionsRefreshTooltip => 'Refresh sessions';

  @override
  String clientSessionsCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed',
      one: '1 completed',
    );
    return '$_temp0';
  }

  @override
  String get clientSessionsTitle => 'My sessions';

  @override
  String get clientSessionsSubtitle => 'Manage your coaching appointments.';

  @override
  String clientSessionsTabUpcoming(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String clientSessionsTabPast(int count) {
    return 'Past ($count)';
  }

  @override
  String get clientSessionsTryAgain => 'Try again';

  @override
  String get clientSessionsEmptyUpcoming => 'No upcoming sessions.';

  @override
  String get clientSessionsEmptyPast => 'No past sessions.';

  @override
  String get clientSessionsConfirmedWhenAccepted =>
      'Your session is confirmed once the coach accepts.';

  @override
  String get clientSessionsHelpTitle => 'Need help with a booking?';

  @override
  String get clientSessionsHelpSubtitle =>
      'Get in touch and we\'ll be happy to help.';

  @override
  String get clientSessionsContactSupport => 'Contact support';

  @override
  String get clientSessionsFilterAll => 'All';

  @override
  String get clientSessionsFilterCompleted => 'Completed';

  @override
  String get clientSessionsFilterCancelled => 'Cancelled';

  @override
  String get clientSessionsCancelDialogTitle => 'Cancel session';

  @override
  String get clientSessionsCancelDialogMessage =>
      'Are you sure you want to cancel this booking?';

  @override
  String get clientSessionsCancelDialogNo => 'NO';

  @override
  String get clientSessionsCancelDialogYes => 'YES, CANCEL';

  @override
  String get clientSessionsStatusCompleted => 'Completed';

  @override
  String get clientSessionsStatusPending => 'Pending';

  @override
  String get clientSessionsStatusExpired => 'Expired';

  @override
  String get clientSessionsStatusPriceDeclined => 'Price declined';

  @override
  String get clientSessionsStatusCancelled => 'Cancelled';

  @override
  String get clientSessionsPriceOfferReady =>
      'Price offer ready — open details to approve.';

  @override
  String get clientSessionsAwaitingPrice => 'Awaiting coach’s price.';

  @override
  String get clientSessionsAwaitingConfirmation =>
      'Awaiting coach confirmation.';

  @override
  String get clientSessionsCancelledByYou => 'Cancelled by you';

  @override
  String clientSessionsPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String clientSessionsDurationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String get clientSessionsLocationTbc => 'Location to be confirmed';

  @override
  String clientSessionsSessionPriceWithPkg(String packageName) {
    return 'Session price ($packageName)';
  }

  @override
  String get clientSessionsSessionTotal => 'Session total';

  @override
  String get clientSessionsViewDetails => 'View details >';

  @override
  String get clientSessionsBookAgain => 'Book again >';

  @override
  String clientSessionsEditReviewRating(int rating) {
    return 'Edit review: $rating/5 ';
  }

  @override
  String get clientSessionsLeaveAReview => 'Leave a review';

  @override
  String get clientSessionsMessageBtn => 'Message';

  @override
  String get clientSessionsCancelBooking => 'Cancel booking';

  @override
  String get clientSessionDetailAcceptPriceTitle => 'Accept proposed price?';

  @override
  String get clientSessionDetailDeclinePriceTitle => 'Decline proposed price?';

  @override
  String clientSessionDetailAcceptPriceMessage(String price) {
    return 'Accept $price MAD and confirm this session?';
  }

  @override
  String get clientSessionDetailDeclinePriceMessage =>
      'Declining will cancel this booking request.';

  @override
  String get clientSessionDetailAcceptConfirmBtn => 'ACCEPT & CONFIRM';

  @override
  String get clientSessionDetailDeclinePriceBtn => 'DECLINE PRICE';

  @override
  String get clientSessionDetailPriceRespondError =>
      'Could not respond to price.';

  @override
  String get clientSessionDetailConnectionUnavailable =>
      'Connection unavailable. Please try again.';

  @override
  String get clientSessionDetailPriceExpiredTitle => 'Price request expired';

  @override
  String get clientSessionDetailApprovePriceTitle =>
      'Approve your session price';

  @override
  String get clientSessionDetailAwaitingPriceTitle => 'Awaiting coach’s price';

  @override
  String get clientSessionDetailPriceExpiredBody =>
      'No price was agreed before the deadline. Please make a new booking.';

  @override
  String clientSessionDetailProposedPriceBody(String price) {
    return '$price MAD per session. Your acceptance confirms this booking.';
  }

  @override
  String get clientSessionDetailAwaitingPriceBody =>
      'Your coach will send a price offer. You must accept it to confirm the session.';

  @override
  String clientSessionDetailPriceDeadline(String date, String time) {
    return 'Deadline: $date · $time (2 hours before the session)';
  }

  @override
  String get clientSessionDetailAcceptAndConfirm => 'Accept & confirm';

  @override
  String get clientSessionDetailDecline => 'Decline';

  @override
  String get clientSessionDetailStatusExpired => 'EXPIRED';

  @override
  String get clientSessionDetailStatusPriceDeclined => 'PRICE DECLINED';

  @override
  String get clientSessionDetailStatusPending => 'PENDING';

  @override
  String get clientSessionDetailStatusConfirmed => 'CONFIRMED';

  @override
  String get clientSessionDetailStatusCancelled => 'CANCELLED';

  @override
  String get clientSessionDetailCancelTitle => 'Cancel session?';

  @override
  String get clientSessionDetailCancelMessage =>
      'This action cannot be undone.';

  @override
  String get clientSessionDetailCancelConfirmBtn => 'CANCEL SESSION';

  @override
  String get clientSessionDetailSessionCancelledSnack => 'Session cancelled.';

  @override
  String get clientSessionDetailCancelErrorSnack => 'Error while cancelling.';

  @override
  String get clientSessionDetailServerUnreachable =>
      'Unable to reach the server.';

  @override
  String get clientSessionDetailReviewPublishedSnack =>
      'Review published successfully!';

  @override
  String get clientSessionDetailReviewPublishErrorSnack =>
      'Error while publishing.';

  @override
  String get clientSessionDetailDialogBack => 'BACK';

  @override
  String get clientSessionDetailTopBarTitle => 'Session details';

  @override
  String clientSessionDetailBannerPriceProposed(String price) {
    return '$price MAD · proposed';
  }

  @override
  String clientSessionDetailBannerPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String get clientSessionDetailBannerFreeSession => 'Free session';

  @override
  String get clientSessionDetailBannerAwaitingPricing => 'Awaiting pricing';

  @override
  String clientSessionDetailDurationTimeRange(
      int minutes, String start, String end) {
    return '$minutes min · $start — $end';
  }

  @override
  String clientSessionDetailPerSessionPackage(String packageName) {
    return 'Per session · $packageName';
  }

  @override
  String get clientSessionDetailInfoDate => 'Date';

  @override
  String get clientSessionDetailInfoTime => 'Time';

  @override
  String get clientSessionDetailInfoDuration => 'Duration';

  @override
  String clientSessionDetailDurationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get clientSessionDetailInfoLocation => 'Location';

  @override
  String get clientSessionDetailLocationDefault =>
      'Location to be arranged with coach in messages';

  @override
  String get clientSessionDetailInfoPackage => 'Package';

  @override
  String get clientSessionDetailInfoRef => 'Ref.';

  @override
  String get clientSessionDetailCoachFallback => 'Coach';

  @override
  String get clientSessionDetailAnywhereFallback => 'Anywhere';

  @override
  String get clientSessionDetailNewCoach => 'New';

  @override
  String get clientSessionDetailBtnCancel => 'CANCEL';

  @override
  String get clientSessionDetailApprovalExpiredReason =>
      'The coach did not approve this booking before the one-hour deadline.';

  @override
  String get clientSessionDetailPriceNotAgreedReason =>
      'The price was not agreed before the two-hour deadline.';

  @override
  String get clientSessionDetailRequestExpiredTitle => 'Request expired';

  @override
  String get clientSessionDetailCancellationReasonTitle =>
      'Cancellation reason';

  @override
  String get clientSessionDetailShareReviewTitle => 'Share your review';

  @override
  String get clientSessionDetailShareReviewSubtitle =>
      'Help others choose the right coach';

  @override
  String get clientSessionDetailPublishedBadge => 'PUBLISHED';

  @override
  String get clientSessionDetailEditMyReview => 'Edit my review';

  @override
  String get clientSessionDetailCancelEditing => 'Cancel editing';

  @override
  String get clientSessionDetailCommentLabel => 'Comment';

  @override
  String get clientSessionDetailHowWasSession => 'How was your session?';

  @override
  String get clientSessionDetailReviewHint => 'Share the details... (optional)';

  @override
  String get clientSessionDetailUpdateMyReviewBtn => 'Update Review';

  @override
  String get clientSessionDetailPublishMyReviewBtn => 'Publish Review';

  @override
  String get clientSessionDetailRating1 => 'Needs improvement';

  @override
  String get clientSessionDetailRating2 => 'Okay';

  @override
  String get clientSessionDetailRating3 => 'Good';

  @override
  String get clientSessionDetailRating4 => 'Very good';

  @override
  String get clientSessionDetailRating5 => 'Excellent!';

  @override
  String get clientConversationDeletedMessage => 'This message was deleted';

  @override
  String get clientConversationSelectLimitError =>
      'Select up to 100 messages at a time.';

  @override
  String clientConversationDeleteDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count messages?',
      one: 'Delete 1 message?',
    );
    return '$_temp0';
  }

  @override
  String get clientConversationDeleteDialogContent =>
      'Delete for everyone is available for your own messages during the first 30 minutes.';

  @override
  String get clientConversationCancel => 'Cancel';

  @override
  String get clientConversationDeleteForMe => 'Delete for me';

  @override
  String get clientConversationDeleteForEveryone => 'Delete for everyone';

  @override
  String get clientConversationDeleteFailed => 'Could not delete messages.';

  @override
  String get clientConversationRefreshError =>
      'Could not refresh messages. Check your connection.';

  @override
  String get clientConversationSendRetryError =>
      'Could not send. Your message is ready to retry.';

  @override
  String get clientConversationAttachCamera => 'Camera';

  @override
  String get clientConversationAttachGallery => 'Gallery';

  @override
  String get clientConversationCaptionHint => 'Add a caption...';

  @override
  String get clientConversationSend => 'Send';

  @override
  String get clientConversationImageUploadFailed => 'Image upload failed';

  @override
  String get clientConversationSendPhotoError =>
      'Could not send the photo. Please try again.';

  @override
  String get clientConversationBatchLimitError =>
      'Choose up to 30 photos per batch.';

  @override
  String clientConversationBatchFailedError(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos could not be sent. The others were sent.',
      one: '1 photo could not be sent. The others were sent.',
    );
    return '$_temp0';
  }

  @override
  String get clientConversationAudioUploadFailed => 'Audio upload failed';

  @override
  String get clientConversationMicPermissionError =>
      'Allow microphone access for Sirvya in your phone Settings to record voice messages.';

  @override
  String get clientConversationAudioRecordError =>
      'Could not record or send audio. Please try again.';

  @override
  String get clientConversationMediaSendFailed =>
      'Failed to send media message';

  @override
  String get clientConversationNetworkError => 'Network error';

  @override
  String get clientConversationTitleFallback => 'Conversation';

  @override
  String get clientConversationSubtitleFallback => 'Fitness coach';

  @override
  String get clientConversationMenuSelect => 'Select messages';

  @override
  String get clientConversationMenuRefresh => 'Refresh messages';

  @override
  String get clientConversationMenuReport => 'Report Coach';

  @override
  String get clientConversationMenuBlock => 'Block Coach';

  @override
  String get clientConversationReportReasonSpam => 'Spam';

  @override
  String get clientConversationReportReasonHarassment => 'Harassment';

  @override
  String get clientConversationReportReasonInappropriate =>
      'Inappropriate content';

  @override
  String get clientConversationReportReasonFraud => 'Fraud / Scam';

  @override
  String get clientConversationReportReasonOther => 'Other';

  @override
  String get clientConversationThisCoachFallback => 'this coach';

  @override
  String clientConversationReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get clientConversationReportPrompt =>
      'Why are you reporting this user? We take these reports seriously.';

  @override
  String get clientConversationSubmit => 'Submit';

  @override
  String get clientConversationIdentifyCoachReportError =>
      'Unable to identify coach to report';

  @override
  String get clientConversationReportSubmitted =>
      'Report submitted successfully.';

  @override
  String get clientConversationReportFailed => 'Failed to submit report';

  @override
  String clientConversationBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get clientConversationBlockMessage =>
      'They won\'t be able to find your profile or send you messages. They will not be notified that you blocked them.';

  @override
  String get clientConversationBlockConfirm => 'Block';

  @override
  String get clientConversationIdentifyCoachBlockError =>
      'Unable to identify coach to block';

  @override
  String get clientConversationUserBlocked => 'User blocked.';

  @override
  String get clientConversationBlockFailed => 'Failed to block user';

  @override
  String get coachAccountBack => 'Back';

  @override
  String get coachAccountCancel => 'Cancel';

  @override
  String coachAccountCopiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get coachAccountDeleteCannotNow => 'Cannot delete account right now.';

  @override
  String get coachAccountDeleteCheckEmailSubtitle =>
      'Check your email for the 6-digit confirmation code.';

  @override
  String get coachAccountDeleteCodeExpired => 'Code expired.';

  @override
  String coachAccountDeleteCodeExpiresIn(String mins, String secs) {
    return 'Code expires in $mins:$secs';
  }

  @override
  String get coachAccountDeleteConfirmButton => 'Delete Account';

  @override
  String get coachAccountDeleteEnterCodeInstructions =>
      'Enter the code sent to your email to confirm deletion.';

  @override
  String get coachAccountDeleteItem1 =>
      'Your coach profile and public visibility';

  @override
  String get coachAccountDeleteItem2 =>
      'Your packages, photos and certifications';

  @override
  String get coachAccountDeleteItem3 =>
      'Your conversation history and client links';

  @override
  String get coachAccountDeleteItem4 =>
      'All active and past reservation records';

  @override
  String get coachAccountDeletePermanentSubtitle =>
      'This action is permanent and cannot be undone.';

  @override
  String get coachAccountDeleteResendCode => 'Resend code';

  @override
  String get coachAccountDeleteSendCodeButton => 'Send Verification Code';

  @override
  String get coachAccountDeleteSendCodeFailed =>
      'Failed to send code. Please try again.';

  @override
  String get coachAccountDeleteTitle => 'Delete Coach Account';

  @override
  String get coachAccountDeleteUnderstandCheckbox =>
      'I understand that deleting my account is permanent and irreversible.';

  @override
  String get coachAccountDeleteVerifyTitle => 'Verify Deletion';

  @override
  String get coachAccountDeleteWhatWillBeDeleted =>
      'The following data will be permanently removed:';

  @override
  String get coachAccountEnterFullCode => 'Please enter the full 6-digit code.';

  @override
  String get coachAccountServerUnreachable =>
      'Server unreachable. Please check your connection.';

  @override
  String get coachAccountThemeDark => 'Dark';

  @override
  String get coachAccountThemeLight => 'Light';

  @override
  String get coachAccountThemeSystem => 'System default';

  @override
  String get coachAccountVerificationFailed =>
      'Verification failed. Please try again.';

  @override
  String get coachCalendarActionAccept => 'Accept';

  @override
  String get coachCalendarActionAwaitingClient => 'Awaiting client response';

  @override
  String get coachCalendarActionCancelReservation => 'Cancel Reservation';

  @override
  String get coachCalendarActionProposePrice => 'Propose Price';

  @override
  String get coachCalendarActionReject => 'Decline';

  @override
  String get coachCalendarAddBlockedPeriod => 'Add Blocked Time';

  @override
  String get coachCalendarAwaitingYourPriceOffer => 'Awaiting your price offer';

  @override
  String get coachCalendarBlockHours => 'Block specific hours';

  @override
  String get coachCalendarBlockSpecificHoursSubtitle =>
      'Select the time interval you want to make unavailable.';

  @override
  String get coachCalendarBlockTheseHours => 'Block These Hours';

  @override
  String get coachCalendarBlockedPeriodsSubtitle =>
      'Times you marked as unavailable for clients.';

  @override
  String get coachCalendarBlockedPeriodsTitle => 'Blocked Periods';

  @override
  String get coachCalendarCancel => 'Cancel';

  @override
  String get coachCalendarCancelDialogTitle => 'Cancel Reservation';

  @override
  String get coachCalendarConfirm => 'Confirm';

  @override
  String coachCalendarDurationMinutes(int duration) {
    return '$duration min';
  }

  @override
  String get coachCalendarEnterReasonHint => 'Reason (optional)';

  @override
  String get coachCalendarFailed => 'Action failed. Please try again.';

  @override
  String get coachCalendarLegendBlocked => 'Blocked';

  @override
  String get coachCalendarLegendReservation => 'Reservation';

  @override
  String get coachCalendarLocationArranged => 'Location by agreement';

  @override
  String get coachCalendarLocationGym => 'Gym';

  @override
  String get coachCalendarLocationHome => 'Client\'s Home';

  @override
  String get coachCalendarNoBlockedPeriods =>
      'No blocked periods for this date.';

  @override
  String get coachCalendarNoReservationsThisDay =>
      'No reservations scheduled for this day.';

  @override
  String get coachCalendarNoteOptionalHint => 'Note (optional)';

  @override
  String coachCalendarPriceAwaitingClient(String price) {
    return '$price MAD proposed · Awaiting client';
  }

  @override
  String coachCalendarPricePerSession(String price) {
    return '$price MAD / session';
  }

  @override
  String get coachCalendarPricePerSessionLabel => 'Price per session (MAD)';

  @override
  String get coachCalendarProposePriceBody =>
      'Enter your proposed price for this session.';

  @override
  String get coachCalendarProposePriceTitle => 'Propose a Price';

  @override
  String get coachCalendarRejectDialogTitle => 'Decline Reservation';

  @override
  String get coachCalendarReservationDetailsTitle => 'Reservation Details';

  @override
  String coachCalendarReservationNumber(String id) {
    return 'Reservation #$id';
  }

  @override
  String get coachCalendarReservationUnavailable =>
      'Reservation information unavailable.';

  @override
  String get coachCalendarSendOffer => 'Send Offer';

  @override
  String get coachCalendarSendPriceError => 'Please enter a valid price.';

  @override
  String get coachCalendarSlotBooked => 'Slot booked';

  @override
  String get coachCalendarStatusCancelled => 'Cancelled';

  @override
  String get coachCalendarStatusConfirmed => 'Confirmed';

  @override
  String get coachCalendarStatusExpired => 'Expired';

  @override
  String get coachCalendarStatusPending => 'Pending';

  @override
  String get coachCalendarStatusPriceDeclined => 'Price declined';

  @override
  String get coachCalendarStatusPriceOffered => 'Price offered';

  @override
  String get coachCalendarTabAvailability => 'Availability';

  @override
  String get coachCalendarTabReservations => 'Reservations';

  @override
  String get coachCalendarTimeEnd => 'End Time';

  @override
  String get coachCalendarTimeStart => 'Start Time';

  @override
  String get coachCalendarTitle => 'Calendar';

  @override
  String coachCalendarWorkingHours(int start, int end) {
    return 'Working Hours: $start:00 – $end:00';
  }

  @override
  String get coachDashboardActivitySubtitle =>
      'Here is your coaching activity overview.';

  @override
  String coachDashboardAgreedPrices(String period) {
    return 'Agreed prices ($period)';
  }

  @override
  String get coachDashboardClientFallback => 'Client';

  @override
  String get coachDashboardCoachFallback => 'Coach';

  @override
  String coachDashboardDaysAgoLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardDaysAgoShort(int days) {
    return '${days}d ago';
  }

  @override
  String get coachDashboardFilterThisMonth => 'This Month';

  @override
  String get coachDashboardFilterThisWeek => 'This Week';

  @override
  String get coachDashboardFilterToday => 'Today';

  @override
  String get coachDashboardGoodMorning => 'Good morning';

  @override
  String coachDashboardHoursAgoLong(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardHoursAgoShort(int hours) {
    return '${hours}h ago';
  }

  @override
  String get coachDashboardInvitationPoints => 'Invitation Points';

  @override
  String get coachDashboardInvitations => 'Invitations';

  @override
  String coachDashboardInvitationsThisWeek(int count) {
    return '$count this week';
  }

  @override
  String get coachDashboardJustNow => 'Just now';

  @override
  String get coachDashboardLoadErrorSubtitle =>
      'Unable to load dashboard data. Check your connection.';

  @override
  String get coachDashboardLoadErrorTitle => 'Could Not Load Dashboard';

  @override
  String coachDashboardMinutesAgoLong(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardMinutesAgoShort(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get coachDashboardNoNotificationsSubtitle =>
      'Updates and reminders will show up here.';

  @override
  String get coachDashboardNoNotificationsTitle => 'No Notifications';

  @override
  String get coachDashboardNoUpcomingReservationsSubtitle =>
      'Upcoming bookings will appear here.';

  @override
  String get coachDashboardNoUpcomingReservationsTitle =>
      'No Upcoming Sessions';

  @override
  String get coachDashboardNotificationFallback => 'Notification';

  @override
  String get coachDashboardNotificationsTitle => 'Notifications';

  @override
  String coachDashboardPeriodClients(int count, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients ($period)',
      one: '1 client ($period)',
    );
    return '$_temp0';
  }

  @override
  String get coachDashboardPeriodThisMonth => 'this month';

  @override
  String get coachDashboardPeriodThisWeek => 'this week';

  @override
  String get coachDashboardPeriodToday => 'today';

  @override
  String get coachDashboardRecentReservations => 'Recent Reservations';

  @override
  String get coachDashboardRetry => 'Retry';

  @override
  String get coachDashboardSetYourAvailability => 'Set Your Availability';

  @override
  String get coachDashboardStatClients => 'Clients';

  @override
  String get coachDashboardStatReservations => 'Reservations';

  @override
  String get coachDashboardStatRevenue => 'Revenue (MAD)';

  @override
  String coachDashboardTierLabel(int tier) {
    return 'Tier: $tier';
  }

  @override
  String get coachDashboardTitle => 'Dashboard';

  @override
  String get coachDashboardTotalClients => 'Total Clients';

  @override
  String get coachDashboardUpcomingReservations => 'Upcoming Sessions';

  @override
  String get coachDashboardViewAll => 'View all';

  @override
  String coachDashboardWantsToConnect(String timeAgo) {
    return 'Wants to connect · $timeAgo';
  }

  @override
  String get coachEditProfileAdd => 'Add';

  @override
  String get coachEditProfileAddCertificationButton => 'Add Certification';

  @override
  String get coachEditProfileAddCertificationHint =>
      'e.g., NASM Certified Personal Trainer';

  @override
  String get coachEditProfileAddCertificationTitle => 'Add Certification';

  @override
  String get coachEditProfileAddGalleryImageButton => 'Add Photo';

  @override
  String get coachEditProfileAddPackageButton => 'Add Package';

  @override
  String get coachEditProfileAddSpecialtyButton => 'Add Specialty';

  @override
  String get coachEditProfileAddSpecialtyHint => 'Select or type specialty';

  @override
  String get coachEditProfileAddSpecialtyTitle => 'Add Specialty';

  @override
  String get coachEditProfileBioHint =>
      'Share your coaching philosophy, experience, and what clients can expect.';

  @override
  String get coachEditProfileBioLabel => 'Biography';

  @override
  String get coachEditProfileBioTitle => 'About You';

  @override
  String get coachEditProfileCancel => 'Cancel';

  @override
  String get coachEditProfileCertificationsSubtitle =>
      'Showcase your degrees and certifications.';

  @override
  String get coachEditProfileCertificationsTitle => 'Certifications';

  @override
  String get coachEditProfileCityHint => 'e.g., Casablanca';

  @override
  String get coachEditProfileCityLabel => 'City';

  @override
  String coachEditProfileDeletePackageConfirm(String name) {
    return 'Delete package \"$name\"?';
  }

  @override
  String get coachEditProfileDeletePackageTitle => 'Delete Package';

  @override
  String get coachEditProfileDeletePhotoConfirm =>
      'Remove this photo from your gallery?';

  @override
  String get coachEditProfileDeletePhotoTitle => 'Remove Photo';

  @override
  String get coachEditProfileExperienceHint => 'e.g., 5 years';

  @override
  String get coachEditProfileExperienceLabel => 'Experience';

  @override
  String get coachEditProfileGallerySubtitle =>
      'High quality photos build client confidence.';

  @override
  String get coachEditProfileGalleryTitle => 'Photo Gallery';

  @override
  String get coachEditProfileHourlyRateHint => 'e.g., 300';

  @override
  String get coachEditProfileHourlyRateLabel => 'Hourly Rate (MAD)';

  @override
  String get coachEditProfileInstagramHint => 'e.g., coach_fitness';

  @override
  String get coachEditProfileInstagramLabel => 'Instagram';

  @override
  String coachEditProfilePackageSessionsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get coachEditProfilePackagesSubtitle =>
      'Offer multi-session discounts or specialized packs.';

  @override
  String get coachEditProfilePackagesTitle => 'Coaching Packages';

  @override
  String get coachEditProfilePersonalInfoTitle => 'Personal Information';

  @override
  String get coachEditProfilePhoneLabel => 'Phone Number';

  @override
  String get coachEditProfileProfessionalTitle => 'Professional Title';

  @override
  String get coachEditProfileProfessionalTitleHint =>
      'e.g., Strength & Conditioning Coach';

  @override
  String get coachEditProfileSave => 'Save';

  @override
  String get coachEditProfileSaveSuccess => 'Profile updated successfully.';

  @override
  String get coachEditProfileSaving => 'Saving…';

  @override
  String get coachEditProfileSpecialtiesSubtitle =>
      'Help clients find you by your areas of expertise.';

  @override
  String get coachEditProfileSpecialtiesTitle => 'Specialties';

  @override
  String get coachEditProfileTitle => 'Edit Profile';

  @override
  String get coachProfileAboutConfigured => 'Biography configured';

  @override
  String get coachProfileAboutDefault => 'No biography added yet.';

  @override
  String get coachProfileCancel => 'Cancel';

  @override
  String get coachProfileCoachFallback => 'Coach';

  @override
  String get coachProfileCompletedSnack => 'Profile completed!';

  @override
  String get coachProfileEditProfile => 'Edit Profile';

  @override
  String coachProfileInfoExperience(String exp) {
    return 'Experience: $exp';
  }

  @override
  String coachProfileInfoLanguages(String lang) {
    return 'Languages: $lang';
  }

  @override
  String get coachProfileInfoLocation => 'Location';

  @override
  String get coachProfileInfoProfessionalTitle => 'Title';

  @override
  String get coachProfileInfoSpecialties => 'Specialties';

  @override
  String get coachProfileLoadError => 'Could not load coach profile.';

  @override
  String get coachProfileLoading => 'Loading profile…';

  @override
  String get coachProfileLocationNotSet => 'Location not set';

  @override
  String get coachProfileLogOutConfirmMessage =>
      'Are you sure you want to log out?';

  @override
  String get coachProfileLogOutTitle => 'Log Out';

  @override
  String get coachProfileMenuAboutYou => 'About You';

  @override
  String get coachProfileMenuAccount => 'Account Settings';

  @override
  String get coachProfileMenuExpertise => 'Expertise & Specialties';

  @override
  String get coachProfileMenuFeedback => 'My feedback';

  @override
  String get coachProfileMenuFeedbackSubtitle => 'Client reviews and ratings';

  @override
  String get coachProfileMenuLocations => 'Coaching Locations';

  @override
  String get coachProfileMenuLocationsSubtitle =>
      'Manage gyms and training areas';

  @override
  String get coachProfileMenuPackages => 'Packages & Pricing';

  @override
  String get coachProfileMenuPackagesSubtitle => 'Set your session rates';

  @override
  String get coachProfileMenuPhotos => 'Photo Gallery';

  @override
  String get coachProfileMenuVisibility => 'Profile Visibility';

  @override
  String get coachProfileNotSet => 'Not specified';

  @override
  String get coachProfilePersonalTrainerFallback => 'Personal Trainer';

  @override
  String get coachProfilePhotoUpdated => 'Profile photo updated.';

  @override
  String coachProfilePhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get coachProfilePreviewProfile => 'Preview Public Profile';

  @override
  String get coachProfileProfessionalInfoEmpty =>
      'No professional info provided.';

  @override
  String get coachProfileProfessionalInformationSection =>
      'Professional Details';

  @override
  String get coachProfilePublicProfileBadge => 'Public';

  @override
  String get coachProfileRetry => 'Retry';

  @override
  String get coachProfileSaveError => 'Failed to save profile.';

  @override
  String get coachProfileStatBookings => 'Bookings';

  @override
  String get coachProfileStatClients => 'Clients';

  @override
  String get coachProfileStatPoints => 'Points';

  @override
  String get coachProfileStepAvatar => 'Add a profile photo to your profile.';

  @override
  String get coachProfileStepBio => 'Add your biography to your profile.';

  @override
  String get coachProfileStepCertifications =>
      'Add certifications to your profile.';

  @override
  String get coachProfileStepCity => 'Add your city to your profile.';

  @override
  String get coachProfileStepClientLevels => 'Specify accepted client levels.';

  @override
  String get coachProfileStepCoachingFormats => 'Choose coaching formats.';

  @override
  String get coachProfileStepEmail => 'Add your email to your profile.';

  @override
  String get coachProfileStepExperience =>
      'Add your experience to your profile.';

  @override
  String get coachProfileStepFirstName =>
      'Add your first name to your profile.';

  @override
  String get coachProfileStepGallery => 'Add photos to your gallery.';

  @override
  String get coachProfileStepGender => 'Specify your gender.';

  @override
  String get coachProfileStepGymAddress => 'Add gym location.';

  @override
  String get coachProfileStepGymImage => 'Add a gym photo.';

  @override
  String get coachProfileStepGymName => 'Add your gym name.';

  @override
  String get coachProfileStepInstagram => 'Add your Instagram handle.';

  @override
  String get coachProfileStepLanguages => 'Add spoken languages.';

  @override
  String get coachProfileStepLastName => 'Add your last name.';

  @override
  String get coachProfileStepPackage => 'Add a coaching package.';

  @override
  String get coachProfileStepPhone => 'Add your phone number.';

  @override
  String get coachProfileStepProfessionalTitle =>
      'Add your professional title.';

  @override
  String get coachProfileStepServiceArea => 'Set your coaching zone.';

  @override
  String get coachProfileStepSpecialties => 'Select your specialties.';

  @override
  String get coachProfileTitle => 'Coach Profile';

  @override
  String get coachProfileUploadFailed => 'Failed to upload photo.';

  @override
  String get coachClientDetailDisconnectInviteTitle => 'Disconnect invitation';

  @override
  String coachClientDetailDisconnectInviteMessage(String name) {
    return 'Disconnect your invitation with $name? Clients with bookings remain visible so you can manage their sessions. Their account and sessions are kept.';
  }

  @override
  String get coachClientDetailCancel => 'Cancel';

  @override
  String get coachClientDetailDisconnect => 'Disconnect';

  @override
  String get coachClientDetailTitle => 'Client';

  @override
  String get coachClientDetailLoadError => 'Unable to load client';

  @override
  String get coachClientDetailRetry => 'Retry';

  @override
  String get coachClientDetailNoSessions => 'No sessions yet';

  @override
  String get coachClientDetailReport => 'Report Client';

  @override
  String get coachClientDetailBlock => 'Block Client';

  @override
  String coachClientDetailReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get coachClientDetailReportSubtitle =>
      'Why are you reporting this user? We take these reports seriously.';

  @override
  String get coachClientDetailSubmit => 'Submit';

  @override
  String coachClientDetailBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get coachClientDetailBlockMessage =>
      'They will not be able to book sessions or message you again.';

  @override
  String get coachClientDetailBlockConfirm => 'Block';

  @override
  String get coachDashboardStatConfirmed => 'Confirmed';

  @override
  String get coachDashboardStatConfirmedValue => 'Confirmed Sessions';

  @override
  String get coachDashboardStatPending => 'Pending';

  @override
  String coachDashboardStatusAcceptedPoints(String points) {
    return '+$points pts';
  }

  @override
  String get coachDashboardStatusCancelled => 'Cancelled';

  @override
  String get coachDashboardStatusConfirmed => 'Confirmed';

  @override
  String get coachDashboardStatusDeclined => 'Declined';

  @override
  String get coachDashboardStatusPending => 'Pending';

  @override
  String get coachDashboardStatusUnknown => 'Unknown';

  @override
  String coachDashboardTierProgress(int progress, int nextTier, int remaining) {
    return '$progress% to $nextTier · $remaining pts left';
  }

  @override
  String get coachDashboardTomorrow => 'Tomorrow';

  @override
  String get coachDashboardYesterday => 'Yesterday';

  @override
  String get coachProfileCompletionTitle => 'Profile Completion';

  @override
  String get coachProfileGalleryPreview => 'Gallery Preview';

  @override
  String get coachProfileInfoBio => 'Biography';

  @override
  String get coachProfileInfoCertifications => 'Certifications';

  @override
  String get coachEditProfileAddOtherSpecialty => '+ Add custom specialty';

  @override
  String get coachEditProfileAddPackageTitle => 'Add New Package';

  @override
  String get coachEditProfileBioRequired => 'Biography is required.';

  @override
  String get coachEditProfileCertificationExists =>
      'This certification is already added.';

  @override
  String get coachEditProfileCustomSpecialties => 'Custom Specialties';

  @override
  String get coachEditProfileDelete => 'Delete';

  @override
  String get coachEditProfileDirectMessagingSubtitle =>
      'Allow prospective clients to contact you before booking.';

  @override
  String get coachEditProfileDirectMessagingTitle => 'Direct Messaging';

  @override
  String get coachEditProfileEditPackageTitle => 'Edit Package';

  @override
  String get coachEditProfileEmailHint => 'your.email@example.com';

  @override
  String get coachEditProfileEmailInvalid =>
      'Please enter a valid email address.';

  @override
  String get coachEditProfileEmailLabel => 'Email Address';

  @override
  String get coachEditProfileEmailRequired => 'Email address is required.';

  @override
  String get coachEditProfileEnterFullName => 'Please enter your full name.';

  @override
  String get coachEditProfileFullNameLabel => 'Full Name';

  @override
  String get coachEditProfileFullNameValidator =>
      'Please enter your full name.';

  @override
  String get coachEditProfileGalleryAdded => 'Photo added to gallery.';

  @override
  String get coachEditProfileGalleryEmpty => 'No photos in your gallery yet.';

  @override
  String get coachEditProfileGalleryMaxImages =>
      'Maximum 12 gallery photos allowed.';

  @override
  String get coachEditProfileGenderFemale => 'Female';

  @override
  String get coachEditProfileGenderLabel => 'Gender';

  @override
  String get coachEditProfileGenderMale => 'Male';

  @override
  String get coachEditProfileGenderOther => 'Other';

  @override
  String get coachEditProfileGenericError =>
      'Something went wrong. Please try again.';

  @override
  String get coachEditProfileImageDeleted => 'Photo removed from gallery.';

  @override
  String get coachEditProfileMaxCertifications =>
      'Maximum 10 certifications allowed.';

  @override
  String get coachEditProfileMaxPackagesReached =>
      'Maximum packages limit reached.';

  @override
  String get coachEditProfileMaxSpecialties => 'Maximum 8 specialties allowed.';

  @override
  String get coachEditProfileNoCertifications => 'No certifications added yet.';

  @override
  String get coachEditProfilePackageAdded => 'Package created successfully.';

  @override
  String get coachEditProfilePackageDeleted => 'Package deleted.';

  @override
  String get coachEditProfilePackageDescriptionHint =>
      'Describe what is included in this package...';

  @override
  String get coachEditProfilePackageDescriptionLabel => 'Package Description';

  @override
  String get coachEditProfilePackageHidden => 'Hidden from clients';

  @override
  String get coachEditProfilePackageNameHint => 'e.g., 10-Session Kickstart';

  @override
  String get coachEditProfilePackageNameLabel => 'Package Name';

  @override
  String get coachEditProfilePackageNameRequired => 'Package name is required.';

  @override
  String get coachEditProfilePackageSessionsHint => 'Number of sessions';

  @override
  String get coachEditProfilePackageSessionsLabel => 'Included Sessions';

  @override
  String get coachEditProfilePackageSetPriceSubtitle =>
      'Clients will see this price when booking.';

  @override
  String get coachEditProfilePackageSetPriceTitle => 'Session Price';

  @override
  String get coachEditProfilePackageUpdated => 'Package updated successfully.';

  @override
  String get coachEditProfilePackageVisibleToClients =>
      'Visible to clients on your profile';

  @override
  String get coachEditProfilePackagesDescription =>
      'Manage the packs and session offers displayed on your public profile.';

  @override
  String get coachEditProfilePhoneHint => '+212 6XX XXX XXX';

  @override
  String get coachEditProfilePhotoReady => 'Photo ready to save.';

  @override
  String get coachEditProfilePriceOnRequest => 'Price on request';

  @override
  String get coachEditProfileProfessionalTitleLabel => 'Professional Title';

  @override
  String get coachEditProfilePublicProfileSubtitle =>
      'Allow clients to discover your profile in search results.';

  @override
  String get coachEditProfilePublicProfileTitle => 'Public Profile';

  @override
  String get coachEditProfileSaveChangesButton => 'Save changes';

  @override
  String get coachEditProfileSectionAccountSettings => 'Account Settings';

  @override
  String get coachEditProfileSectionBasicInfo => 'Basic Information';

  @override
  String get coachEditProfileSectionCertifications =>
      'Certifications & Credentials';

  @override
  String get coachEditProfileSectionContactLocation => 'Contact & Location';

  @override
  String get coachEditProfileSectionGallery => 'Photo Gallery';

  @override
  String get coachEditProfileSectionPackages => 'Packages & Pricing';

  @override
  String get coachEditProfileSectionSpecialties => 'Coaching Specialties';

  @override
  String get coachEditProfileSpecialtiesDescription =>
      'Select the training areas you specialize in to match with the right clients.';

  @override
  String get coachEditProfileSpecialtyExists =>
      'This specialty is already added.';

  @override
  String get coachEditProfileSubtitle =>
      'Keep your coaching info updated to attract more clients.';

  @override
  String get coachEditProfileUpdate => 'Update';

  @override
  String get coachEditProfileUpdateError => 'Failed to update profile.';

  @override
  String get coachEditProfileUpdatedSnack => 'Profile updated successfully.';

  @override
  String get coachEditProfileUploadFailed => 'Failed to upload photo.';

  @override
  String coachDashboardPercentOfTotal(String percent) {
    return '$percent% of total';
  }

  @override
  String get coachDashboardVerificationPendingTitle =>
      'Verification in Progress';

  @override
  String get coachDashboardVerificationPendingBody =>
      'Your credentials are being reviewed by the SIRVYA team.';

  @override
  String coachEditProfileErrorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String coachEditProfileGalleryLimitWarning(int max) {
    return 'You can only add up to $max photos.';
  }

  @override
  String coachEditProfileUploadFailedForFile(String file) {
    return 'Failed to upload $file';
  }

  @override
  String get coachEditProfileImageDeleteFailed => 'Failed to remove image.';

  @override
  String coachEditProfileNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String coachProfileErrorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String get coachCalendarBlockAction => 'Block';

  @override
  String get coachAccountTitle => 'Account & referrals';

  @override
  String get coachAccountReferralTitle => 'Coach Referral';

  @override
  String get coachAccountReferralSubtitle => 'Invite friends and earn rewards';

  @override
  String get coachAccountCopy => 'Copy';

  @override
  String get coachAccountCode => 'Code';

  @override
  String get coachAccountScanToInvite => 'Scan to invite';

  @override
  String get coachAccountCopyCode => 'Copy code';

  @override
  String coachAccountReferralRewardDesc(int points) {
    return 'Earn $points bonus points for every professional coach you onboard to the SIRVYA ecosystem.';
  }

  @override
  String get coachAccountPrivateAccount => 'Private account';

  @override
  String get coachAccountEmail => 'Email';

  @override
  String get coachAccountChangeEmailSubtitle =>
      'Change email with verification.';

  @override
  String get coachAccountEmailUpdated => 'Email updated successfully';

  @override
  String get coachAccountPhone => 'Phone';

  @override
  String get coachAccountPhoneUpdated => 'Phone updated successfully';

  @override
  String get coachAccountPasswordSecurity => 'Password & security';

  @override
  String get coachAccountPasswordUpdated => 'Password updated successfully';

  @override
  String get coachAccountAppearance => 'Appearance';

  @override
  String get coachAccountChooseAppTheme => 'Choose the app theme';

  @override
  String get coachAccountNotifications => 'Notifications';

  @override
  String get coachAccountBlockedUsers => 'Blocked Users';

  @override
  String get coachAccountDeleteAccount => 'Delete Account';

  @override
  String get coachChatAudioRecordError =>
      'Could not record voice note. Check permissions.';

  @override
  String get coachChatAudioUploadFailed => 'Failed to send audio message.';

  @override
  String coachChatBatchPartialFail(int failed) {
    return '$failed images could not be sent.';
  }

  @override
  String get coachChatBlock => 'Block';

  @override
  String get coachChatBlockClient => 'Block Client';

  @override
  String get coachChatBlockContent =>
      'Are you sure you want to block this client? They will not be able to message you or book sessions.';

  @override
  String get coachChatBlockFailed => 'Failed to block client.';

  @override
  String get coachChatBlockIdentifyError =>
      'Could not identify client to block.';

  @override
  String get coachChatBlockSuccess => 'Client blocked successfully.';

  @override
  String coachChatBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get coachChatCamera => 'Camera';

  @override
  String get coachChatCancel => 'Cancel';

  @override
  String get coachChatCaptionHint => 'Add a caption...';

  @override
  String get coachChatDeleteFailed => 'Failed to delete message.';

  @override
  String get coachChatDeleteForEveryone => 'Delete for everyone';

  @override
  String get coachChatDeleteForMe => 'Delete for me';

  @override
  String get coachChatDeleteMessagesContent => 'Delete selected messages?';

  @override
  String coachChatDeleteMessagesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return 'Delete $_temp0?';
  }

  @override
  String get coachChatGallery => 'Gallery';

  @override
  String get coachChatHeaderSubtitle => 'Active client';

  @override
  String get coachChatImageUploadFailed => 'Failed to upload image.';

  @override
  String get coachChatMaxBatchPhotos => 'Maximum 10 photos per message.';

  @override
  String get coachChatMaxSelection => 'Maximum 20 messages can be selected.';

  @override
  String get coachChatMicrophonePermission =>
      'Microphone access is required to record voice notes.';

  @override
  String get coachChatNetworkError => 'Network error. Please try again.';

  @override
  String get coachChatPhotoSendError => 'Could not send photo.';

  @override
  String get coachChatReasonFraud => 'Fraud or scam';

  @override
  String get coachChatReasonHarassment => 'Harassment or abuse';

  @override
  String get coachChatReasonInappropriate => 'Inappropriate content';

  @override
  String get coachChatReasonOther => 'Other reason';

  @override
  String get coachChatReasonSpam => 'Spam or advertising';

  @override
  String get coachChatRefreshError => 'Could not refresh messages.';

  @override
  String get coachChatRefreshMessages => 'Refresh messages';

  @override
  String get coachChatReportClient => 'Report Client';

  @override
  String get coachChatReportFailed => 'Failed to submit report.';

  @override
  String get coachChatReportIdentifyError =>
      'Could not identify client to report.';

  @override
  String get coachChatReportPrompt =>
      'Select a reason for reporting this user:';

  @override
  String get coachChatReportSuccess =>
      'Report submitted. Thank you for keeping SIRVYA safe.';

  @override
  String coachChatReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get coachChatSelectMessages => 'Select messages';

  @override
  String get coachChatSend => 'Send';

  @override
  String get coachChatSendFailed => 'Failed to send message.';

  @override
  String get coachChatSubmit => 'Submit';

  @override
  String get coachChatThisClient => 'this client';

  @override
  String get coachExpertiseAdd => 'Add';

  @override
  String get coachExpertiseAddCertTitle => 'Add Certification';

  @override
  String get coachExpertiseAddSpecialtyTitle => 'Add Specialty';

  @override
  String get coachExpertiseAttachedDocument => 'Document attached';

  @override
  String get coachExpertiseCancel => 'Cancel';

  @override
  String get coachExpertiseCertDetailsTitle => 'Certification Details';

  @override
  String get coachExpertiseCertNameHint => 'Certification Name';

  @override
  String get coachExpertiseCertProviderHint => 'Issuing Organization';

  @override
  String get coachExpertiseCertYearHint => 'Year Obtained';

  @override
  String get coachExpertiseCertificationsSubtitle =>
      'Display your verified credentials to clients.';

  @override
  String get coachExpertiseCertificationsTitle => 'Certifications';

  @override
  String get coachExpertiseCoachingSince => 'Coaching since';

  @override
  String get coachExpertiseDetailName => 'Name';

  @override
  String get coachExpertiseDetailProvider => 'Organization';

  @override
  String get coachExpertiseDetailYear => 'Year';

  @override
  String coachExpertiseErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get coachExpertiseExperienceSubtitle =>
      'Your total coaching and training experience.';

  @override
  String get coachExpertiseExperienceTitle => 'Experience';

  @override
  String coachExpertiseExperienceYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get coachExpertiseFileAttached => 'File attached';

  @override
  String get coachExpertiseLevelsSubtitle =>
      'Experience levels of clients you work with.';

  @override
  String get coachExpertiseLevelsTitle => 'Client Levels';

  @override
  String get coachExpertiseNoCerts => 'No certifications added yet.';

  @override
  String get coachExpertiseNoSpecialties => 'No specialties selected yet.';

  @override
  String get coachExpertiseRetry => 'Retry';

  @override
  String get coachExpertiseSave => 'Save';

  @override
  String get coachExpertiseSaveSuccess => 'Expertise updated successfully.';

  @override
  String get coachExpertiseSaving => 'Saving…';

  @override
  String get coachExpertiseSelectDoc => 'Upload certificate document';

  @override
  String get coachExpertiseSpecialtiesSubtitle =>
      'Select areas of training you specialize in.';

  @override
  String get coachExpertiseSpecialtiesTitle => 'Specialties';

  @override
  String get coachExpertiseTitle => 'Expertise & Credentials';

  @override
  String get coachExpertiseUploadFailed => 'Failed to upload document.';

  @override
  String get coachExpertiseYearsLabel => 'Years of Experience';

  @override
  String get coachLocationsAddressHint => 'Street address or landmark';

  @override
  String get coachLocationsAddressLabel => 'Address';

  @override
  String get coachLocationsCancel => 'Cancel';

  @override
  String get coachLocationsCityTitle => 'Primary City';

  @override
  String get coachLocationsDetectCityHint => 'Tap to detect your city';

  @override
  String get coachLocationsEditGymDialogTitle => 'Edit Gym Location';

  @override
  String get coachLocationsEditLocation => 'Edit Location';

  @override
  String get coachLocationsFormatGym => 'At the Gym';

  @override
  String get coachLocationsFormatHome => 'At Client\'s Home';

  @override
  String get coachLocationsFormatOnline => 'Online Coaching';

  @override
  String get coachLocationsFormatsSubtitle =>
      'Where do you provide your coaching sessions?';

  @override
  String get coachLocationsFormatsTitle => 'Coaching Formats';

  @override
  String get coachLocationsGymAddressHint => 'Gym address';

  @override
  String get coachLocationsGymAddressLabel => 'Gym Address';

  @override
  String get coachLocationsGymNameHint => 'e.g., City Club';

  @override
  String get coachLocationsGymNameLabel => 'Gym Name';

  @override
  String get coachLocationsGymSubtitle =>
      'Your primary affiliated gym or studio.';

  @override
  String get coachLocationsGymTitle => 'Partner Gym';

  @override
  String get coachLocationsRadiusHint => 'Service radius (km)';

  @override
  String get coachLocationsRadiusLabel => 'Travel Radius (km)';

  @override
  String get coachLocationsSave => 'Save Locations';

  @override
  String get coachLocationsSaveSuccess => 'Locations updated successfully.';

  @override
  String get coachLocationsSaving => 'Saving…';

  @override
  String get coachLocationsTitle => 'Coaching Locations';

  @override
  String get coachPackagesAddPackage => 'Add Package';

  @override
  String get coachPackagesAgreeOnPrice => 'Price agreed with client';

  @override
  String get coachPackagesCancel => 'Cancel';

  @override
  String get coachPackagesDelete => 'Delete';

  @override
  String get coachPackagesDeleteContent =>
      'Are you sure you want to delete this package?';

  @override
  String get coachPackagesDeleteError => 'Failed to delete package.';

  @override
  String get coachPackagesDeleteTitle => 'Delete Package';

  @override
  String get coachPackagesDeleted => 'Package deleted.';

  @override
  String get coachPackagesDurationLabel => 'Duration';

  @override
  String get coachPackagesEdit => 'Edit';

  @override
  String get coachPackagesEditPackage => 'Edit Package';

  @override
  String get coachPackagesEmptySubtitle =>
      'Create packs to encourage repeat sessions and long-term commitment.';

  @override
  String get coachPackagesEmptyTitle => 'No Packages Yet';

  @override
  String get coachPackagesNameHint => 'e.g., 10-Session Transformation Pack';

  @override
  String get coachPackagesNameLabel => 'Package Name';

  @override
  String get coachPackagesPriceHint => 'Price in MAD';

  @override
  String get coachPackagesPriceLabel => 'Price (MAD)';

  @override
  String coachPackagesProgress(int current, int max) {
    return '$current of $max packages';
  }

  @override
  String get coachPackagesSave => 'Save Package';

  @override
  String get coachPackagesSaveError => 'Failed to save package.';

  @override
  String get coachPackagesSaved => 'Package saved successfully.';

  @override
  String get coachPackagesSaving => 'Saving…';

  @override
  String coachPackagesSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get coachPackagesSessionsHint => 'Number of sessions included';

  @override
  String get coachPackagesSessionsLabel => 'Sessions Included';

  @override
  String get coachPackagesTitle => 'Packages & Rates';

  @override
  String get coachPhotosAddPhoto => 'Add Photo';

  @override
  String get coachPhotosAddressHint => 'Gym address';

  @override
  String get coachPhotosAddressLabel => 'Address';

  @override
  String get coachPhotosCancel => 'Cancel';

  @override
  String get coachPhotosCaptionHint => 'Caption (optional)';

  @override
  String get coachPhotosCaptionTitle => 'Photo Caption';

  @override
  String get coachPhotosCover => 'Cover';

  @override
  String get coachPhotosDelete => 'Delete';

  @override
  String get coachPhotosEditCaption => 'Edit Caption';

  @override
  String get coachPhotosEditGymDialogTitle => 'Edit Gym Photo';

  @override
  String coachPhotosErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get coachPhotosGallerySubtitle =>
      'Show your coaching environment and workouts.';

  @override
  String get coachPhotosGalleryTitle => 'Gallery Photos';

  @override
  String get coachPhotosGymTitle => 'Gym / Studio Photos';

  @override
  String get coachPhotosNoPhotos => 'No photos in your gallery yet.';

  @override
  String coachPhotosPartialSlots(int slots) {
    return '$slots slots remaining in gallery.';
  }

  @override
  String coachPhotosSaveFailed(String error) {
    return 'Failed to save photo: $error';
  }

  @override
  String get coachPhotosSaveSuccess => 'Photos updated successfully.';

  @override
  String get coachPhotosSaving => 'Saving…';

  @override
  String get coachPhotosTitle => 'Coaching Photos';

  @override
  String get coachPhotosUploadFailed => 'Failed to upload photo.';

  @override
  String get mealScannerAddFoodItem => 'Add food item';

  @override
  String get mealScannerAddToMeal => 'Add to meal';

  @override
  String get mealScannerAdjustPortion => 'Adjust portion';

  @override
  String get mealScannerApply => 'Apply';

  @override
  String get mealScannerCalculatedNutrition => 'Calculated Nutrition';

  @override
  String get mealScannerCaloriesKcalLabel => 'Calories (kcal)';

  @override
  String get mealScannerCarbsGLabel => 'Carbs (g)';

  @override
  String get mealScannerCategoryAll => 'All';

  @override
  String get mealScannerCategoryDairy => 'Dairy & Eggs';

  @override
  String get mealScannerCategoryDrinks => 'Drinks';

  @override
  String get mealScannerCategoryFish => 'Fish & Seafood';

  @override
  String get mealScannerCategoryGrains => 'Grains & Bread';

  @override
  String get mealScannerCategoryMeals => 'Prepared Meals';

  @override
  String get mealScannerCategoryMeat => 'Meat & Poultry';

  @override
  String get mealScannerCategoryNuts => 'Nuts & Seeds';

  @override
  String get mealScannerCategoryProduce => 'Fruits & Veggies';

  @override
  String get mealScannerCategorySnacks => 'Snacks & Sweets';

  @override
  String get mealScannerChangesNotSynced =>
      'Changes saved locally · Not synced yet';

  @override
  String get mealScannerChooseCategoryHint => 'Choose food category';

  @override
  String get mealScannerChooseDifferentFood => 'Choose a different food';

  @override
  String get mealScannerCustomFoodDefaultName => 'Custom Food';

  @override
  String get mealScannerCustomFoodNameLabel => 'Food Name';

  @override
  String get mealScannerCustomItemFallback => 'Item';

  @override
  String get mealScannerDeleteMeal => 'Delete meal';

  @override
  String get mealScannerEditMacrosManually => 'Edit macros manually';

  @override
  String get mealScannerEnterFoodNameError => 'Please enter a food name.';

  @override
  String get mealScannerEnterValidWeightError =>
      'Please enter a valid weight in grams.';

  @override
  String get mealScannerFatGLabel => 'Fat (g)';

  @override
  String mealScannerFoodMacrosPer100g(
      int calories, String protein, String carbs, String fat) {
    return '$calories kcal · P ${protein}g · C ${carbs}g · F ${fat}g';
  }

  @override
  String get mealScannerFoodNameLabel => 'Food Name';

  @override
  String get mealScannerMacroCarbs => 'Carbs';

  @override
  String get mealScannerMacroFat => 'Fat';

  @override
  String get mealScannerMacroProtein => 'Protein';

  @override
  String get mealScannerManualValuesActive => 'Manual values active';

  @override
  String get mealScannerMealBreakfast => 'Breakfast';

  @override
  String mealScannerMealDate(String date) {
    return 'Meal date: $date';
  }

  @override
  String get mealScannerMealDinner => 'Dinner';

  @override
  String get mealScannerMealLunch => 'Lunch';

  @override
  String mealScannerMealMovedTo(String meal) {
    return 'Meal moved to $meal';
  }

  @override
  String mealScannerMealSavedTo(String meal) {
    return 'Meal saved to $meal';
  }

  @override
  String get mealScannerMealSnack => 'Snack';

  @override
  String get mealScannerMoveMeal => 'Move meal';

  @override
  String mealScannerNoFoodsFound(String query) {
    return 'No food found for \"$query\"';
  }

  @override
  String mealScannerNotSynced(String meal) {
    return 'Not synced ($meal)';
  }

  @override
  String get mealScannerOneServing => '1 serving';

  @override
  String get mealScannerOnlineBadge => 'Online';

  @override
  String get mealScannerOrEnterCustomMacros => 'Or enter custom macros';

  @override
  String get mealScannerProteinGLabel => 'Protein (g)';

  @override
  String mealScannerQuantityLabel(String unit) {
    return 'Quantity ($unit)';
  }

  @override
  String get mealScannerQueryingGlobalDb => 'Querying food database…';

  @override
  String get mealScannerResetToAuto => 'Reset to auto calculation';

  @override
  String mealScannerSavedIn(String meal) {
    return 'Saved in $meal';
  }

  @override
  String get mealScannerSearchHint => 'Search food or scan barcode…';

  @override
  String get mealScannerSearchMoreOnline => 'Search more foods online';

  @override
  String get mealScannerSearchOpenFoodFacts => 'Open Food Facts search';

  @override
  String mealScannerSearchingFor(String query) {
    return 'Searching for \"$query\"…';
  }

  @override
  String get mealScannerSearchingOnlineBanner => 'Searching online database…';

  @override
  String get mealScannerSearchingOnlineShort => 'Searching…';

  @override
  String mealScannerSelectedFoodBase(
      int calories, String protein, String carbs, String fat) {
    return '$calories kcal · P ${protein}g · C ${carbs}g · F ${fat}g (per 100g)';
  }

  @override
  String get mealScannerValuesAutoCalculated =>
      'Values calculated automatically based on weight.';

  @override
  String nutritionGoalAboutMaintenanceKcal(int kcal) {
    return '$kcal kcal/day estimated maintenance';
  }

  @override
  String get nutritionGoalActivityHigh => 'High (daily intense exercise)';

  @override
  String get nutritionGoalActivityLight => 'Light (1-2 workouts/week)';

  @override
  String get nutritionGoalActivityLow => 'Sedentary (little to no exercise)';

  @override
  String get nutritionGoalActivityModerate => 'Moderate (3-5 workouts/week)';

  @override
  String get nutritionGoalAdultWeightError =>
      'Please enter a realistic target weight.';

  @override
  String get nutritionGoalAgeLabel => 'Age';

  @override
  String nutritionGoalAppliedToast(
      int calories, int protein, int carbs, int fat) {
    return 'Applied targets: $calories kcal · P ${protein}g · C ${carbs}g · F ${fat}g';
  }

  @override
  String get nutritionGoalApplyRecommendedBtn => 'Apply Recommended Targets';

  @override
  String get nutritionGoalBreakfastCheckin => 'Breakfast check-in';

  @override
  String get nutritionGoalCalorieCheckinsSub =>
      'Receive daily prompts to log meals.';

  @override
  String get nutritionGoalCalorieCheckinsTitle => 'Meal Check-in Reminders';

  @override
  String get nutritionGoalCaptionDailyEnergy => 'Daily caloric intake target';

  @override
  String get nutritionGoalCaptionHormoneHealth =>
      'Essential for hormone balance and joints';

  @override
  String get nutritionGoalCaptionMuscleRecovery =>
      'Target for muscle repair and satiety';

  @override
  String get nutritionGoalCompleteProfilePrompt =>
      'Complete your profile to personalize nutrition targets.';

  @override
  String nutritionGoalDeficitBadge(int diff) {
    return '$diff kcal deficit';
  }

  @override
  String get nutritionGoalDietBalanced => 'Balanced';

  @override
  String get nutritionGoalDietHalal => 'Halal';

  @override
  String get nutritionGoalDietVegan => 'Vegan';

  @override
  String get nutritionGoalDietVegetarian => 'Vegetarian';

  @override
  String get nutritionGoalDietaryStyleLabel => 'Dietary Preference';

  @override
  String get nutritionGoalDinnerCheckin => 'Dinner check-in';

  @override
  String get nutritionGoalEstimateMaintenanceSub =>
      'Based on your height, weight, age and activity.';

  @override
  String get nutritionGoalEstimateMaintenanceTitle => 'Maintenance Calories';

  @override
  String get nutritionGoalEstimatePrompt =>
      'Calculate personalized calorie and macro targets.';

  @override
  String nutritionGoalFieldInvalid(String field) {
    return 'Please enter a valid value for $field';
  }

  @override
  String nutritionGoalFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get nutritionGoalFoodPreferenceLabel => 'Food Preference';

  @override
  String get nutritionGoalGeneralEstimatesSuitable =>
      'These estimates provide a science-backed starting point for your journey.';

  @override
  String get nutritionGoalHeaderSubtitle =>
      'Set your daily calorie and macro goals.';

  @override
  String get nutritionGoalHeaderTitle => 'Nutrition Targets';

  @override
  String get nutritionGoalHeightLabel => 'Height (cm)';

  @override
  String get nutritionGoalLunchCheckin => 'Lunch check-in';

  @override
  String get nutritionGoalMacroCalories => 'Calories';

  @override
  String get nutritionGoalMacroCarbs => 'Carbs';

  @override
  String get nutritionGoalMacroFat => 'Fat';

  @override
  String get nutritionGoalMacroProtein => 'Protein';

  @override
  String get nutritionGoalMaintenanceBadge => 'Maintenance';

  @override
  String get nutritionGoalMealIdeasSub =>
      'Get smart recipe and meal suggestions.';

  @override
  String get nutritionGoalMealIdeasTitle => 'Meal Ideas & Inspiration';

  @override
  String get nutritionGoalMinorSectionSub => 'Preferences and schedule';

  @override
  String get nutritionGoalMinorSectionTitle => 'Preferences';

  @override
  String get nutritionGoalMonthlyReview => 'Monthly Progress Review';

  @override
  String get nutritionGoalMyGoalLabel => 'Primary Goal';

  @override
  String get nutritionGoalNoteGain =>
      'Targeting lean muscle growth with a clean caloric surplus.';

  @override
  String get nutritionGoalNoteLose =>
      'Targeting safe, sustainable fat loss with a moderate deficit.';

  @override
  String get nutritionGoalNoteMaintain =>
      'Targeting weight stability, performance and energy.';

  @override
  String get nutritionGoalQuietHoursEnd => 'Quiet hours end';

  @override
  String get nutritionGoalQuietHoursNote =>
      'Notifications are silenced during your quiet hours.';

  @override
  String get nutritionGoalQuietHoursStart => 'Quiet hours start';

  @override
  String get nutritionGoalRecommendedTitle => 'Recommended Targets';

  @override
  String get nutritionGoalRemindersSub =>
      'Manage daily reminders and quiet hours.';

  @override
  String get nutritionGoalRemindersTitle => 'Reminders & Notifications';

  @override
  String get nutritionGoalSaveMyGoal => 'Save Nutrition Goal';

  @override
  String get nutritionGoalSaving => 'Saving…';

  @override
  String get nutritionGoalSectionDailyTargetsSub =>
      'Customize your daily macronutrient breakdown.';

  @override
  String get nutritionGoalSectionDailyTargetsTitle => 'Daily Targets';

  @override
  String get nutritionGoalSectionStatusSub =>
      'Current status of this nutrition goal.';

  @override
  String get nutritionGoalSectionStatusTitle => 'Goal Status';

  @override
  String get nutritionGoalSectionSupportSub =>
      'Reminders and coaching recommendations.';

  @override
  String get nutritionGoalSectionSupportTitle => 'Support & Reminders';

  @override
  String get nutritionGoalSectionWhatMattersSub =>
      'Key nutritional focus for your journey.';

  @override
  String get nutritionGoalSectionWhatMattersTitle => 'Nutrition Focus';

  @override
  String get nutritionGoalSetupLaterInProfile =>
      'You can update these targets anytime in your profile.';

  @override
  String get nutritionGoalSexFemale => 'Female';

  @override
  String get nutritionGoalSexMale => 'Male';

  @override
  String get nutritionGoalSkipForNow => 'Skip for now';

  @override
  String get nutritionGoalStartFreshSub =>
      'Reset targets to default recommendations.';

  @override
  String get nutritionGoalStartFreshTitle => 'Reset Targets';

  @override
  String get nutritionGoalStartingWeightLabel => 'Starting Weight (kg)';

  @override
  String get nutritionGoalStatusAchieved => 'Achieved';

  @override
  String get nutritionGoalStatusActive => 'Active';

  @override
  String get nutritionGoalStatusPaused => 'Paused';

  @override
  String get nutritionGoalStyleBalanced => 'Balanced';

  @override
  String get nutritionGoalStyleHighProtein => 'High Protein';

  @override
  String get nutritionGoalStyleLowCarb => 'Low Carb';

  @override
  String nutritionGoalSurplusBadge(int diff) {
    return '$diff kcal surplus';
  }

  @override
  String get nutritionGoalTargetDirectionError =>
      'Target weight direction does not match goal type.';

  @override
  String get nutritionGoalTargetWeightLabel => 'Target Weight (kg)';

  @override
  String get nutritionGoalTimeZoneLabel => 'Timezone';

  @override
  String get nutritionGoalTitle => 'Nutrition Goal';

  @override
  String get nutritionGoalTitleSignup => 'Set Up Nutrition Goal';

  @override
  String get nutritionGoalTypeBalanced => 'General Fitness';

  @override
  String get nutritionGoalTypeGain => 'Muscle Gain';

  @override
  String get nutritionGoalTypeLose => 'Fat Loss';

  @override
  String get nutritionGoalTypeMaintain => 'Maintenance';

  @override
  String get nutritionGoalUnitKcalPerDay => 'kcal / day';

  @override
  String get nutritionGoalUseThisGoal => 'Use This Goal';

  @override
  String get nutritionGoalUsualActivityLabel => 'Usual Activity Level';

  @override
  String get nutritionGoalWeeklyWeightCheckin => 'Weekly Weight Check-in';

  @override
  String get nutritionGoalYearlyReview => 'Yearly Review';

  @override
  String get nutritionTrackerGoalLoadError =>
      'Could not load your goal. Please try again.';

  @override
  String get nutritionTrackerMealRemoveError =>
      'Could not remove this meal. Try again.';

  @override
  String get nutritionTrackerDailyDiary => 'YOUR DAILY DIARY';

  @override
  String get nutritionTrackerFuelDay => 'Fuel your day.';

  @override
  String get nutritionTrackerBackToToday => 'Back to today';

  @override
  String get nutritionTrackerRetrySync => 'Retry sync';

  @override
  String get nutritionTrackerEnergyLogged => 'ENERGY LOGGED';

  @override
  String nutritionTrackerMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals logged',
      one: '1 meal logged',
    );
    return '$_temp0';
  }

  @override
  String get nutritionTrackerSetDailyTargets => 'Set your own daily targets →';

  @override
  String get nutritionTrackerScanMeal => 'Scan a meal';

  @override
  String get nutritionTrackerAddManually => 'Add manually';

  @override
  String get nutritionTrackerMealsMoments => 'Meals & moments';

  @override
  String get nutritionTrackerDiaryTitle => 'Nutrition diary';

  @override
  String get nutritionTrackerNothingLogged => 'Nothing logged yet';

  @override
  String get nutritionTrackerAddMealTitle => 'Add a meal';

  @override
  String get nutritionTrackerAddMealSubtitle =>
      'Use the nutrition on a label or in your recipe.';

  @override
  String get nutritionTrackerMealNameLabel => 'Meal name';

  @override
  String get nutritionTrackerSaving => 'Saving…';

  @override
  String get nutritionTrackerSaveMeal => 'Save meal';

  @override
  String get nutritionTrackerDailyTargetsTitle => 'Your daily targets';

  @override
  String get nutritionTrackerSaveTargets => 'Save targets';

  @override
  String get coachExpertiseDetailStatus => 'Verification Status';

  @override
  String get coachExpertiseErrorPickingFile =>
      'Could not select file. Please try again.';

  @override
  String get coachExpertiseErrorUpdating => 'Failed to update credentials.';

  @override
  String get coachExpertiseFailedLoadDoc =>
      'Could not load certificate document.';

  @override
  String get coachExpertiseFileUploaded => 'Certificate document uploaded.';

  @override
  String get coachExpertiseLevelAdvanced => 'Advanced athletes';

  @override
  String get coachExpertiseLevelBeginners => 'Beginners';

  @override
  String get coachExpertiseLevelIntermediate => 'Intermediate';

  @override
  String get coachExpertiseMaxSpecialties => 'Maximum 8 specialties allowed.';

  @override
  String get coachExpertisePreview => 'Preview';

  @override
  String get coachExpertisePrimaryCategory => 'Primary Discipline';

  @override
  String get coachExpertiseProfileUpdated =>
      'Credentials updated successfully.';

  @override
  String get coachExpertiseResubmit => 'Resubmit Document';

  @override
  String get coachExpertiseReviewInProgress => 'Under review by SIRVYA team';

  @override
  String get coachExpertiseReviewNotice =>
      'Certificates are verified by our team within 24-48 hours.';

  @override
  String get coachExpertiseSaveChanges => 'Save';

  @override
  String get coachExpertiseSelectCategory => 'Select primary category';

  @override
  String get coachExpertiseSelectYear => 'Select year';

  @override
  String get coachExpertiseSpecialtyHint => 'e.g., Kettlebell Training';

  @override
  String get coachExpertiseStatusApproved => 'Verified';

  @override
  String get coachExpertiseStatusRejected => 'Rejected';

  @override
  String get coachExpertiseStatusReviewing => 'In Review';

  @override
  String get coachExpertiseStatusSelfReported => 'Self-Reported';

  @override
  String get coachExpertiseSubmitVerification => 'Submit for Verification';

  @override
  String get coachExpertiseSuggestedBodybuilding =>
      'Bodybuilding & Hypertrophy';

  @override
  String get coachExpertiseSuggestedConditioning => 'Cardio & Conditioning';

  @override
  String get coachExpertiseSuggestedForYou => 'Suggested for your discipline';

  @override
  String get coachExpertiseSuggestedFunctional => 'Functional Fitness';

  @override
  String get coachExpertiseSuggestedNutrition => 'Nutrition & Dietetics';

  @override
  String get coachExpertiseSuggestedPilates => 'Pilates & Core Stability';

  @override
  String get coachExpertiseSuggestedPowerlifting => 'Powerlifting & Strength';

  @override
  String get coachExpertiseSuggestedRehabilitation => 'Post-Rehabilitation';

  @override
  String get coachExpertiseSuggestedYoga => 'Yoga & Flexibility';

  @override
  String get coachExpertiseTapToPreview => 'Tap to preview certificate';

  @override
  String get coachExpertiseUploadCertificate =>
      'Upload Certificate (PDF / Image)';

  @override
  String get coachExpertiseVerifiedBadgeInfo =>
      'Verified credentials receive a badge on your public profile.';

  @override
  String get coachExpertiseVerifiedCertificate => 'Verified Certificate';

  @override
  String get coachExpertiseViewDetails => 'View Details';

  @override
  String get coachExpertiseWhoYouCoach => 'Who do you typically coach?';

  @override
  String get coachLocationsFormatOutdoors => 'Outdoors / Parks';

  @override
  String get coachLocationsGymLocationTitle => 'Gym Location';

  @override
  String get coachLocationsManageAvailability =>
      'Manage your daily coaching calendar';

  @override
  String get coachLocationsOpenCalendar => 'Working Hours & Calendar';

  @override
  String get coachLocationsPreview => 'Preview';

  @override
  String get coachLocationsSaveChanges => 'Save';

  @override
  String coachLocationsSaveFailed(String error) {
    return 'Failed to save location: $error';
  }

  @override
  String get coachLocationsSelectGym => 'Select partner gym';

  @override
  String get coachLocationsServiceAreaHint => 'e.g., Greater Casablanca Area';

  @override
  String get coachLocationsServiceAreaSubtitle =>
      'Areas where you are available to travel for clients.';

  @override
  String get coachLocationsServiceAreaTitle => 'Service Area';

  @override
  String get coachLocationsUpdateLocation => 'Update Map Coordinates';

  @override
  String get coachLocationsUploadImage => 'Upload Gym Photo';

  @override
  String get coachLocationsUploading => 'Uploading photo…';

  @override
  String get coachPackagesFixedPrice => 'Fixed Session Price';

  @override
  String get coachPackagesFixedPriceSub =>
      'Standard rate applied per coaching session.';

  @override
  String get coachPackagesIncludedHint =>
      'e.g., Custom diet plan + 24/7 WhatsApp support';

  @override
  String get coachPackagesIncludedLabel => 'What\'s Included';

  @override
  String get coachPackagesIndividualSession => 'Single session';

  @override
  String get coachPackagesLocationGym => 'Gym';

  @override
  String get coachPackagesLocationOnline => 'Online';

  @override
  String get coachPackagesLocationsLabel => 'Available Locations';

  @override
  String get coachPackagesMinutesUnit => 'min';

  @override
  String coachPackagesMultipleSessions(int sessions, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    return '$_temp0 · $duration min each';
  }

  @override
  String get coachPackagesOnRequest => 'On request';

  @override
  String get coachPackagesPerSession => 'MAD / session';

  @override
  String get coachPackagesPreview => 'Preview';

  @override
  String get coachPackagesPriceOnRequest => 'Price on Request';

  @override
  String get coachPackagesPricingLabel => 'Pricing Model';

  @override
  String get coachPackagesSaveChanges => 'Save';

  @override
  String get coachPhotosFormatGym => 'Gym';

  @override
  String get coachPhotosFormatHome => 'Home';

  @override
  String get coachPhotosFormatOnline => 'Online';

  @override
  String get coachPhotosFormatOutdoors => 'Outdoors';

  @override
  String get coachPhotosGymNameHint => 'Gym Name';

  @override
  String get coachPhotosGymNameLabel => 'Gym Name';

  @override
  String get coachPhotosMaxPhotos => 'Maximum 12 photos reached.';

  @override
  String get coachPhotosPortfolioSubtitle =>
      'High quality training photos build trust with prospective clients.';

  @override
  String get coachPhotosPortfolioTitle => 'Coaching Portfolio';

  @override
  String get coachPhotosPreview => 'Preview';

  @override
  String get coachPhotosSave => 'Save';

  @override
  String get coachPhotosSaveChanges => 'Save';

  @override
  String get coachPhotosUploadImage => 'Upload Photo';

  @override
  String get coachPhotosUploading => 'Uploading…';

  @override
  String coachLocationsErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get nutritionGoalBiologicalSexLabel => 'Biological sex';

  @override
  String get nutritionGoalSexEstimateLabel =>
      'Used for basal metabolic rate calculation';

  @override
  String get nutritionGoalGeneralEstimatesSub =>
      'Standard nutritional equations based on your profile';

  @override
  String get nutritionGoalUseMaintenanceBtn => 'Use Maintenance Targets';

  @override
  String get nutritionGoalAboutCaloriePlanning =>
      'About Calorie & Macro Planning';

  @override
  String get nutritionTrackerDailyTargetsTooltip => 'Daily targets';

  @override
  String get nutritionTrackerPrevDayTooltip => 'Previous day';

  @override
  String get nutritionTrackerNextDayTooltip => 'Next day';

  @override
  String get nutritionTrackerToday => 'Today';

  @override
  String nutritionTrackerTargetSummary(int goal) {
    return '$goal kcal daily target';
  }

  @override
  String nutritionTrackerRemaining(int diff) {
    return '$diff remaining';
  }

  @override
  String nutritionTrackerAboveTarget(int diff) {
    return '$diff above target';
  }

  @override
  String nutritionTrackerOfGrams(int goal) {
    return 'of $goal g';
  }

  @override
  String get nutritionTrackerNoTargetSet => 'No target set';

  @override
  String get nutritionTrackerEstimatesNotice =>
      'Nutrition estimates are based on your saved portions. Meal details sync to your account; photos stay on this device and may be unavailable on another phone. Your diary follows the calendar dates you choose.';

  @override
  String nutritionTrackerShareMealTooltip(String name) {
    return 'Share $name';
  }

  @override
  String nutritionTrackerRemoveMealTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String get nutritionTrackerManualNotes => 'Nutrition entered manually.';

  @override
  String get nutritionTrackerOneServing => '1 serving';

  @override
  String get nutritionTrackerSyncError =>
      'Could not sync your diary. Check your connection and try again.';

  @override
  String get nutritionTrackerSyncMealError =>
      'Could not sync this meal. Your input is still here; retry to save it.';

  @override
  String get nutritionTrackerEnterMealName => 'Enter a meal name';

  @override
  String get nutritionTrackerChooseMealTypeNotice =>
      'Choose Breakfast, Lunch, Dinner or Snack after tapping Save meal.';

  @override
  String get nutritionTrackerEnterValidNumber =>
      'Enter a valid number, including 0';

  @override
  String get nutritionTrackerSaveTargetsError =>
      'Could not save targets. Your input is still here.';

  @override
  String get nutritionTrackerSetTargetsSubtitle =>
      'Set the targets that suit your plan. Leave a field empty to track without a target.';

  @override
  String get nutritionTrackerEnterValidDailyTarget =>
      'Enter a valid daily target';

  @override
  String get themeServiceLight => 'Light';

  @override
  String get themeServiceDark => 'Dark';

  @override
  String get themeServiceSystem => 'System';

  @override
  String get themeSelectorAppearance => 'Appearance';

  @override
  String get themeSelectorChooseTheme => 'Choose the app theme';

  @override
  String get campaignServiceAnnouncementExpired =>
      'This announcement has expired or is unavailable.';

  @override
  String get campaignServiceOpenLinkFailed => 'Could not open this link.';

  @override
  String get campaignServiceLocationTbd => 'To be defined';

  @override
  String get campaignServiceCompanyIndependent => 'Independent';

  @override
  String get locationReminderTitleCoach => 'Help nearby clients find you';

  @override
  String get locationReminderTitleClient => 'Find coaches closer to you';

  @override
  String get locationReminderBodyCoach =>
      'Enable location to help clients discover you nearby and see an approximate distance. Only your city and distance are shown; your address stays private.';

  @override
  String get locationReminderBodyClient =>
      'Enable location for nearby coach recommendations and approximate distances. Only your city is public; your address stays private.';

  @override
  String get locationReminderNotNow => 'Not now';

  @override
  String get locationReminderEnable => 'Enable location';

  @override
  String mealShareServiceMarketingCaption(
      String mealName, int cal, int protein, int carbs, int fat) {
    return '🥗 Just tracked my meal with SIRVYA AI!\n🍽️ $mealName\n🔥 $cal kcal · 🥩 ${protein}g Protein · 🍚 ${carbs}g Carbs · 🥑 ${fat}g Fat\n\nScan meals, track your macros & reach your fitness goals with elite coaches on SIRVYA! 💪✨\n📲 Download SIRVYA: https://sirvya.com\n#SIRVYA #Fitness #Nutrition #MealScan #HealthyEating #Coach';
  }

  @override
  String mealShareServiceSubject(String mealName) {
    return 'Tracked with SIRVYA: $mealName';
  }

  @override
  String get mealShareServiceCopiedFallback =>
      'Meal summary copied to clipboard! You can paste it into WhatsApp or Instagram.';

  @override
  String get mealShareServiceCaptionCopied =>
      'Meal caption & SIRVYA link copied to clipboard!';

  @override
  String get mediaPickerPermissionDenied =>
      'Allow camera or photo access for Sirvya in your phone Settings, then try again.';

  @override
  String get mediaPickerOpenPhotoFailed =>
      'Could not open this photo. Please try again.';

  @override
  String get notificationNavClientFallback => 'Client';

  @override
  String get notificationNavTitleFallback => 'Notification';

  @override
  String get notificationNavBodyUnavailable =>
      'This item is no longer available.';

  @override
  String get notificationNavClose => 'Close';

  @override
  String get notificationServiceChannelName => 'Sirvya Notifications';

  @override
  String get notificationServiceChannelDesc =>
      'This channel is used for important notifications.';

  @override
  String get appleAuthIosOnly =>
      'Apple sign-in is currently available on iPhone and iPad.';

  @override
  String get appleAuthFirebaseFailed => 'Firebase authentication failed.';

  @override
  String get appleAuthIdTokenFailed => 'Could not retrieve Firebase ID token.';

  @override
  String get appleAuthInvalidResponse => 'Invalid response from server.';

  @override
  String get appleAuthAccountSuspended => 'Account suspended.';

  @override
  String appleAuthSignInError(int statusCode) {
    return 'Apple sign-in error ($statusCode)';
  }

  @override
  String get googleAuthFirebaseFailed => 'Firebase authentication failed.';

  @override
  String get googleAuthIdTokenFailed => 'Could not retrieve Firebase ID token.';

  @override
  String get googleAuthInvalidResponse => 'Invalid response from server.';

  @override
  String get googleAuthAccountSuspended => 'Account suspended.';

  @override
  String googleAuthSignInError(int statusCode) {
    return 'Google sign-in error ($statusCode)';
  }

  @override
  String get accountPasswordSheetServerUnreachable =>
      'Unable to reach the server. Please try again.';

  @override
  String accountPasswordSheetEnterField(String label) {
    return 'Enter $label';
  }

  @override
  String get accountPasswordSheetMinLength => 'Use at least 8 characters.';

  @override
  String get accountPasswordSheetPasswordsMismatch => 'Passwords do not match.';

  @override
  String get accountPasswordSheetShowPassword => 'Show password';

  @override
  String get accountPasswordSheetHidePassword => 'Hide password';

  @override
  String get accountPasswordSheetClose => 'Close';

  @override
  String get accountPasswordSheetTitle => 'Secure your account';

  @override
  String get accountPasswordSheetSubtitle =>
      'Choose a password with at least 8 characters that you don’t use elsewhere.';

  @override
  String get accountPasswordSheetCurrentLabel => 'Current password';

  @override
  String get accountPasswordSheetNewLabel => 'New password';

  @override
  String get accountPasswordSheetConfirmLabel => 'Confirm password';

  @override
  String get accountPasswordSheetUpdating => 'Updating password…';

  @override
  String get accountPasswordSheetUpdate => 'Update password';

  @override
  String get appUpdatePromptLinkNotConfigured =>
      'The update link is not configured yet. Please contact Sirvya support.';

  @override
  String get appUpdatePromptStoreOpenFailed =>
      'Could not open the store. Please try again or check for the update in your app store.';

  @override
  String get appUpdatePromptUpdateRequiredBadge => 'UPDATE REQUIRED';

  @override
  String get appUpdatePromptNewVersionBadge => 'NEW VERSION';

  @override
  String get appUpdatePromptMandatoryTitle => 'Update Sirvya to continue';

  @override
  String get appUpdatePromptOptionalTitle => 'A fresh version of Sirvya';

  @override
  String get appUpdatePromptMandatoryBody =>
      'This version is no longer supported. Install the latest version to keep using the app.';

  @override
  String get appUpdatePromptOptionalBody =>
      'The latest version is ready. Update now for the latest improvements.';

  @override
  String appUpdatePromptInstalledVersion(String version) {
    return 'Installed $version';
  }

  @override
  String appUpdatePromptMinimumVersion(String version) {
    return 'Minimum $version';
  }

  @override
  String get appUpdatePromptOpeningStore => 'Opening the store…';

  @override
  String get appUpdatePromptUpdateNow => 'Update now';

  @override
  String get appUpdatePromptChecking => 'Checking…';

  @override
  String get appUpdatePromptCheckAgain => 'Check again';

  @override
  String get appUpdatePromptLater => 'Later';

  @override
  String get campaignDialogExploreNow => 'Explore now';

  @override
  String get campaignDialogGotIt => 'Got it';

  @override
  String get campaignDialogBrandHeader => 'SIRVYA  /  INSIDE';

  @override
  String get campaignDialogCloseTooltip => 'Close announcement';

  @override
  String get campaignDialogSelectedForYou => 'SELECTED FOR YOU';

  @override
  String get campaignDialogDefaultTitle => 'Something new at Sirvya';

  @override
  String get campaignDialogMaybeLater => 'Maybe later';

  @override
  String get clientProfileViewPhotoLabel => 'View profile photo';

  @override
  String get clientProfileChangePhotoTooltip => 'Change profile photo';

  @override
  String get clientProfilePremiumBadge => 'SIRVYA PREMIUM';

  @override
  String get clientProfileJourneyBadge => 'YOUR SIRVYA JOURNEY';

  @override
  String get clientProfileWelcomeTitle => 'Welcome to Sirvya';

  @override
  String get clientProfileSetCity => 'Set your city';

  @override
  String get clientProfilePersonalSpaceNote =>
      'Your personal space. Built around your progress.';

  @override
  String get clientProfileCompletionTitle => 'Make it yours';

  @override
  String clientProfileCompletionDetailsAdded(int completed, int total) {
    return 'Profile completion · $completed of $total details added';
  }

  @override
  String get clientProfileCompletionSemantic => 'Profile completion';

  @override
  String get clientProfileStepPhoto => 'Add your profile photo';

  @override
  String get clientProfileStepFirstName => 'Add your first name';

  @override
  String get clientProfileStepLastName => 'Add your last name';

  @override
  String get clientProfileStepEmail => 'Add your email address';

  @override
  String get clientProfileStepPhone => 'Add your phone number';

  @override
  String get clientProfileStepCity => 'Set your city';

  @override
  String get clientProfileStepHeight => 'Add your height';

  @override
  String get clientProfileStepInterests => 'Choose your fitness interests';

  @override
  String get connectionRecoveryCheckTitle => 'Check your connection';

  @override
  String get connectionRecoveryLater => 'Later';

  @override
  String get connectionRecoveryRefreshApp => 'Refresh app';

  @override
  String get locationPickerFindingCity => 'Finding your city…';

  @override
  String get locationPickerUseCurrent => 'Use my current location';

  @override
  String get locationPickerCityLabel => 'City';

  @override
  String get locationPickerAddressLabel => 'Detected address (private)';

  @override
  String get locationPickerPrivacyNotice =>
      'Use the location button to fill these fields automatically. Only your city appears to other users. Your detailed address and coordinates stay private.';

  @override
  String get locationPickerKeepUpdatedTitle => 'Keep my location updated';

  @override
  String get locationPickerKeepUpdatedSubtitle =>
      'Refresh every 15 minutes. Background updates require Always allow permission.';

  @override
  String get mealDiaryMoveTitle => 'Move your meal';

  @override
  String get mealDiarySaveTitle => 'Save your meal';

  @override
  String get mealDiaryCancel => 'Cancel';

  @override
  String get mealDiaryMoveSubtitle => 'Choose its new place in your diary.';

  @override
  String get mealDiarySaveSubtitle => 'Where would you like to add this meal?';

  @override
  String get mealDiaryTypeBreakfast => 'Breakfast';

  @override
  String get mealDiaryTypeLunch => 'Lunch';

  @override
  String get mealDiaryTypeDinner => 'Dinner';

  @override
  String get mealDiaryTypeSnack => 'Snack';

  @override
  String mealDiaryMoveTo(String mealType) {
    return 'Move to $mealType';
  }

  @override
  String mealDiarySaveTo(String mealType) {
    return 'Save to $mealType';
  }

  @override
  String get mealDiaryDeleteTitle => 'Delete this meal?';

  @override
  String mealDiaryDeleteBody(String name) {
    return '“$name” will be removed from your diary and daily totals. This cannot be undone.';
  }

  @override
  String get mealDiaryKeepMeal => 'Keep meal';

  @override
  String get mealDiaryDeleteMeal => 'Delete meal';

  @override
  String get mealLiveCameraNoCamera =>
      'No camera found. Choose a photo from your gallery.';

  @override
  String get mealLiveCameraPermissionDenied =>
      'Allow camera access in your device or browser settings, then retry.';

  @override
  String get mealLiveCameraUnavailable =>
      'Camera unavailable. Retry or choose a photo from your gallery.';

  @override
  String get mealLiveCameraCaptureFailed =>
      'Could not capture the photo. Try again.';

  @override
  String get mealLiveCameraStarting => 'Starting camera…';

  @override
  String get mealLiveCameraRetry => 'Retry camera';

  @override
  String get mealScannerTitle => 'Sirvya nutrition';

  @override
  String get mealScannerSavedMealsTooltip => 'Saved meals';

  @override
  String get mealScannerDiscoverButton => 'Discover your meal';

  @override
  String get mealScannerFooterDisclaimer =>
      'Photo sent for AI analysis · Nutrition is estimated';

  @override
  String get mealScannerMeetYourMealChip => 'MEET YOUR MEAL';

  @override
  String get mealScannerHeading => 'Your plate,\nunderstood.';

  @override
  String get mealScannerSubheading =>
      'A little clarity for every bite.\nFrom everyday favorites to Moroccan classics.';

  @override
  String get mealScannerStepCapture => 'Capture';

  @override
  String get mealScannerStepReview => 'Review';

  @override
  String get mealScannerStepDiscover => 'Discover';

  @override
  String get mealScannerLetsTakeALook => 'Let’s take a look';

  @override
  String get mealScannerGoodLightHint => 'Good light. Whole plate. One photo.';

  @override
  String get mealScannerKeepWholePlate => 'Keep the whole plate in view';

  @override
  String get mealScannerPhotoReady => 'Photo ready for analysis';

  @override
  String get mealScannerAnalyzingTitle => 'Getting to know your meal';

  @override
  String get mealScannerAnalyzingSubtitle =>
      'Ingredients first. Nutrition next.';

  @override
  String get mealScannerFromGalleryTooltip => 'From gallery';

  @override
  String get mealScannerGalleryLabel => 'Gallery';

  @override
  String get mealScannerRetakePhoto => 'Retake photo';

  @override
  String get mealScannerCapturePhoto => 'Capture photo';

  @override
  String get mealScannerPortionQuestion => 'How much are you eating?';

  @override
  String get mealScannerPortionSubtitle =>
      'Choose your portion of the food in this photo.';

  @override
  String get mealScannerPortionHalf => '½ plate';

  @override
  String get mealScannerPortionOne => '1 plate';

  @override
  String get mealScannerPortionOneHalf => '1½ plates';

  @override
  String get mealScannerPortionTwo => '2 plates';

  @override
  String get mealScannerNotesLabel => 'Anything we can’t see?';

  @override
  String get mealScannerNotesHint => 'Extra olive oil, sauces, sugar…';

  @override
  String get mealScanLimitPausedTitle => 'Meal scans are paused';

  @override
  String get mealScanLimitReachedTitle => 'You’re all scanned for today';

  @override
  String mealScanLimitUsedToday(int used, int total) {
    return '$used / $total scans used today';
  }

  @override
  String mealScanLimitPerDay(int dailyLimit) {
    String _temp0 = intl.Intl.pluralLogic(
      dailyLimit,
      locale: localeName,
      other: '$dailyLimit scans per day',
      one: '1 scan per day',
    );
    return '$_temp0';
  }

  @override
  String mealScanLimitPerDayWithBonus(int dailyLimit, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      dailyLimit,
      locale: localeName,
      other: '$dailyLimit scans per day',
      one: '1 scan per day',
    );
    return '$_temp0 + $bonus extra today';
  }

  @override
  String get mealScanLimitPausedBody =>
      'Meal scanning is currently disabled for your account. Your admin can update your allowance.';

  @override
  String get mealScanLimitReachedBody =>
      'You’ve reached your allowance for today. Come back after midnight UTC for your next daily scans, or ask your admin for extra scans.';

  @override
  String get mealScanLimitGotIt => 'Got it';

  @override
  String get mealShareCardCalories => 'Calories';

  @override
  String get mealShareCardProtein => 'Protein';

  @override
  String get mealShareCardCarbs => 'Carbs';

  @override
  String get mealShareCardFat => 'Fat';

  @override
  String get mealShareModalTitle => 'Share Your Meal';

  @override
  String get mealShareModalSubtitle =>
      'Sirvya photo overlay for Stories & Posts';

  @override
  String get mealShareModalClose => 'Close';

  @override
  String get mealShareModalStoryTab => 'Story (9:16)';

  @override
  String get mealShareModalPostTab => 'Post Card';

  @override
  String get mealShareModalStyleOverlay => 'Sirvya Overlay';

  @override
  String get mealShareModalStyleCard => 'Card View';

  @override
  String get mealShareModalIncludeIngredients =>
      'Include Ingredients Breakdown';

  @override
  String get mealShareModalShareButton => 'Share Story / Post';

  @override
  String get mealShareModalCopyCaptionButton => 'Copy Caption & Link';

  @override
  String mealVisualsIngredientIllustration(String name) {
    return '$name illustration';
  }

  @override
  String get mealVisualsAnalysisTitle => 'Meal analysis';

  @override
  String get mealVisualsShareMealTooltip => 'Share meal';

  @override
  String get mealVisualsBackTooltip => 'Back';

  @override
  String get mealVisualsChipManualDiary => 'YOUR MEAL DIARY';

  @override
  String get mealVisualsChipScan => 'SIRVYA MEAL SCAN';

  @override
  String get mealVisualsManualServing => '1 serving · Entered nutrition';

  @override
  String get mealVisualsEstimatedOnePlate => '1 plate · Estimated nutrition';

  @override
  String mealVisualsEstimatedPlates(String portion) {
    return '$portion plates · Estimated nutrition';
  }

  @override
  String get mealVisualsInsideYourPlate => 'Inside your plate';

  @override
  String mealVisualsIngredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get mealVisualsFineTunePortions =>
      'Fine-tune portions to make this estimate yours.';

  @override
  String get mealVisualsAddIngredient => 'Add an ingredient';

  @override
  String get mealVisualsManualDisclaimer =>
      'Nutrition is based on the values you entered for this serving.';

  @override
  String get mealVisualsScanDisclaimer =>
      'Ingredient images are illustrations. Nutrition is estimated from your meal photo and portion details.';

  @override
  String get mealVisualsTotalEnergy => 'TOTAL ENERGY';

  @override
  String get mealVisualsNutritionEntered => 'Nutrition you entered';

  @override
  String get mealVisualsEstimateOfPortion => 'An estimate of this portion';

  @override
  String get mealVisualsMacroProtein => 'Protein';

  @override
  String get mealVisualsMacroCarbs => 'Carbs';

  @override
  String get mealVisualsMacroFat => 'Fat';

  @override
  String get mealVisualsShareToTitle => 'Share to';

  @override
  String get mealVisualsShareToSubtitle =>
      'Post your meal & macros to Instagram, WhatsApp & more';

  @override
  String get mealVisualsChannelStory => 'Story';

  @override
  String get mealVisualsChannelWhatsApp => 'WhatsApp';

  @override
  String get mealVisualsChannelPost => 'Post';

  @override
  String mealVisualsEditIngredientTooltip(String name) {
    return 'Edit $name';
  }

  @override
  String mealVisualsMoreOptionsTooltip(String name) {
    return 'More options for $name';
  }

  @override
  String get mealVisualsRemoveIngredient => 'Remove ingredient';

  @override
  String get mealVisualsContextTitle => 'A little context';

  @override
  String get mealVisualsConfidenceManual => 'Entered manually';

  @override
  String mealVisualsConfidenceLevel(String level) {
    return '$level confidence';
  }

  @override
  String get mealVisualsSaveChanges => 'Save changes';

  @override
  String get mealVisualsSaveMeal => 'Save meal';

  @override
  String get mealVisualsSaveBarFooter =>
      'Account diary · Photos stay on this device';

  @override
  String get notificationCardCatNutrition => 'YOUR NUTRITION';

  @override
  String get notificationCardCatPricing => 'PRICING';

  @override
  String get notificationCardCatMessage => 'MESSAGE';

  @override
  String get notificationCardCatFeedback => 'FEEDBACK';

  @override
  String get notificationCardCatSessions => 'YOUR SESSIONS';

  @override
  String get notificationCardCatConnections => 'CONNECTIONS';

  @override
  String get notificationCardCatUpdate => 'SIRVYA UPDATE';

  @override
  String get notificationCardView => 'View';

  @override
  String get notificationCardJustNow => 'Just now';

  @override
  String notificationCardMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String notificationCardHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get notificationCardYesterday => 'Yesterday';

  @override
  String get notificationInboxTitle => 'Your latest updates';

  @override
  String get notificationInboxAllCaughtUp => 'You’re all caught up.';

  @override
  String notificationInboxUnreadCount(int count) {
    return '$count unread · Keep your journey moving.';
  }

  @override
  String get nutritionGoalCardTitle => 'My nutrition goal';

  @override
  String get nutritionGoalCardSetGoal => 'Set goal';

  @override
  String get nutritionGoalCardEdit => 'Edit';

  @override
  String get nutritionGoalCardLoadFailedRetry =>
      'Could not load your goal · Retry';

  @override
  String get nutritionGoalCardEmptyPrompt =>
      'Choose your goal and optional reminders. Start with balanced habits or set a personal weight goal.';

  @override
  String get nutritionGoalCardPersonalGoal => 'Your personal goal';

  @override
  String get nutritionGoalLabelBalanced => 'Build balanced habits';

  @override
  String get nutritionGoalLabelLose => 'Lose weight gradually';

  @override
  String get nutritionGoalLabelGain => 'Gain weight gradually';

  @override
  String get nutritionGoalLabelMaintain => 'Maintain my weight';

  @override
  String get nutritionGoalCardStatusAchieved =>
      'Goal reached · Choose a new goal when ready';

  @override
  String get nutritionGoalCardStatusPaused =>
      'Paused · Resume whenever you like';

  @override
  String get nutritionGoalCardStatusActiveRemindersOn =>
      'Active · Reminders follow your preferences';

  @override
  String get nutritionGoalCardStatusActiveRemindersOff =>
      'Active · Reminders off';

  @override
  String get nutritionGoalCardAddWeighInHint =>
      'Add a recent weigh-in to track your goal.';

  @override
  String get nutritionGoalCardBasedOnWeighIns =>
      'Based on your saved weigh-ins. Completion uses recent check-ins, not a promised date.';

  @override
  String get nutritionGoalCardProgressButton => 'Monthly & yearly progress';

  @override
  String get nutritionReviewLoadError =>
      'Could not load this review. Try again.';

  @override
  String get nutritionReviewTitle => 'Your progress review';

  @override
  String get nutritionReviewMonthly => 'Monthly';

  @override
  String get nutritionReviewYearly => 'Yearly';

  @override
  String get nutritionReviewPreviousPeriod => 'Previous period';

  @override
  String get nutritionReviewNextPeriod => 'Next period';

  @override
  String nutritionReviewDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days logged',
      one: '1 day logged',
    );
    return '$_temp0';
  }

  @override
  String nutritionReviewSavedMeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved meals',
      one: '1 saved meal',
    );
    return '$_temp0';
  }

  @override
  String get nutritionReviewDailyAveragesTitle => 'Daily averages';

  @override
  String get nutritionReviewDailyAveragesSubtitle =>
      'Only days with saved meals are included. Unlogged days are not treated as zero intake.';

  @override
  String get nutritionReviewWeightCheckInsTitle => 'Weight check-ins';

  @override
  String nutritionReviewWeightCheckInsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count check-ins in this period',
      one: '1 check-in in this period',
    );
    return '$_temp0';
  }

  @override
  String nutritionReviewWeightRange(String first, String latest) {
    return '$first to $latest kg';
  }

  @override
  String get nutritionReviewFooterDisclaimer =>
      'This is your logged history, not a complete measure of your intake. Small, consistent check-ins can help you understand your routine.';

  @override
  String get profileCompletedBadgeLabel => 'Profile completed';

  @override
  String get weightProgressHeaderTag => 'YOUR PROGRESS';

  @override
  String get weightProgressHeaderTitle => 'Every check-in counts.';

  @override
  String get weightProgressLogTooltip => 'Log weight';

  @override
  String get weightProgressRefreshHistory => 'Refresh history';

  @override
  String get weightProgressCurrentWeight => 'Current weight';

  @override
  String get weightProgressFirstWeighInHint =>
      'Your first weigh-in starts here.';

  @override
  String weightProgressLatestWeighIn(String date) {
    return 'Latest weigh-in · $date';
  }

  @override
  String get weightProgressSinceFirst => 'since your first weigh-in';

  @override
  String get weightProgressStartingWeight => 'Starting weight';

  @override
  String get weightProgressWeighInsLogged => 'Weigh-ins logged';

  @override
  String get weightProgressTrendTitle => 'Weight trend';

  @override
  String get weightProgressTrendSubtitle =>
      'A little perspective on your journey.';

  @override
  String get weightProgressPeriod7Days => '7 days';

  @override
  String get weightProgressPeriod30Days => '30 days';

  @override
  String get weightProgressPeriodRecent => 'Recent';

  @override
  String weightProgressChartSemantics(int count, String weight, String date) {
    return 'Weight trend, $count weigh-ins. Selected $weight kilograms on $date.';
  }

  @override
  String get weightProgressChartSinglePointHint =>
      'Your first point is on the chart. Add another to see a trend. Dates in UTC.';

  @override
  String get weightProgressChartMultiPointHint =>
      'Tap or slide across the chart to explore your weigh-ins. Dates in UTC.';

  @override
  String get weightProgressEmptyStoryTitle => 'Your story starts with one log.';

  @override
  String get weightProgressEmptyPeriodTitle => 'No weigh-ins in this period.';

  @override
  String get weightProgressEmptyStorySubtitle =>
      'Log a weight to start your personal trend.';

  @override
  String get weightProgressEmptyPeriodSubtitle =>
      'Choose Recent to see your latest available records.';

  @override
  String get weightProgressRecentTitle => 'Recent weigh-ins';

  @override
  String weightProgressInViewCount(int count) {
    return '$count in view';
  }

  @override
  String get weightProgressEmptyRecords =>
      'Your recorded weights will appear here.';

  @override
  String get weightProgressFirstInView => 'First in this view';

  @override
  String weightProgressChangeFromPrevious(String change) {
    return '$change from previous';
  }

  @override
  String get weightProgressChartLimitFooter =>
      'Chart: up to the latest 90 saved weigh-ins. List: latest 5 in this view.';

  @override
  String get weightProgressKeepRecordTitle => 'Keep a record, at your pace.';

  @override
  String get weightProgressKeepRecordSubtitle =>
      'A quick check-in adds another point to your story.';

  @override
  String get weightProgressLogButton => 'Log a weigh-in';

  @override
  String weightProgressBmiLabel(String bmi) {
    return 'BMI · $bmi';
  }

  @override
  String get weightProgressBmiSubtitle =>
      'From your latest weight and saved height.';

  @override
  String get weightLogInvalidError =>
      'Enter a valid weight between 0 and 500 kg.';

  @override
  String get weightLogSaveError =>
      'Could not save. Your entry is still here—please try again.';

  @override
  String get weightLogSheetTitle => 'A moment for you.';

  @override
  String get weightLogCloseTooltip => 'Close';

  @override
  String get weightLogSheetSubtitle =>
      'Log your weight and keep your journey in view.';

  @override
  String get weightLogInputLabel => 'Weight (kg)';

  @override
  String get weightLogRecordedTodayHint =>
      'Recorded for today. You can use a dot or a comma.';

  @override
  String weightLogLastRecordedHint(String weight) {
    return 'Last recorded: $weight kg · Recorded for today.';
  }

  @override
  String get weightLogSaving => 'Saving…';

  @override
  String get weightLogSaveButton => 'Save weigh-in';

  @override
  String get announcementClose => 'Close';

  @override
  String get announcementWhatsNewTitle => 'What’s new at Sirvya';

  @override
  String get announcementDismissTooltip => 'Dismiss announcements';

  @override
  String get announcementSirvyaUpdate => 'SIRVYA UPDATE';

  @override
  String get announcementExploreCoaches => 'Explore coaches';

  @override
  String get announcementLearnMore => 'Learn more';

  @override
  String get announcementReadMore => 'Read more';

  @override
  String chatImageBatchSendPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count photos',
      one: 'Send 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get chatImageBatchCaptionHint =>
      'Caption for the first photo (optional)';

  @override
  String get chatImageBatchCancel => 'Cancel';

  @override
  String chatSelectionSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get chatSelectionSelectAllTooltip => 'Select all loaded messages';

  @override
  String get chatSelectionDeleteTooltip => 'Delete messages';

  @override
  String get clientNavHome => 'Home';

  @override
  String get clientNavExplore => 'Explore';

  @override
  String get clientNavSessions => 'Sessions';

  @override
  String get clientNavProfile => 'Profile';

  @override
  String get clientNavScanMealLabel => 'Scan your meal';

  @override
  String coachHeaderNotificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get coachHeaderNotifications => 'Notifications';

  @override
  String get coachHeaderOpenProfileLabel => 'Open Coach Profile';

  @override
  String get coachNavbarDashboard => 'Dashboard';

  @override
  String get coachNavbarCalendar => 'Calendar';

  @override
  String get coachNavbarChats => 'Chats';

  @override
  String get coachNavbarClients => 'Clients';

  @override
  String get coachNavbarProfile => 'Profile';

  @override
  String conversationSendingPhotoBatch(int current, int total) {
    return 'Sending photo $current of $total…';
  }

  @override
  String get conversationSendingAttachment => 'Sending your attachment…';

  @override
  String get conversationSendingMessage => 'Sending message…';

  @override
  String get conversationRefreshError =>
      'Could not refresh. Your messages are still here.';

  @override
  String get conversationRetry => 'Retry';

  @override
  String conversationNewUnread(int count) {
    return '$count new';
  }

  @override
  String get conversationBackTooltip => 'Back';

  @override
  String get conversationStorageNotice =>
      'Photos and voice notes stay on this device';

  @override
  String get conversationDismissNoticeTooltip => 'Dismiss storage notice';

  @override
  String get conversationLoading => 'Loading conversation…';

  @override
  String get conversationEmptyTitle => 'Start the conversation';

  @override
  String get conversationEmptySubtitle => 'A little hello goes a long way.';

  @override
  String get conversationRetryOlder => 'Retry older messages';

  @override
  String get conversationDayToday => 'Today';

  @override
  String get conversationDayYesterday => 'Yesterday';

  @override
  String get conversationDeletedByYou => 'You deleted this message';

  @override
  String get conversationDeletedByOther => 'This message was deleted';

  @override
  String get conversationAttachPhotosTooltip => 'Attach photos';

  @override
  String conversationRecordingTimer(String time) {
    return 'Recording $time';
  }

  @override
  String get conversationWriteMessageHint => 'Write a message…';

  @override
  String get conversationPhotoGalleryTooltip => 'Photo gallery';

  @override
  String get conversationStopRecordingSendTooltip => 'Stop recording and send';

  @override
  String get conversationSendMessageTooltip => 'Send message';

  @override
  String get conversationRecordVoiceTooltip => 'Record voice message';

  @override
  String get exploreCoachGridRemoveFavorite => 'Remove from favorites';

  @override
  String get exploreCoachGridAddFavorite => 'Add to favorites';

  @override
  String get exploreCoachGridNew => 'New';

  @override
  String exploreCoachGridFromPrice(int price) {
    return 'From $price MAD';
  }

  @override
  String get exploreCoachGridPriceOnRequest => 'Price on request';

  @override
  String get exploreCoachGridViewAndBook => 'View & Book';

  @override
  String get exploreCoachMapLoadError =>
      'Could not load the map. Please try again.';

  @override
  String get exploreCoachMapCoachesInArea => 'Coaches in this area';

  @override
  String get exploreCoachMapViewAndBook => 'View & Book';

  @override
  String get exploreCoachMapRetry => 'Retry';

  @override
  String get exploreCoachMapYourLocation => 'Your location';

  @override
  String exploreCoachMapCoachesInAreaSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coaches in this area',
      one: '1 coach in this area',
    );
    return '$_temp0';
  }

  @override
  String get exploreCoachMapOsmCopyright => '© OpenStreetMap contributors';

  @override
  String get exploreCoachMapTilesUnavailable =>
      'Map tiles unavailable. Check your connection.';

  @override
  String get exploreCoachMapNoCoachesMatch =>
      'No coaches with a saved location match your filters.';

  @override
  String exploreCoachMapApproximateLocations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coaches · Approximate locations',
      one: '1 coach · Approximate location',
    );
    return '$_temp0';
  }

  @override
  String get exploreCoachMapSetYourLocation => 'Set your location';

  @override
  String get exploreCoachMapNearMe => 'Near me';

  @override
  String get exploreCoachMapShowAllCoaches => 'Show all coaches';

  @override
  String get exploreCoachMapRefreshMap => 'Refresh map';

  @override
  String get exploreCoachMapZoomOut => 'Zoom out';

  @override
  String get exploreCoachMapZoomIn => 'Zoom in';

  @override
  String get localChatMediaDeleteTitle => 'Delete from this phone?';

  @override
  String get localChatMediaDeleteBody =>
      'The message stays in your history. Once the server copy is removed, this file cannot be downloaded again.';

  @override
  String get localChatMediaCancel => 'Cancel';

  @override
  String get localChatMediaDeleteFile => 'Delete file';

  @override
  String get localChatMediaMissingError =>
      'This file was stored on the original device. Deleting the app removes local photos and voice notes. Ask the sender to resend it.';

  @override
  String get localChatMediaNotOnDevice => 'Not on this device';

  @override
  String get localChatMediaSending => 'Sending…';

  @override
  String get localChatMediaRetryDownload => 'Retry download';

  @override
  String get localChatMediaDownloading => 'Downloading…';

  @override
  String get localChatMediaLoadingPhoto => 'Loading photo…';

  @override
  String get managerHeaderRoleBadge => 'MANAGER';

  @override
  String get managerNavbarDashboard => 'Dashboard';

  @override
  String get managerNavbarClients => 'Clients';

  @override
  String get managerNavbarCoaches => 'Coaches';

  @override
  String get managerNavbarReservations => 'Reservations';

  @override
  String get managerNavbarMore => 'More';

  @override
  String get voiceNoteTapToRetry => 'Tap to retry';

  @override
  String get voiceNoteLoadingTooltip => 'Loading voice message';

  @override
  String get voiceNoteRetryTooltip => 'Retry voice message';

  @override
  String get voiceNotePauseTooltip => 'Pause voice message';

  @override
  String get voiceNotePlayTooltip => 'Play voice message';

  @override
  String get voiceNoteSeekBarLabel => 'Voice message seek bar';

  @override
  String voiceNoteSeekBarValue(int percent) {
    return '$percent percent';
  }

  @override
  String get voiceNoteLoading => 'Loading…';

  @override
  String get voiceNoteLabel => 'Voice note';

  @override
  String get blockedUsersListLoadFailed => 'Failed to load blocked users';

  @override
  String blockedUsersListNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String blockedUsersListUnblockTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get blockedUsersListUnblockMessage =>
      'They will be able to see your profile and send you messages again.';

  @override
  String get blockedUsersListCancel => 'Cancel';

  @override
  String get blockedUsersListUnblock => 'Unblock';

  @override
  String blockedUsersListUnblocked(String name) {
    return '$name has been unblocked';
  }

  @override
  String get blockedUsersListUnblockFailed => 'Failed to unblock user';

  @override
  String get blockedUsersListTitle => 'Blocked Users';

  @override
  String get blockedUsersListRetry => 'Retry';

  @override
  String get blockedUsersListEmptyTitle => 'No blocked users';

  @override
  String get blockedUsersListEmptyMessage =>
      'When you block someone, they will appear here.';

  @override
  String get blockedUsersListBlockedLabel => 'Blocked';

  @override
  String get clientNotificationsLoadFailed => 'Could not load notifications';

  @override
  String get clientNotificationsMarkReadFailed =>
      'Could not mark notifications read.';

  @override
  String get clientNotificationsTitle => 'Notifications';

  @override
  String get clientNotificationsMarkAllRead => 'Mark all as read';

  @override
  String clientNotificationsErrorRetry(String error) {
    return '$error · Retry';
  }

  @override
  String get clientNotificationsEmpty => 'No notifications yet.';

  @override
  String coachInvitationsMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String coachInvitationsHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get coachInvitationsYesterday => 'Yesterday';

  @override
  String coachInvitationsDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get coachInvitationsGenericError =>
      'Something went wrong, please try again.';

  @override
  String get coachInvitationsEmpty => 'No invitations clicked yet';

  @override
  String get coachInvitationsTitle => 'Invitations';

  @override
  String get coachInvitationsPointsHeader => 'Client Invitation Points';

  @override
  String coachInvitationsPointsValue(int points) {
    return '$points pts';
  }

  @override
  String get coachInvitationsAcceptedClients => 'accepted clients';

  @override
  String coachInvitationsPointsEarned(int points) {
    return '+$points pts';
  }

  @override
  String get coachInvitationsDeclined => 'Declined';

  @override
  String get coachInvitationsDecline => 'Decline';

  @override
  String get coachInvitationsAccept => 'Accept';

  @override
  String get welcomePage1Tag => 'COACHING';

  @override
  String get welcomePage1Title => 'Your Coach,';

  @override
  String get welcomePage1Accent => 'On Demand.';

  @override
  String get welcomePage1Subtitle =>
      'Find certified coaches near you and book a session in seconds.';

  @override
  String get welcomePage2Tag => 'PROGRESS';

  @override
  String get welcomePage2Title => 'Track Every';

  @override
  String get welcomePage2Accent => 'Milestone.';

  @override
  String get welcomePage2Subtitle =>
      'Monitor your sessions and measure your growth day after day.';

  @override
  String get welcomePage3Tag => 'COMMUNITY';

  @override
  String get welcomePage3Title => 'Join';

  @override
  String get welcomePage3Accent => 'SIRVYA.';

  @override
  String get welcomePage3Subtitle =>
      'Connect with top coaches and transform your body for good.';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeLogIn => 'LOG IN';

  @override
  String get welcomeCreateAccount => 'CREATE AN ACCOUNT';

  @override
  String get coachInviteClientsLoadError =>
      'Unable to load invitations. Please try again.';

  @override
  String get coachInviteClientsCopied => 'Copied to clipboard';

  @override
  String get coachInviteClientsShareTitle => 'Join me on SIRVYA';

  @override
  String coachInviteClientsShareText(String link, String code) {
    return 'You are invited to join me on SIRVYA. Find your coach or grow your coaching business.\n\n$link\n\nInvitation code: $code';
  }

  @override
  String coachInviteClientsShareFallback(String link, String code) {
    return 'Join me on SIRVYA: $link\nInvitation code: $code';
  }

  @override
  String get coachInviteClientsTitle => 'Invite & grow';

  @override
  String get coachInviteClientsRetry => 'Retry';

  @override
  String get coachInviteClientsHeading => 'Grow your SIRVYA network';

  @override
  String get coachInviteClientsIntro =>
      'One code for clients and coaches. Track the people who successfully sign up through your invitation.';

  @override
  String get coachInviteClientsYourCode => 'Your invitation code';

  @override
  String get coachInviteClientsCopyCode => 'Copy code';

  @override
  String get coachInviteClientsCopyLink => 'Copy link';

  @override
  String get coachInviteClientsShare => 'Share';

  @override
  String get coachInviteClientsClientsJoined => 'Clients joined';

  @override
  String get coachInviteClientsCoachesJoined => 'Coaches joined';

  @override
  String coachInviteClientsPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '$count point',
    );
    return '$_temp0';
  }

  @override
  String get coachInviteClientsRewardBalance => 'Your total reward balance';

  @override
  String get coachInviteClientsHowRewards => 'How rewards work';

  @override
  String get coachInviteClientsRewardRules =>
      'Coach: 40 points after a new account is created.\nClient: 20 points when you accept their connection in Clients. Sharing or opening a link does not earn points.';

  @override
  String get coachInviteClientsPeopleInvited => 'People you invited';

  @override
  String get coachInviteClientsFilterAll => 'All';

  @override
  String get coachInviteClientsFilterClients => 'Clients';

  @override
  String get coachInviteClientsFilterCoaches => 'Coaches';

  @override
  String get coachInviteClientsEmpty =>
      'No signups in this category yet. Share your link to get started.';

  @override
  String get coachInviteClientsRoleCoach => 'Coach';

  @override
  String get coachInviteClientsRoleClient => 'Client';

  @override
  String get coachInviteClientsStatusPending => 'Connection pending';

  @override
  String get coachInviteClientsStatusConnected => 'Connected';

  @override
  String get coachInviteClientsStatusDeclined => 'Connection declined';

  @override
  String get coachInviteClientsStatusRegistered => 'Registered';

  @override
  String coachInviteClientsRoleStatus(String role, String status) {
    return '$role • $status';
  }

  @override
  String coachInviteClientsPointsAwarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pts',
      one: 'pt',
    );
    return '+$count $_temp0';
  }

  @override
  String get coachClientsInviteAccepted =>
      'Invitation accepted: +20 points. The client is now available in Chats.';

  @override
  String get coachClientsInviteDeclined => 'Invitation declined.';

  @override
  String get coachClientsInviteUpdateFailed => 'Unable to update invitation.';

  @override
  String get coachClientsYourClients => 'YOUR CLIENTS';

  @override
  String get coachClientsTitle => 'My Clients';

  @override
  String get coachClientsLoading => 'Loading…';

  @override
  String get coachClientsEmptySubtitle =>
      'Bookings and invitations bring your clients here';

  @override
  String coachClientsCountSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients • Sessions and conversations',
      one: '1 client • Sessions and conversations',
    );
    return '$_temp0';
  }

  @override
  String get coachClientsInvite => 'Invite';

  @override
  String get coachClientsStatTotal => 'Total';

  @override
  String get coachClientsStatPending => 'Pending';

  @override
  String get coachClientsStatUpcoming => 'Upcoming';

  @override
  String get coachClientsFilterAll => 'All';

  @override
  String get coachClientsSearchHint => 'Search clients...';

  @override
  String get coachClientsSort => 'Sort';

  @override
  String get coachClientsSortAz => 'Name A–Z';

  @override
  String get coachClientsSortZa => 'Name Z–A';

  @override
  String get coachClientsSortNewest => 'Newest connected';

  @override
  String get coachClientsInvitations => 'CLIENT INVITATIONS';

  @override
  String coachClientsPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get coachClientsClientFallback => 'Client';

  @override
  String get coachClientsStatusPending => 'Pending';

  @override
  String coachClientsStatusAccepted(String points) {
    return 'Accepted · +$points pts';
  }

  @override
  String get coachClientsStatusDeclined => 'Declined';

  @override
  String get coachClientsDecline => 'Decline';

  @override
  String get coachClientsAccept => 'Accept';

  @override
  String get coachClientsJustNow => 'Just now';

  @override
  String coachClientsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String coachClientsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String coachClientsDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get coachClientsEmptyTitle => 'Your coaching clients will appear here';

  @override
  String get coachClientsEmptyBody =>
      'Clients appear when they book with you or when you accept their invitation.';

  @override
  String get coachClientsUpcomingSession => 'Upcoming session';

  @override
  String coachClientsNextSession(String date, String time) {
    return 'Next: $date at $time';
  }

  @override
  String coachClientsSessionSummary(int sessions, int upcoming, int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    return '$_temp0 • $upcoming upcoming • $pending pending';
  }

  @override
  String get coachClientsLoadError => 'Unable to load clients';

  @override
  String get coachClientsRetry => 'Retry';

  @override
  String get coachClientsNoMatchSearch => 'No clients match your search.';

  @override
  String get coachClientsNoMatchFilter => 'No clients match this filter.';

  @override
  String get clientChangeEmailInvalidEmail =>
      'Please enter a valid email address.';

  @override
  String get clientChangeEmailInvalidCode =>
      'Please enter the 6-digit verification code.';

  @override
  String get clientChangeEmailVerifyFailed =>
      'Verification failed. Please try again.';

  @override
  String get clientChangeEmailCodeSent =>
      'A new verification code has been sent.';

  @override
  String get clientChangeEmailTitle => 'Change Email';

  @override
  String clientChangeEmailStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get clientChangeEmailHeadingNew => 'Enter your new email address';

  @override
  String get clientChangeEmailHeadingVerifyCurrent =>
      'Verify your current email';

  @override
  String get clientChangeEmailHeadingVerifyNew => 'Confirm your new email';

  @override
  String clientChangeEmailIntroStart(String email) {
    return 'We will send a verification code to your current email ($email) first.';
  }

  @override
  String clientChangeEmailIntroCode(String email) {
    return 'Enter the 6-digit code sent to $email.';
  }

  @override
  String get clientChangeEmailNewEmailLabel => 'New email address';

  @override
  String get clientChangeEmailCodeLabel => '6-digit verification code';

  @override
  String get clientChangeEmailPleaseWait => 'Please wait…';

  @override
  String get clientChangeEmailSendCodeButton => 'Send verification code';

  @override
  String get clientChangeEmailVerifySendButton => 'Verify & send to new email';

  @override
  String get clientChangeEmailConfirmButton => 'Confirm email change';

  @override
  String get clientChangeEmailResend => 'Resend code';

  @override
  String get clientChangeEmailStartAgain => 'Start over';

  @override
  String get clientConversationListUnknown => 'Unknown';

  @override
  String clientConversationListError(int code) {
    return 'Error ($code)';
  }

  @override
  String get clientConversationListServerUnreachable =>
      'Unable to reach server. Check your connection.';

  @override
  String get clientConversationListTitle => 'Messages';

  @override
  String get clientConversationListSubtitle => 'Chat with your coaches';

  @override
  String get clientConversationListFilterAll => 'All';

  @override
  String get clientConversationListFilterUnread => 'Unread';

  @override
  String get clientConversationListSearchHint => 'Search conversations...';

  @override
  String get clientConversationListRetry => 'RETRY';

  @override
  String get clientConversationListEmptyTitle => 'No conversations yet';

  @override
  String get clientConversationListEmptySubtitle =>
      'Your messages with coaches will appear here.';

  @override
  String clientConversationListNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get clientConversationListFooter =>
      'Your personal messages are end-to-end private';

  @override
  String get clientConversationListTapToOpen => 'Tap to open conversation';

  @override
  String get clientConversationListYesterday => 'Yesterday';

  @override
  String get clientQrScannerPrompt =>
      'Align the coach\'s QR code within the frame';

  @override
  String get coachChangeEmailTitle => 'Change Email';

  @override
  String get coachChangeEmailLoadRetry => 'Unable to load email. Tap to retry.';

  @override
  String get coachConversationsYesterday => 'Yesterday';

  @override
  String get coachConversationsEmpty => 'No conversations yet';

  @override
  String get coachConversationsFooter =>
      'Your client messages are private and secure';

  @override
  String get coachConversationsTitle => 'Messages';

  @override
  String get coachConversationsSubtitle => 'Conversations with your clients';

  @override
  String get coachConversationsFilterAll => 'All';

  @override
  String get coachConversationsFilterUnread => 'Unread';

  @override
  String get coachConversationsSearchHint => 'Search clients...';

  @override
  String get coachConversationsTapToOpen => 'Tap to open conversation';

  @override
  String get coachVisibilityUpdateFailed =>
      'Failed to update visibility settings.';

  @override
  String get coachVisibilityNetworkError => 'Network error. Please try again.';

  @override
  String get coachVisibilityTitle => 'Profile Visibility';

  @override
  String get coachVisibilitySave => 'Save';

  @override
  String get coachVisibilityProfileSection => 'Search & Discovery';

  @override
  String get coachVisibilityProfileDesc =>
      'Control whether clients can find your profile in search results and recommendations.';

  @override
  String get coachVisibilityPublicProfile => 'Public Profile';

  @override
  String get coachVisibilityPublicProfileDesc =>
      'Allow clients to discover and view your profile';

  @override
  String get coachVisibilityMessagingSection => 'Messaging Preferences';

  @override
  String get coachVisibilityMessagingDesc =>
      'Choose who can start a conversation with you directly.';

  @override
  String get coachVisibilityDirectMessaging => 'Direct Messaging';

  @override
  String get coachVisibilityDirectMessagingDesc =>
      'Allow clients to message you before booking';

  @override
  String get coachChangePhoneErrorMissing =>
      'Please enter both country code and phone number.';

  @override
  String get coachChangePhoneErrorFailed => 'Failed to update phone number.';

  @override
  String get coachChangePhoneErrorServer =>
      'Server error. Please check your connection.';

  @override
  String get coachChangePhoneTitle => 'Phone Number';

  @override
  String get coachChangePhoneSubtitle =>
      'Update the phone number linked to your account.';

  @override
  String get coachChangePhoneSave => 'Save Phone Number';

  @override
  String get splashTagline => 'YOUR FITNESS JOURNEY';

  @override
  String get mainLayoutNavHome => 'Home';

  @override
  String get mainLayoutNavExplore => 'Explore';

  @override
  String get mainLayoutNavSessions => 'Sessions';

  @override
  String get mainLayoutNavProfile => 'Profile';

  @override
  String mainLayoutPlaceholderItem(String title, int index) {
    return '$title — Item #$index';
  }

  @override
  String get mainLayoutPlaceholderHint => 'Screen under construction';

  @override
  String get userLocationSettingsDetectPrompt =>
      'Please detect or select a city and coordinates first.';

  @override
  String get userLocationSettingsTitle => 'My Location';

  @override
  String get userLocationSettingsLoadError =>
      'Unable to load your saved location.';

  @override
  String get userLocationSettingsBackgroundTitle =>
      'Background Location Permission';

  @override
  String get userLocationSettingsBackgroundSubtitle =>
      'Manage location access in system settings';

  @override
  String get userLocationSettingsSaving => 'Saving…';

  @override
  String get userLocationSettingsContinue => 'Continue';

  @override
  String get userLocationSettingsSave => 'Save Location';

  @override
  String get coachChangePasswordAllRequired => 'All fields are required.';

  @override
  String get coachChangePasswordMismatch => 'New passwords do not match.';

  @override
  String get coachChangePasswordTooShort =>
      'New password must be at least 8 characters.';

  @override
  String get coachChangePasswordFailed => 'Failed to update password.';

  @override
  String get coachChangePasswordServerError =>
      'Server error. Please check your connection.';

  @override
  String get coachChangePasswordTitle => 'Password & Security';

  @override
  String get coachChangePasswordSubtitle => 'Change your account password.';

  @override
  String get coachChangePasswordCurrent => 'Current Password';

  @override
  String get coachChangePasswordNew => 'New Password';

  @override
  String get coachChangePasswordConfirm => 'Confirm New Password';

  @override
  String get coachChangePasswordUpdate => 'Update Password';

  @override
  String get coachNotificationsUpdateFailed => 'Could not update notifications';

  @override
  String get coachNotificationsTitle => 'Notifications';

  @override
  String get coachNotificationsMarkAllRead => 'Mark all read';

  @override
  String get coachNotificationsLoadError => 'Unable to load notifications';

  @override
  String get coachNotificationsRetry => 'Retry';

  @override
  String get coachNotificationsEmptyTitle => 'No notifications yet.';

  @override
  String get coachNotificationsEmptyBody =>
      'Messages, reservations and session reminders will appear here.';

  @override
  String get accountSecurityPasswordUpdateFailed =>
      'Could not update your password. Please try again.';

  @override
  String get apiServiceNetworkError => 'Network error. Check your connection.';

  @override
  String get connectionRecoveryMessage =>
      'Your connection may be weak or interrupted, or the server may be temporarily unavailable. Check your Wi-Fi or mobile data, then try again.';

  @override
  String get conversationActivityTyping => 'Typing…';

  @override
  String get conversationActivityRecording => 'Recording a voice message…';

  @override
  String socialAuthNotAvailable(String provider) {
    return '$provider sign-in is not available yet. Please use email and password.';
  }

  @override
  String get socialAuthAccountExists =>
      'This email already has an account. Sign in using your original method.';

  @override
  String get socialAuthNetwork =>
      'Check your internet connection and try again.';

  @override
  String socialAuthNotVerified(String provider) {
    return '$provider sign-in could not be verified. Please try again.';
  }

  @override
  String get socialAuthUserDisabled =>
      'This account is unavailable. Please contact support.';

  @override
  String socialAuthFailed(String provider) {
    return '$provider sign-in failed. Please try again.';
  }
}
