import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../../constants/app_colors.dart';

const _red = Color(0xFFFF5252);
const _bgImageUrl =
    'assets/branding/sirvya2.jfif';

class ClientForgotScreen extends StatefulWidget {
  const ClientForgotScreen({super.key});

  @override
  State<ClientForgotScreen> createState() => _ClientForgotScreenState();
}

class _ClientForgotScreenState extends State<ClientForgotScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0;
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading = false;
  String? _errorMsg;

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
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(_emailCtrl.text.trim())) {
          return l.clientForgotErrorInvalidEmail;
        }
        return null;
      case 1:
        if (_otpCtrl.text.trim().length != 6) {
          return l.clientForgotErrorOtpLength;
        }
        return null;
      case 2:
        if (_passwordCtrl.text.length < 6) return l.clientForgotErrorPasswordShort;
        if (_passwordCtrl.text != _confirmCtrl.text) return l.clientForgotErrorPasswordsMismatch;
        return null;
      default:
        return null;
    }
  }

  Future<void> _nextStep() async {
    final err = _validateStep(_step, AppLocalizations.of(context));
    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    if (_step == 0) {
      await _sendForgotOTP();
    } else if (_step == 1) {
      await _verifyForgotOTP();
    } else {
      await _resetPassword();
    }
  }

  Future<void> _sendForgotOTP() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-forgot-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        setState(() {
          _step = 1;
          _loading = false;
        });
        _animateStep();
      } else {
        setState(() {
          _errorMsg = data['error'] as String? ?? l.clientForgotErrorEmailNotFound;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = l.clientForgotErrorServerUnreachable;
        _loading = false;
      });
    }
  }

  Future<void> _verifyForgotOTP() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-forgot-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim().toLowerCase(),
          'otp': _otpCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['verified'] == true) {
        setState(() {
          _step = 2;
          _loading = false;
        });
        _animateStep();
      } else {
        setState(() {
          _errorMsg = data['error'] as String? ?? l.clientForgotErrorInvalidOtp;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = l.clientForgotErrorServerUnreachable;
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/reset-password-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim().toLowerCase(),
          'otp': _otpCtrl.text.trim(),
          'newPassword': _passwordCtrl.text,
        }),
      ).timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        if (!mounted) return;
        _showSuccess();
      } else {
        setState(() {
          _errorMsg = data['error'] as String? ?? l.clientForgotErrorResetFailed;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = l.clientForgotErrorServerUnreachable;
        _loading = false;
      });
    }
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
                28, 40, 28, 24 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: AppColors.sand, size: 38),
              ),
              const SizedBox(height: 24),
              Text(
                l.clientForgotSuccessTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                l.clientForgotSuccessMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                    (route) => false,
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
                    l.clientForgotLogInCta,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.cyprus,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
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
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300 &&
              !_loading) {
            _prevStep();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _bgImageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (_, child, frame, __) =>
                      frame == null ? Container(color: const Color(0xFF111111)) : child,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                  child:
                      Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
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
                              const SizedBox(height: 32),
                              _buildStepHeader(),
                              const SizedBox(height: 32),
                              _buildStepContent(),
                              if (_errorMsg != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorBanner(),
                              ],
                              const SizedBox(height: 40),
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
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
      child: Row(children: [
        IconButton(
          onPressed: _loading ? null : _prevStep,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
        ),
        const Spacer(),
      ]),
    );
  }

  Widget _buildStepper() {
    const total = 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
    l.clientForgotStep1Label,
    l.clientForgotStep2Label,
    l.clientForgotStep3Label,
  ];
  List<String> _stepTitles(AppLocalizations l) => [
    l.clientForgotStep1Title,
    l.clientForgotStep2Title,
    l.clientForgotStep3Title,
  ];
  List<String> _stepSubs(AppLocalizations l) => [
    l.clientForgotStep1Sub,
    l.clientForgotStep2Sub,
    l.clientForgotStep3Sub,
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
    final l = AppLocalizations.of(context);
    switch (_step) {
      case 0:
        return _FitField(
          controller: _emailCtrl,
          label: l.clientForgotEmailLabel,
          hint: l.clientForgotEmailHint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        );
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FitField(
            controller: _otpCtrl,
            label: l.clientForgotOtpLabel,
            hint: l.clientForgotOtpHint,
            icon: Icons.pin_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loading ? null : _sendForgotOTP,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.sand, size: 16),
            label: Text(l.clientForgotResendCode,
                style: const TextStyle(color: AppColors.sand, fontSize: 12)),
          ),
        ]);
      case 2:
        return Column(children: [
          _FitField(
            controller: _passwordCtrl,
            label: l.clientForgotNewPasswordLabel,
            hint: l.clientForgotNewPasswordHint,
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            showToggle: true,
            obscureValue: _obscurePass,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _FitField(
            controller: _confirmCtrl,
            label: l.clientForgotConfirmPasswordLabel,
            hint: l.clientForgotConfirmPasswordHint,
            icon: Icons.lock_rounded,
            obscure: _obscureConf,
            showToggle: true,
            obscureValue: _obscureConf,
            onToggle: () => setState(() => _obscureConf = !_obscureConf),
          ),
          const SizedBox(height: 16),
          _PasswordStrengthBar(password: _passwordCtrl.text),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCTA() {
    final l = AppLocalizations.of(context);
    final labels = [
      l.clientForgotCtaSendCode,
      l.clientForgotCtaVerifyCode,
      l.clientForgotCtaResetPassword,
    ];
    return Column(children: [
      _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: AppColors.sand, strokeWidth: 2.5),
              ),
            )
          : GestureDetector(
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
                      AppColors.sand.withValues(alpha: 0.85)
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
                  child: Text(
                    labels[_step],
                    style: const TextStyle(
                      color: AppColors.cyprus,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          l.clientForgotRememberPassword,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          ),
          child: Text(
            l.clientForgotLogInLink,
            style: const TextStyle(
                color: AppColors.sand,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.1),
        border: Border.all(color: _red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_errorMsg ?? '',
              style: const TextStyle(color: _red, fontSize: 13)),
        ),
      ]),
    );
  }
}

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
        return l.clientForgotPasswordWeak;
      case 2:
        return l.clientForgotPasswordMedium;
      case 3:
        return l.clientForgotPasswordGood;
      case 4:
        return l.clientForgotPasswordStrong;
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
        l.clientForgotPasswordSecurity(_label(l)),
        style: TextStyle(
            color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ]);
  }
}

class _FitField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool showToggle;
  final bool obscureValue;
  final TextInputType keyboardType;
  final VoidCallback? onToggle;
  final void Function(String)? onChanged;

  const _FitField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.showToggle = false,
    this.obscureValue = false,
    this.keyboardType = TextInputType.text,
    this.onToggle,
    this.onChanged,
  });

  @override
  State<_FitField> createState() => _FitFieldState();
}

class _FitFieldState extends State<_FitField> {
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        child: Row(children: [
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
            ),
        ]),
      ),
    ]);
  }
}