import 'coachOnboarding.dart';
import 'nutritionGoal.dart';
import '../../components/app_dialog.dart';
import '../../services/referral_link_service.dart';
import 'userLocationSettings.dart';
import '../../components/location_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../../services/google_auth_service.dart';
import '../../services/apple_auth_service.dart';
import 'login.dart';
import 'welcome.dart';
import 'clientHome.dart';
import '../../mainLayoutCoach.dart';
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../../services/apiService.dart';
import '../../services/notification_service.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';

enum _ReferralStatus { idle, checking, valid, invalid }

const _orange = Color(0xFFFFB74D);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFFF5252);

const _bgImageUrl = 'assets/branding/sirvya1.jfif';

const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12
c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24
c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
<path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039
l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
<path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36
c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
<path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571
c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24
C44,22.659,43.862,21.35,43.611,20.083z"/>
</svg>
''';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _nutritionPlan;
  bool _skippedNutritionGoal = false;
  Map<String, dynamic>? get _signupNutritionPlan => _nutritionPlan == null
      ? null
      : {
          ..._nutritionPlan!,
          'height': double.tryParse(_heightCtrl.text.replaceAll(',', '.')),
          'currentWeight':
              double.tryParse(_weightCtrl.text.replaceAll(',', '.'))
        };
  Future<void> _chooseNutritionGoal() async {
    final value = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) => NutritionGoalScreen(
                signup: true,
                initial: _nutritionPlan ??
                    {
                      'height': double.tryParse(
                          _heightCtrl.text.replaceAll(',', '.')),
                      'currentWeight':
                          double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
                      'formulaSex': _gender?.toLowerCase(),
                    })));
    if (value != null && mounted) {
      if (value['skipped'] == true) {
        setState(() {
          _skippedNutritionGoal = true;
          _nutritionPlan = null;
        });
        return;
      }
      setState(() {
        _skippedNutritionGoal = false;
        _nutritionPlan = value;
        if (value['height'] != null) _heightCtrl.text = '${value['height']}';
        if (value['currentWeight'] != null) {
          _weightCtrl.text = '${value['currentWeight']}';
        }
      });
    }
  }

  Future<bool> _ensureSignupLocation() async {
    if (_role != 'client' && _role != 'coach') return true;
    if (!mounted) return false;
    if (_role == 'client' && _selectedInterests.isEmpty) {
      final continued = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, update) {
                final l = AppLocalizations.of(ctx);
                return AppDialog(
                  title: Text(l.registerInterestsDialogTitle),
                  content: SingleChildScrollView(
                      child: _buildSpecialtiesSelector(
                          interests: true, update: () => update(() {}))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.registerCancel)),
                    FilledButton(
                        onPressed: _selectedInterests.isEmpty
                            ? null
                            : () => Navigator.pop(ctx, true),
                        child: Text(l.registerContinue))
                  ],
                );
              }));
      if (!mounted || continued != true) return false;
    }
    if (_location?['city']?.toString().isNotEmpty == true &&
        _location?['latitude'] != null &&
        _location?['longitude'] != null) {
      return true;
    }
    if (!mounted) return false;
    final location = await Navigator.of(context)
        .push<Map<String, dynamic>>(MaterialPageRoute(
      builder: (_) => const UserLocationSettings(forSignup: true),
    ));
    if (!mounted || location == null) return false;
    _location = location;
    return true;
  }

  final _referralCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  Timer? _referralDebounce;
  _ReferralStatus _referralStatus = _ReferralStatus.idle;

  int _step = 0;
  String? _role;
  String? _gender;
  bool _acceptedTerms = false;
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  String? _errorMsg;

  final List<String> _selectedSpecialties = [];
  final List<String> _selectedInterests = [];
  static const _specialtyOptions = [
    'Musculation',
    'Perte de poids',
    'Yoga',
    'CrossFit',
    'Boxe',
    'Nutrition',
    'Pilates',
    'Cardio',
    'Stretching',
    'Functional Training'
  ];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _referralCtrl.text = ReferralLinkService.instance.code.value;
    if (_referralCtrl.text.isNotEmpty) _onReferralChanged(_referralCtrl.text);
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _referralCtrl.dispose();
    _otpCtrl.dispose();
    _referralDebounce?.cancel();
    super.dispose();
  }

  void _onReferralChanged(String v) {
    _referralDebounce?.cancel();
    final code = v.trim();
    if (code.isEmpty) {
      setState(() => _referralStatus = _ReferralStatus.idle);
      return;
    }
    setState(() => _referralStatus = _ReferralStatus.checking);
    _referralDebounce =
        Timer(const Duration(milliseconds: 500), () => _checkReferral(code));
  }

  Future<void> _checkReferral(String code) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/auth/validate-referral?code=${Uri.encodeQueryComponent(code)}'))
          .timeout(const Duration(seconds: 8));
      if (!mounted || _referralCtrl.text.trim() != code) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() => _referralStatus = data['valid'] == true
          ? _ReferralStatus.valid
          : _ReferralStatus.invalid);
    } catch (_) {
      if (!mounted || _referralCtrl.text.trim() != code) return;
      setState(() => _referralStatus = _ReferralStatus.idle);
    }
  }

  Widget? _referralSuffixIcon() {
    switch (_referralStatus) {
      case _ReferralStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      case _ReferralStatus.valid:
        return const Icon(Icons.check_circle_rounded, color: _green, size: 20);
      case _ReferralStatus.invalid:
        return const Icon(Icons.error_rounded, color: _red, size: 20);
      case _ReferralStatus.idle:
        return null;
    }
  }

  void _animateStep() {
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
    setState(() => _errorMsg = null);
  }

  String? _validateStep(int step, AppLocalizations l) {
    switch (step) {
      case 0:
        if (_role == null) return l.registerErrorSelectRole;
        if (!_acceptedTerms) {
          return l.registerErrorAcceptTerms;
        }
        return null;
      case 1:
        if (_firstNameCtrl.text.trim().isEmpty) return l.registerErrorFirstNameRequired;
        if (_lastNameCtrl.text.trim().isEmpty) return l.registerErrorLastNameRequired;
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(_emailCtrl.text.trim())) {
          return l.registerErrorInvalidEmail;
        }
        if (_heightCtrl.text.trim().isEmpty) return l.registerErrorHeightRequired;
        final height =
            double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.'));
        if (height == null || !height.isFinite || height <= 0 || height > 300) {
          return l.registerErrorInvalidHeight;
        }
        if (_role == 'client') {
          final weight =
              double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
          if (weight == null || !weight.isFinite || weight <= 0 || weight > 500) {
            return l.registerErrorInvalidWeight;
          }
        }
        if (_role == 'client' && _selectedInterests.isEmpty) {
          return l.registerErrorChooseInterest;
        }
        if ((_role == 'client' || _role == 'coach') &&
            ((_location?['city']?.toString().trim().isEmpty ?? true) ||
                _location?['latitude'] == null ||
                _location?['longitude'] == null)) {
          return l.registerErrorLocationRequired;
        }
        if ((_role == 'coach' || _role == 'advisor') &&
            _selectedSpecialties.isEmpty) {
          return l.registerErrorChooseSpecialty;
        }
        return null;
      case 2:
        if (_passwordCtrl.text.length < 6) {
          return l.registerErrorPasswordTooShort;
        }
        if (_passwordCtrl.text != _confirmCtrl.text) {
          return l.registerErrorPasswordsMismatch;
        }
        return null;
      case 3:
        if (_gender == null) return l.registerErrorSelectGender;
        return null;
      case 4:
        if (_otpCtrl.text.trim().length != 6) {
          return l.registerErrorOtpLength;
        }
        return null;
      default:
        return null;
    }
  }

  void _nextStep() async {
    final err = _validateStep(_step, AppLocalizations.of(context));
    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      _animateStep();
    } else if (_step == 3) {
      final ok = await _sendSignUpOTP();
      if (ok) {
        setState(() => _step = 4);
        _animateStep();
      }
    } else {
      await _verifyAndRegister();
    }
  }

  Future<bool> _sendSignUpOTP() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/send-signup-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': _emailCtrl.text.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return true;
      } else {
        setState(() => _errorMsg =
            data['error'] as String? ?? l.registerErrorSendOtpFailed);
        return false;
      }
    } catch (_) {
      setState(() => _errorMsg = l.registerErrorServerUnreachable);
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-signup-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailCtrl.text.trim().toLowerCase(),
              'otp': _otpCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['verified'] == true) {
        await _register();
      } else {
        setState(() {
          _errorMsg = data['error'] as String? ?? l.registerErrorInvalidOtp;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = l.registerErrorVerifyOtpNetwork;
        _loading = false;
      });
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() {
        _step--;
        _errorMsg = null;
      });
      _animateStep();
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final body = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'password': _passwordCtrl.text,
        'gender': _gender,
        'role': _role,
        if (_role == 'client' && _signupNutritionPlan != null)
          'nutritionPlan': _signupNutritionPlan,
        'height': double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.')),
        if (_role == 'client')
          'weight':
              double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')),
        'acceptedTerms': _acceptedTerms,
        if (_location != null) 'location': _location,
        if (_role == 'client')
          'interests': List<String>.from(_selectedInterests),
      };
      if (_role == 'client' || _role == 'coach' || _role == 'advisor') {
        if (_referralCtrl.text.trim().isNotEmpty) {
          body['referralCode'] = _referralCtrl.text.trim();
        }
        if (_role != 'client') {
          body['specialties'] = List<String>.from(_selectedSpecialties);
        }
      }
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        await ReferralLinkService.instance.clear();
        if (!mounted) return;
        _showSuccess();
      } else {
        if (!mounted) return;
        setState(() =>
            _errorMsg = data['error'] as String? ?? AppLocalizations.of(context).registerErrorFailed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMsg = AppLocalizations.of(context).registerErrorServerUnreachable);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    final l = AppLocalizations.of(context);
    if (_role == null) {
      setState(
          () => _errorMsg = l.registerErrorSelectRoleGoogle);
      return;
    }
    if (!_acceptedTerms) {
      setState(
          () => _errorMsg = l.registerErrorAgreeTermsSocial);
      return;
    }

    if (!await _ensureSignupLocation()) return;
    setState(() {
      _googleLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await GoogleAuthService.signInWithGoogle(
        role: _role!,
        referralCode: (_referralCtrl.text.trim().isNotEmpty)
            ? _referralCtrl.text.trim()
            : null,
        action: 'signup',
        termsAccepted: _acceptedTerms,
        location: _location,
        interests: _role == 'client' ? _selectedInterests : null,
        nutritionPlan: _role == 'client' ? _signupNutritionPlan : null,
        height: double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.')),
        weight: _role == 'client'
            ? double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'))
            : null,
      );

      await ReferralLinkService.instance.clear();
      final role = result.user['role'] as String? ?? _role!;
      final id = result.user['id'] as int? ?? 0;
      final firstName = result.user['firstName'] as String? ?? '';

      // Advisors awaiting approval stay on the success sheet.
      if (role == 'advisor' && !result.isApproved) {
        setState(() => _googleLoading = false);
        _showGoogleSuccess(firstName: firstName, role: role);
        return;
      }

      await ApiService.saveToken(result.accessToken);
      await ApiService.saveRole(role);
      await ApiService.saveUserData(id, firstName);
      await NotificationService.instance.getFCMToken();

      if (!mounted) return;

      Widget dest;
      switch (role) {
        case 'client':
          dest = HomeScreen(
            clientID: id,
            token: result.accessToken,
            firstName: firstName,
            onLogout: () async {
              await ApiService.clearToken();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const WelcomeScreen(),
                  transitionsBuilder: (_, a, __, child) =>
                      FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 500),
                ),
                (_) => false,
              );
            },
          );
          break;
        case 'coach':
          dest = const CoachOnboarding();
          break;
        default:
          setState(() {
            _errorMsg = AppLocalizations.of(context).registerErrorUnrecognizedRole(role);
            _googleLoading = false;
          });
          return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => dest,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'cancelled') {
        setState(() => _googleLoading = false);
        return;
      }
      if (kDebugMode) debugPrint('❌ GOOGLE REGISTER ERROR: ');
      setState(() {
        _errorMsg = msg;
        _googleLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GOOGLE REGISTER ERROR: ');
      setState(() {
        _errorMsg = AppLocalizations.of(context).registerErrorGoogleFailed;
        _googleLoading = false;
      });
    }
  }

  Future<void> _registerWithApple() async {
    final l = AppLocalizations.of(context);
    if (_role == null) {
      setState(
          () => _errorMsg = l.registerErrorSelectRoleApple);
      return;
    }
    if (!_acceptedTerms) {
      setState(
          () => _errorMsg = l.registerErrorAgreeTermsSocial);
      return;
    }

    if (!await _ensureSignupLocation()) return;
    setState(() {
      _appleLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await AppleAuthService.signInWithApple(
        role: _role!,
        referralCode: (_referralCtrl.text.trim().isNotEmpty)
            ? _referralCtrl.text.trim()
            : null,
        action: 'signup',
        termsAccepted: _acceptedTerms,
        location: _location,
        interests: _role == 'client' ? _selectedInterests : null,
        nutritionPlan: _role == 'client' ? _signupNutritionPlan : null,
        height: double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.')),
        weight: _role == 'client'
            ? double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'))
            : null,
      );

      await ReferralLinkService.instance.clear();
      final role = result.user['role'] as String? ?? _role!;
      final id = result.user['id'] as int? ?? 0;
      final firstName = result.user['firstName'] as String? ?? '';

      // Advisors awaiting approval stay on the success sheet.
      if (role == 'advisor' && !result.isApproved) {
        setState(() => _appleLoading = false);
        _showGoogleSuccess(firstName: firstName, role: role);
        return;
      }

      await ApiService.saveToken(result.accessToken);
      await ApiService.saveRole(role);
      await ApiService.saveUserData(id, firstName);
      await NotificationService.instance.getFCMToken();

      if (!mounted) return;

      Widget dest;
      switch (role) {
        case 'client':
          dest = HomeScreen(
            clientID: id,
            token: result.accessToken,
            firstName: firstName,
            onLogout: () async {
              await ApiService.clearToken();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const WelcomeScreen(),
                  transitionsBuilder: (_, a, __, child) =>
                      FadeTransition(opacity: a, child: child),
                  transitionDuration: const Duration(milliseconds: 500),
                ),
                (_) => false,
              );
            },
          );
          break;
        case 'coach':
          dest = const CoachOnboarding();
          break;
        default:
          setState(() {
            _errorMsg = AppLocalizations.of(context).registerErrorUnrecognizedRole(role);
            _appleLoading = false;
          });
          return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => dest,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'cancelled' ||
          msg.contains('canceled') ||
          msg.contains('1001')) {
        setState(() => _appleLoading = false);
        return;
      }
      if (kDebugMode) debugPrint('❌ APPLE REGISTER ERROR: ');
      setState(() {
        _errorMsg = msg;
        _appleLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ APPLE REGISTER ERROR: ');
      setState(() {
        _errorMsg = AppLocalizations.of(context).registerErrorAppleFailed;
        _appleLoading = false;
      });
    }
  }

  void _showGoogleSuccess({required String firstName, required String role}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cyprus,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              28,
              40,
              28,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.sand, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                l.registerSuccessTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                l.registerSuccessPendingApproval(firstName),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.sand,
                        AppColors.sand.withValues(alpha: 0.85)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sand.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    l.registerLogInButton,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.cyprus,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cyprus,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              28,
              40,
              28,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.sand, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                l.registerSuccessTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(
                    text: l.registerSuccessWelcomePrefix(_firstNameCtrl.text.trim()),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        height: 1.6),
                  ),
                  if (_role == 'coach')
                    TextSpan(
                      text: l.registerSuccessCoachBadgeNote,
                      style: const TextStyle(color: _orange, fontSize: 14, height: 1.6),
                    )
                  else if (_role == 'advisor')
                    TextSpan(
                      text: l.registerSuccessAdvisorPendingNote,
                      style: const TextStyle(color: _orange, fontSize: 14, height: 1.6),
                    )
                  else
                    TextSpan(
                      text: l.registerSuccessClientNote,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 14,
                          height: 1.6),
                    ),
                ]),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.sand,
                        AppColors.sand.withValues(alpha: 0.85)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sand.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    l.registerLogInButton,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.cyprus,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _prevStep();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // â”€â”€ Fond image + flou lÃ©ger, identique Ã  l'Ã©cran de login â”€â”€
              Positioned.fill(
                child: Image.asset(
                  _bgImageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (_, child, frame, __) => frame == null
                      ? Container(color: const Color(0xFF111111))
                      : child,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF111111)),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
              // â”€â”€ DÃ©gradÃ© de lisibilitÃ© (cyprus), identique au login â”€â”€
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.cyprus.withValues(alpha: 0.05),
                        AppColors.cyprus.withValues(alpha: 0.55),
                        AppColors.cyprus.withValues(alpha: 0.92),
                        AppColors.cyprus,
                      ],
                      stops: const [0.0, 0.28, 0.5, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(children: [
                  _buildTopBar(),
                  _buildStepper(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildStepHeader(),
                              const SizedBox(height: 28),
                              _buildStepContent(),
                              if (_errorMsg != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorBanner(),
                              ],
                              const SizedBox(height: 28),
                              _buildCTA(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
          ),
          const Spacer(),
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 20),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const total = 5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.sand
                        : active
                            ? AppColors.sand.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 6),
            ]),
          );
        }),
      ),
    );
  }

  List<String> _stepLabels(AppLocalizations l) => [
    l.registerStep1Label,
    l.registerStep2Label,
    l.registerStep3Label,
    l.registerStep4Label,
    l.registerStep5Label,
  ];
  List<String> _stepTitles(AppLocalizations l) => [
    l.registerStep1Title,
    l.registerStep2Title,
    l.registerStep3Title,
    l.registerStep4Title,
    l.registerStep5Title,
  ];
  List<String> _stepSubs(AppLocalizations l) => [
    l.registerStep1Sub,
    l.registerStep2Sub,
    l.registerStep3Sub,
    l.registerStep4Sub,
    l.registerStep5Sub,
  ];

  Widget _buildStepHeader() {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.sand.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _stepLabels(l)[_step],
          style: const TextStyle(
            color: AppColors.sand,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _stepTitles(l)[_step],
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.08,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _stepSubs(l)[_step],
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    ]);
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep4() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegisterField(
          controller: _otpCtrl,
          label: l.registerOtpLabel,
          hint: l.registerOtpHint,
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l.registerOtpSentTo(_emailCtrl.text.trim()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loading ? null : _sendSignUpOTP,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.sand, size: 16),
              label: Text(l.registerOtpResend,
                  style: const TextStyle(color: AppColors.sand, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  // Step 0: Role Selection
  Widget _buildStep0() {
    final l = AppLocalizations.of(context);
    return Column(children: [
      _RoleTile(
        label: l.registerRoleClientLabel,
        description: l.registerRoleClientDesc,
        icon: Icons.person_rounded,
        selected: _role == 'client',
        onTap: () => setState(() {
          _role = 'client';
          _errorMsg = null;
        }),
      ),
      const SizedBox(height: 12),
      _RoleTile(
        label: l.registerRoleCoachLabel,
        description: l.registerRoleCoachDesc,
        icon: Icons.fitness_center_rounded,
        selected: _role == 'coach',
        onTap: () => setState(() {
          _role = 'coach';
          _errorMsg = null;
        }),
      ),
      const SizedBox(height: 24),
      if (_role != null) ...[
        _RegisterField(
            controller: _referralCtrl,
            label: l.registerInviterCodeLabel,
            hint: l.registerInviterCodeHint,
            icon: Icons.card_giftcard_rounded,
            onChanged: _onReferralChanged,
            suffix: _referralSuffixIcon()),
        const SizedBox(height: 20),
      ],
      _buildOrDivider(),
      const SizedBox(height: 20),
      _buildTermsAcceptanceTile(),
      const SizedBox(height: 16),
      _buildGoogleButton(),
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
        const SizedBox(height: 12),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
          _buildAppleButton(),
      ],
    ]);
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.15), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppLocalizations.of(context).registerOr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.15), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final l = AppLocalizations.of(context);
    final enabled =
        _role != null && !_googleLoading && !_loading && !_appleLoading;
    return GestureDetector(
      onTap: enabled ? _registerWithGoogle : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Center(
            child: _googleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.sand,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(
                        _googleLogoSvg,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _role == null
                            ? l.registerSelectRoleFirst
                            : l.registerContinueGoogle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    final l = AppLocalizations.of(context);
    final enabled =
        _role != null && !_appleLoading && !_loading && !_googleLoading;
    return GestureDetector(
      onTap: enabled ? _registerWithApple : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _appleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple_rounded,
                          color: Colors.black, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        l.registerContinueApple,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _localizedNutritionGoalLabel(String? goalType, AppLocalizations l) {
    switch (goalType) {
      case 'balanced':
        return l.registerNutritionGoalBalanced;
      case 'lose':
        return l.registerNutritionGoalLose;
      case 'gain':
        return l.registerNutritionGoalGain;
      case 'maintain':
        return l.registerNutritionGoalMaintain;
      default:
        return l.registerNutritionGoalPersonal;
    }
  }

  String _localizedSpecialtyLabel(String raw, AppLocalizations l) {
    switch (raw) {
      case 'Musculation':
        return l.registerSpecialtyStrength;
      case 'Perte de poids':
        return l.registerSpecialtyWeightLoss;
      case 'Yoga':
        return l.registerSpecialtyYoga;
      case 'CrossFit':
        return l.registerSpecialtyCrossFit;
      case 'Boxe':
        return l.registerSpecialtyBoxing;
      case 'Nutrition':
        return l.registerSpecialtyNutrition;
      case 'Pilates':
        return l.registerSpecialtyPilates;
      case 'Cardio':
        return l.registerSpecialtyCardio;
      case 'Stretching':
        return l.registerSpecialtyStretching;
      case 'Functional Training':
        return l.registerSpecialtyFunctional;
      default:
        return raw;
    }
  }

  // Step 1: Identity
  Widget _buildStep1() {
    final l = AppLocalizations.of(context);
    return Column(children: [
      Row(children: [
        Expanded(
          child: _RegisterField(
            controller: _firstNameCtrl,
            label: l.registerFirstNameLabel,
            hint: l.registerFirstNameHint,
            icon: Icons.person_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RegisterField(
            controller: _lastNameCtrl,
            label: l.registerLastNameLabel,
            hint: l.registerLastNameHint,
            icon: Icons.badge_rounded,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _RegisterField(
        controller: _emailCtrl,
        label: l.registerEmailLabel,
        hint: l.registerEmailHint,
        icon: Icons.email_rounded,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      _RegisterField(
        controller: _heightCtrl,
        label: l.registerHeightLabel,
        hint: l.registerHeightHint,
        icon: Icons.straighten_rounded,
        keyboardType: TextInputType.number,
      ),
      if (_role == 'client') ...[
        const SizedBox(height: 14),
        _RegisterField(
            controller: _weightCtrl,
            label: l.registerWeightLabel,
            hint: l.registerWeightHint,
            icon: Icons.monitor_weight_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      ],
      if (_role == 'coach' || _role == 'advisor') ...[
        const SizedBox(height: 14),
        _buildSpecialtiesSelector(),
      ],
      if (_role == 'client') ...[
        const SizedBox(height: 14),
        _buildSpecialtiesSelector(interests: true),
        const SizedBox(height: 14),
        Card(
            child: ListTile(
                leading: Icon(
                  _nutritionPlan != null
                      ? Icons.flag_rounded
                      : Icons.flag_outlined,
                  color: _nutritionPlan != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(l.registerNutritionGoalTitle),
                subtitle: Text(_nutritionPlan != null
                    ? _localizedNutritionGoalLabel(_nutritionPlan!['goalType'] as String?, l)
                    : (_skippedNutritionGoal
                        ? l.registerNutritionGoalSkipped
                        : l.registerNutritionGoalOptional)),
                trailing: _nutritionPlan != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: l.registerNutritionGoalClearTooltip,
                        onPressed: () => setState(() {
                          _nutritionPlan = null;
                          _skippedNutritionGoal = true;
                        }),
                      )
                    : (_skippedNutritionGoal
                        ? const Icon(Icons.chevron_right)
                        : TextButton(
                            onPressed: () => setState(() {
                              _skippedNutritionGoal = true;
                            }),
                            child: Text(l.registerNutritionGoalSkip,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          )),
                onTap: _chooseNutritionGoal)),
      ],
      if (_role == 'client' || _role == 'coach') ...[
        const SizedBox(height: 18),
        LocationPicker(
            initial: _location, onChanged: (value) => _location = value),
      ],
    ]);
  }

  Widget _buildSpecialtiesSelector(
      {bool interests = false, VoidCallback? update}) {
    final l = AppLocalizations.of(context);
    final selectedValues =
        interests ? _selectedInterests : _selectedSpecialties;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            interests
                ? l.registerInterestsHeader(selectedValues.length)
                : l.registerSpecialtiesHeader(selectedValues.length),
            style: TextStyle(
                color: update == null
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
            interests
                ? l.registerInterestsSub
                : l.registerSpecialtiesSub,
            style: TextStyle(
                color: update == null
                    ? Colors.white70
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _specialtyOptions.map((name) {
              final selected = selectedValues.contains(name);
              return FilterChip(
                  label: Text(_localizedSpecialtyLabel(name, l)),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF064B43)
                        : Colors.white.withValues(
                            alpha: selectedValues.length >= 5 ? 0.45 : 0.9),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  color: WidgetStateProperty.resolveWith((states) => states
                          .contains(WidgetState.selected)
                      ? const Color(0xFFF1F0E5)
                      : states.contains(WidgetState.disabled)
                          ? const Color(0xFF164B43).withValues(alpha: 0.3)
                          : const Color(0xFF164B43).withValues(alpha: 0.65)),
                  checkmarkColor: const Color(0xFF064B43),
                  side: BorderSide(
                      color: selected
                          ? const Color(0xFFF1F0E5)
                          : Colors.white.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  selected: selected,
                  onSelected: !selected && selectedValues.length >= 5
                      ? null
                      : (value) => setState(() {
                            if (value) {
                              selectedValues.add(name);
                            } else {
                              selectedValues.remove(name);
                            }
                            update?.call();
                          }));
            }).toList()),
      ],
    );
  }

  // Step 2: Security
  Widget _buildStep2() {
    final l = AppLocalizations.of(context);
    return Column(children: [
      _RegisterField(
        controller: _passwordCtrl,
        label: l.registerPasswordLabel,
        hint: l.registerPasswordHint,
        icon: Icons.lock_rounded,
        obscure: _obscurePass,
        showToggle: true,
        obscureValue: _obscurePass,
        onToggle: () => setState(() => _obscurePass = !_obscurePass),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      _RegisterField(
        controller: _confirmCtrl,
        label: l.registerConfirmPasswordLabel,
        hint: l.registerConfirmPasswordHint,
        icon: Icons.lock_outline_rounded,
        obscure: _obscureConf,
        showToggle: true,
        obscureValue: _obscureConf,
        onToggle: () => setState(() => _obscureConf = !_obscureConf),
      ),
      const SizedBox(height: 16),
      _PasswordStrengthBar(password: _passwordCtrl.text),
    ]);
  }

  // Step 3: Gender & Legal Agreement
  Widget _buildStep3() {
    final l = AppLocalizations.of(context);
    return Column(children: [
      _GenderTile(
        label: l.registerGenderMale,
        icon: Icons.male_rounded,
        selected: _gender == 'Male',
        onTap: () => setState(() => _gender = 'Male'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: l.registerGenderFemale,
        icon: Icons.female_rounded,
        selected: _gender == 'Female',
        onTap: () => setState(() => _gender = 'Female'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: l.registerGenderOther,
        icon: Icons.person_outline_rounded,
        selected: _gender == 'Other',
        onTap: () => setState(() => _gender = 'Other'),
      ),
      if (_role == 'coach' || _role == 'client') ...[
        const SizedBox(height: 20),
        _RegisterField(
          controller: _referralCtrl,
          label: l.registerInvitationCodeLabel,
          hint: l.registerInvitationCodeHint,
          icon: Icons.card_giftcard_rounded,
          onChanged: _onReferralChanged,
          suffix: _referralSuffixIcon(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            l.registerInvitationCodeHelper,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4),
          ),
        ),
        if (_referralStatus == _ReferralStatus.invalid) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(l.registerInvitationCodeInvalid,
                style: const TextStyle(color: _red, fontSize: 12)),
          ),
        ] else if (_referralStatus == _ReferralStatus.valid) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(l.registerInvitationCodeValid,
                style: const TextStyle(color: _green, fontSize: 12)),
          ),
        ],
      ],
    ]);
  }

  Widget _buildTermsAcceptanceTile() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _acceptedTerms
            ? AppColors.sand.withValues(alpha: 0.12)
            : AppColors.cyprus.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _acceptedTerms
              ? AppColors.sand
              : Colors.white.withValues(alpha: 0.2),
          width: _acceptedTerms ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _acceptedTerms ? AppColors.sand : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _acceptedTerms
                          ? AppColors.sand
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: _acceptedTerms
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.cyprus)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: l.registerTermsAgreePrefix,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: l.registerTermsAgreeLink,
                          style: const TextStyle(
                            color: AppColors.sand,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: l.registerTermsAgreeSuffix,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showTermsModal(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppColors.sand.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.description_rounded,
                  size: 14, color: AppColors.sand),
              label: Text(
                l.registerTermsReadButton,
                style: const TextStyle(
                  color: AppColors.sand,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cyprus,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.gavel_rounded,
                          color: AppColors.sand, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.registerTermsModalHeader,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegalTextSection(
                            l.registerTermsSecGeneralTitle,
                            l.registerTermsSecGeneralBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecScopeTitle,
                            l.registerTermsSecScopeBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecDefsTitle,
                            l.registerTermsSecDefsBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecTosTitle,
                            l.registerTermsSecTosBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecPrivacyTitle,
                            l.registerTermsSecPrivacyBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecHealthTitle,
                            l.registerTermsSecHealthBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecOpenSourceTitle,
                            l.registerTermsSecOpenSourceBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecCoachTitle,
                            l.registerTermsSecCoachBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecCommunityTitle,
                            l.registerTermsSecCommunityBody,
                          ),
                          _buildLegalTextSection(
                            l.registerTermsSecBookingTitle,
                            l.registerTermsSecBookingBody,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _acceptedTerms = true);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sand,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      l.registerTermsAcceptButton,
                      style: const TextStyle(
                        color: AppColors.cyprus,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegalTextSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.sand,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    final l = AppLocalizations.of(context);
    return Column(children: [
      _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.sand,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : _PressableScale(
              onTap: _nextStep,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.sand,
                      AppColors.sand.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sand.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _step < 4
                            ? Icons.arrow_forward_rounded
                            : Icons.check_circle_rounded,
                        color: AppColors.cyprus,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _step < 4 ? l.registerCtaContinue : l.registerCtaVerifyCreate,
                        style: const TextStyle(
                          color: AppColors.cyprus,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      if (_step == 0) ...[
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.15),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                l.registerAlreadyRegistered,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.15),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LoginScreen(),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ),
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.sand.withValues(alpha: 0.15),
            highlightColor: AppColors.sand.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.sand.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, color: AppColors.sand, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    l.registerCtaLogIn,
                    style: const TextStyle(
                      color: AppColors.sand,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.fitlek.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: context.fitlek.error.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.fitlek.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: context.fitlek.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg ?? '',
              style: TextStyle(
                color: context.fitlek.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Applique un lÃ©ger effet d'Ã©chelle au tap, pour un feedback tactile
/// (identique au comportement du bouton CTA de l'Ã©cran de login).
class _PressableScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _PressableScale({required this.onTap, required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setScale(double value) {
    if (widget.onTap == null) return;
    setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// â”€â”€â”€ Role Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleTile extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sand.withValues(alpha: 0.10)
              : AppColors.cyprus.withValues(alpha: 0.45),
          border: Border.all(
            color: selected
                ? AppColors.sand
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.sand, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: selected ? 1 : 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.sand : Colors.transparent,
              border: Border.all(
                color: selected
                    ? AppColors.sand
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    size: 13, color: AppColors.cyprus)
                : null,
          ),
        ]),
      ),
    );
  }
}

// â”€â”€â”€ Gender Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GenderTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sand.withValues(alpha: 0.10)
              : AppColors.cyprus.withValues(alpha: 0.45),
          border: Border.all(
            color: selected
                ? AppColors.sand
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected
                  ? AppColors.sand
                  : Colors.white.withValues(alpha: 0.55),
              size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.sand : Colors.transparent,
              border: Border.all(
                color: selected
                    ? AppColors.sand
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    size: 12, color: AppColors.cyprus)
                : null,
          ),
        ]),
      ),
    );
  }
}

// â”€â”€â”€ Password Strength Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 6) s++;
    if (password.length >= 10) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(password)) s++;
    return s.clamp(0, 4);
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return AppColors.sand;
      default:
        return Colors.white.withValues(alpha: 0.15);
    }
  }

  String _label(AppLocalizations l) {
    switch (_strength) {
      case 1:
        return l.registerPasswordWeak;
      case 2:
        return l.registerPasswordMedium;
      case 3:
        return l.registerPasswordGood;
      case 4:
        return l.registerPasswordStrong;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 4),
              height: 4,
              decoration: BoxDecoration(
                color: i < _strength
                    ? _strengthColor
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l.registerPasswordSecurity(_label(l)),
        style: TextStyle(
          color: _strengthColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

// â”€â”€â”€ Form Field (mÃªme look que _LoginField de login.dart) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RegisterField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final bool showToggle;
  final bool obscureValue;
  final VoidCallback? onToggle;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.showToggle = false,
    this.obscureValue = false,
    this.onToggle,
    this.onChanged,
    this.suffix,
  });

  @override
  State<_RegisterField> createState() => _RegisterFieldState();
}

class _RegisterFieldState extends State<_RegisterField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: _isFocused
                ? AppColors.sand
                : Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? AppColors.sand.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.12),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.sand.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _isFocused
                      ? AppColors.sand.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: _isFocused
                      ? AppColors.sand
                      : Colors.white.withValues(alpha: 0.45),
                  size: 17,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscure,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              if (widget.showToggle)
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.obscureValue
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey(widget.obscureValue),
                        color: _isFocused
                            ? AppColors.sand.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.35),
                        size: 20,
                      ),
                    ),
                  ),
                )
              else if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: widget.suffix!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Notice Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
