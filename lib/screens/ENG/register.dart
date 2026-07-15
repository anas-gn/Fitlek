import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'welcome.dart';

import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';

enum _ReferralStatus { idle, checking, valid, invalid }

// ─── Semantic status colors (kept for feedback only — not brand accents) ────
const _orange = Color(0xFFFFB74D);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFFF5252);

const _baseUrl = 'http://localhost:3000/api';

// Same background photo family as the login screen, for visual continuity.
const _bgImageUrl =
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80';

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
  final _referralCtrl = TextEditingController();

  Timer? _referralDebounce;
  _ReferralStatus _referralStatus = _ReferralStatus.idle;

  int _step = 0;
  String? _role;
  String? _gender;
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _heightCtrl.dispose();
    _referralCtrl.dispose();
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
              '$_baseUrl/auth/validate-referral?code=${Uri.encodeQueryComponent(code)}'))
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

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        return _role == null ? 'Select your role to continue' : null;
      case 1:
        if (_firstNameCtrl.text.trim().isEmpty) return 'First name required';
        if (_lastNameCtrl.text.trim().isEmpty) return 'Last name required';
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(_emailCtrl.text.trim())) {
          return 'Invalid email';
        }
        if (_heightCtrl.text.trim().isEmpty) return 'Height required';
        if (double.tryParse(_heightCtrl.text.trim()) == null) {
          return 'Invalid height';
        }
        return null;
      case 2:
        if (_passwordCtrl.text.length < 6) {
          return 'Password too short (min 6 chars)';
        }
        if (_passwordCtrl.text != _confirmCtrl.text) {
          return 'Passwords do not match';
        }
        return null;
      case 3:
        return _gender == null ? 'Select your gender to continue' : null;
      default:
        return null;
    }
  }

  void _nextStep() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      _animateStep();
    } else {
      _register();
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
        'height': double.tryParse(_heightCtrl.text.trim()),
      };
      if (_role == 'coach' && _referralCtrl.text.trim().isNotEmpty) {
        body['referralCode'] = _referralCtrl.text.trim();
      }
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        if (!mounted) return;
        _showSuccess();
      } else {
        setState(() =>
            _errorMsg = data['error'] as String? ?? 'Registration failed');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Unable to reach the server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cyprus,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
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
          const Text(
            'Account created!',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'Welcome ${_firstNameCtrl.text.trim()}. ',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.6),
              ),
              if (_role == 'coach' || _role == 'advisor')
                const TextSpan(
                  text: 'Your account is pending approval.',
                  style: TextStyle(color: _orange, fontSize: 14, height: 1.6),
                )
              else
                TextSpan(
                  text: 'You can now log in.',
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
                  colors: [AppColors.sand, AppColors.sand.withValues(alpha: 0.85)],
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
              child: const Text(
                'Log in',
                textAlign: TextAlign.center,
                style: TextStyle(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cyprus,
      body: Stack(
        children: [
          // ── Fond image + flou léger, identique à l'écran de login ──
          Positioned.fill(
            child: Image.network(
              _bgImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) =>
                  p == null ? child : Container(color: const Color(0xFF111111)),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          // ── Dégradé de lisibilité (cyprus), identique au login ──
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
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 54),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const total = 4;
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

  static const _stepLabels = [
    'STEP 1 / 4',
    'STEP 2 / 4',
    'STEP 3 / 4',
    'STEP 4 / 4'
  ];
  static const _stepTitles = [
    'What is\nyour role?',
    'Who are you?',
    'Secure\nyour account',
    'One last\nthing'
  ];
  static const _stepSubs = [
    'Choose how you\'ll use SIRVYA.',
    'Tell us what to call you.',
    'Create a strong password.',
    'To personalize your experience.',
  ];

  Widget _buildStepHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.sand.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _stepLabels[_step],
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
        _stepTitles[_step],
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
        _stepSubs[_step],
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
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Role Selection
  Widget _buildStep0() {
    return Column(children: [
      _RoleTile(
        label: 'Client',
        description: 'Find a coach and book sessions.',
        icon: Icons.person_rounded,
        selected: _role == 'client',
        onTap: () => setState(() {
          _role = 'client';
          _errorMsg = null;
        }),
      ),
      const SizedBox(height: 12),
      _RoleTile(
        label: 'Coach',
        description: 'Manage your clients and grow your business.',
        icon: Icons.fitness_center_rounded,
        selected: _role == 'coach',
        onTap: () => setState(() {
          _role = 'coach';
          _errorMsg = null;
        }),
      ),
    ]);
  }

  // Step 1: Identity
  Widget _buildStep1() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: _RegisterField(
            controller: _firstNameCtrl,
            label: 'First name',
            hint: 'Anas',
            icon: Icons.person_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RegisterField(
            controller: _lastNameCtrl,
            label: 'Last name',
            hint: 'Benali',
            icon: Icons.badge_rounded,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _RegisterField(
        controller: _emailCtrl,
        label: 'Email address',
        hint: 'you@email.ma',
        icon: Icons.email_rounded,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      _RegisterField(
        controller: _heightCtrl,
        label: 'Height (cm)',
        hint: '175',
        icon: Icons.straighten_rounded,
        keyboardType: TextInputType.number,
      ),
    ]);
  }

  // Step 2: Security
  Widget _buildStep2() {
    return Column(children: [
      _RegisterField(
        controller: _passwordCtrl,
        label: 'Password',
        hint: '••••••••',
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
        label: 'Confirm password',
        hint: '••••••••',
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

  // Step 3: Gender
  Widget _buildStep3() {
    return Column(children: [
      _GenderTile(
        label: 'Male',
        icon: Icons.male_rounded,
        selected: _gender == 'Male',
        onTap: () => setState(() => _gender = 'Male'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Female',
        icon: Icons.female_rounded,
        selected: _gender == 'Female',
        onTap: () => setState(() => _gender = 'Female'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Other',
        icon: Icons.person_outline_rounded,
        selected: _gender == 'Other',
        onTap: () => setState(() => _gender = 'Other'),
      ),
      if (_role == 'coach') ...[
        const SizedBox(height: 20),
        _RegisterField(
          controller: _referralCtrl,
          label: 'Invitation code (optional)',
          hint: 'e.g. A1B2C3D4E5F6',
          icon: Icons.card_giftcard_rounded,
          onChanged: _onReferralChanged,
          suffix: _referralSuffixIcon(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'Enter a Coach referral code if another Coach invited you.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4),
          ),
        ),
        if (_referralStatus == _ReferralStatus.invalid) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text('This code is not recognized.',
                style: TextStyle(color: _red, fontSize: 12)),
          ),
        ] else if (_referralStatus == _ReferralStatus.valid) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text('Valid coach code',
                style: TextStyle(color: _green, fontSize: 12)),
          ),
        ],
        const SizedBox(height: 20),
        _NoticeBanner(role: _role!),
      ],
    ]);
  }

  Widget _buildCTA() {
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
                        _step < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        color: AppColors.cyprus,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _step < 3 ? 'CONTINUE' : 'CREATE MY ACCOUNT',
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
                'Already registered?',
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: AppColors.sand, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'LOG IN',
                    style: TextStyle(
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

/// Applique un léger effet d'échelle au tap, pour un feedback tactile
/// (identique au comportement du bouton CTA de l'écran de login).
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

// ─── Role Tile ────────────────────────────────────────────────────────────

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
            color: selected ? AppColors.sand : Colors.white.withValues(alpha: 0.15),
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
                color: selected ? AppColors.sand : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 13, color: AppColors.cyprus)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Gender Tile ────────────────────────────────────────────────────────────

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
            color: selected ? AppColors.sand : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? AppColors.sand : Colors.white.withValues(alpha: 0.55),
              size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
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
                color: selected ? AppColors.sand : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 12, color: AppColors.cyprus)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Password Strength Bar ───────────────────────────────────────────────

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

  String get _label {
    switch (_strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Medium';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
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
                color: i < _strength ? _strengthColor : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Security: $_label',
        style: TextStyle(
          color: _strengthColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

// ─── Form Field (même look que _LoginField de login.dart) ──────────────────

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
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _isFocused ? AppColors.sand : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.cyprus.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? AppColors.sand.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.18),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: AppColors.sand.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
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
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: _isFocused ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: AppColors.sand, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: widget.showToggle
                  ? GestureDetector(
                      onTap: widget.onToggle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          widget.obscureValue
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 20,
                        ),
                      ),
                    )
                  : widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Notice Banner ───────────────────────────────────────────────────────

class _NoticeBanner extends StatelessWidget {
  final String role;

  const _NoticeBanner({required this.role});

  @override
  Widget build(BuildContext context) {
    final isCoach = role == 'coach';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.08),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: _orange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Approval required',
              style: TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCoach
                  ? 'Your coach account will be reviewed by an advisor. You can start once approved.'
                  : 'Your advisor account will be activated after verification by the administration.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}