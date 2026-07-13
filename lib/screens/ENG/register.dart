import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'welcome.dart';

import '../../theme/fitlek_theme_extension.dart';
import '../../components/sirvya_logo.dart';

enum _ReferralStatus { idle, checking, valid, invalid }

// ─── Palette ────────────────────────────────────────────────────────────────
const _orange = Color(0xFFFFB74D);
const _blue = Color(0xFF64B5F6);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFFF5252);

const _baseUrl = 'http://localhost:3000/api';

const _bgImageUrl =
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1400&auto=format&fit=crop';

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bgImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Theme.of(context).scaffoldBackgroundColor),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                  color: Theme.of(context).scaffoldBackgroundColor);
            },
          ),
          Container(
              color:
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.55)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xCC0A0A0A),
                  const Color(0xE60A0A0A),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: context.fitlek.card,
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
              color: _roleColor(_role).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.check_rounded, color: _roleColor(_role), size: 40),
          ),
          const SizedBox(height: 24),
          Text('Account created!',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'Welcome ${_firstNameCtrl.text.trim()}. ',
                style: TextStyle(
                    color: context.fitlek.textMuted, fontSize: 14, height: 1.6),
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
                      color: context.fitlek.textMuted,
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
                color: _roleColor(_role),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _roleColor(_role).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text('Log in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        ]),
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'coach':
        return Theme.of(context).colorScheme.primary;
      case 'advisor':
        return _blue;
      default:
        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _RegisterBackground(),
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
                          const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Theme.of(context).colorScheme.onSurface),
          ),
          const Spacer(),
          const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 26),
          const SizedBox(width: 10),
          Text(
            'Sign up',
            style: TextStyle(
              color: context.fitlek.textMuted,
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const total = 4;
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
                        ? _roleColor(_role)
                        : active
                            ? _roleColor(_role).withValues(alpha: 0.4)
                            : context.fitlek.border,
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
      Text(_stepLabels[_step],
          style: TextStyle(
              color: _roleColor(_role),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8)),
      const SizedBox(height: 8),
      Text(_stepTitles[_step],
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.1)),
      const SizedBox(height: 10),
      Text(_stepSubs[_step],
          style: TextStyle(
              color: context.fitlek.textMuted, fontSize: 14, height: 1.5)),
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
        role: 'client',
        label: 'Client',
        description: 'Find a coach and book sessions.',
        icon: Icons.person_rounded,
        color: _green,
        selected: _role == 'client',
        onTap: () => setState(() {
          _role = 'client';
          _errorMsg = null;
        }),
      ),
      const SizedBox(height: 12),
      _RoleTile(
        role: 'coach',
        label: 'Coach',
        description: 'Manage your clients and grow your business.',
        icon: Icons.fitness_center_rounded,
        color: Theme.of(context).colorScheme.primary,
        selected: _role == 'coach',
        onTap: () => setState(() {
          _role = 'coach';
          _errorMsg = null;
        }),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // Step 1: Identity
  Widget _buildStep1() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: _FitField(
            controller: _firstNameCtrl,
            label: 'First name',
            hint: 'Anas',
            accentColor: _roleColor(_role),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FitField(
            controller: _lastNameCtrl,
            label: 'Last name',
            hint: 'Benali',
            accentColor: _roleColor(_role),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      _FitField(
        controller: _emailCtrl,
        label: 'Email',
        hint: 'you@email.ma',
        keyboardType: TextInputType.emailAddress,
        accentColor: _roleColor(_role),
      ),
      const SizedBox(height: 16),
      _FitField(
        controller: _heightCtrl,
        label: 'Height (cm)',
        hint: '175',
        keyboardType: TextInputType.number,
        accentColor: _roleColor(_role),
      ),
    ]);
  }

  // Step 2: Security
  Widget _buildStep2() {
    return Column(children: [
      _FitField(
        controller: _passwordCtrl,
        label: 'Password',
        hint: '••••••••',
        obscure: _obscurePass,
        accentColor: _roleColor(_role),
        suffix: IconButton(
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
          icon: Icon(
            _obscurePass
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: context.fitlek.textMuted,
            size: 20,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _FitField(
        controller: _confirmCtrl,
        label: 'Confirm password',
        hint: '••••••••',
        obscure: _obscureConf,
        accentColor: _roleColor(_role),
        suffix: IconButton(
          onPressed: () => setState(() => _obscureConf = !_obscureConf),
          icon: Icon(
            _obscureConf
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: context.fitlek.textMuted,
            size: 20,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _PasswordStrengthBar(
        password: _passwordCtrl.text,
        accentColor: _roleColor(_role),
      ),
    ]);
  }

  // Step 3: Gender
  Widget _buildStep3() {
    return Column(children: [
      _GenderTile(
        label: 'Male',
        icon: Icons.male_rounded,
        selected: _gender == 'Male',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Male'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Female',
        icon: Icons.female_rounded,
        selected: _gender == 'Female',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Female'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Other',
        icon: Icons.person_outline_rounded,
        selected: _gender == 'Other',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Other'),
      ),
      if (_role == 'coach') ...[
        const SizedBox(height: 20),
        _FitField(
          controller: _referralCtrl,
          label: 'Invitation code (optional)',
          hint: 'e.g. A1B2C3D4E5F6',
          accentColor: _roleColor(_role),
          onChanged: _onReferralChanged,
          suffix: _referralSuffixIcon(),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a Coach referral code if another Coach invited you.',
          style: TextStyle(
              color: context.fitlek.textMuted, fontSize: 12, height: 1.4),
        ),
        if (_referralStatus == _ReferralStatus.invalid) ...[
          const SizedBox(height: 6),
          const Text('This code is not recognized.',
              style: TextStyle(color: _red, fontSize: 12)),
        ] else if (_referralStatus == _ReferralStatus.valid) ...[
          const SizedBox(height: 6),
          const Text('Valid coach code',
              style: TextStyle(color: _green, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        _NoticeBanner(
          role: _role!,
          roleColor: _roleColor(_role),
        ),
      ],
    ]);
  }

  Widget _buildCTA() {
    return Column(children: [
      _loading
          ? Center(
              child: CircularProgressIndicator(
                color: _roleColor(_role),
                strokeWidth: 2.5,
              ),
            )
          : GestureDetector(
              onTap: _nextStep,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _roleColor(_role),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _roleColor(_role).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _step < 3 ? 'CONTINUE' : 'CREATE MY ACCOUNT',
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _step < 3
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
      const SizedBox(height: 16),
      if (_step == 0)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            'Already registered? ',
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 13),
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
              'Log in',
              style: TextStyle(
                color: _roleColor(_role),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
          child: Text(
            _errorMsg ?? '',
            style: const TextStyle(color: _red, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}

// ─── Role Tile ────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  final String role, label, description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
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
              ? color.withValues(alpha: 0.10)
              : context.fitlek.card.withValues(alpha: 0.72),
          border: Border.all(
            color: selected ? color : context.fitlek.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: context.fitlek.textMuted,
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
              color: selected ? color : Colors.transparent,
              border: Border.all(
                color: selected ? color : context.fitlek.border,
                width: 1.5,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded,
                    size: 13, color: Theme.of(context).scaffoldBackgroundColor)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Gender Tile ───────────────────────────────────────────────────────────────

class _GenderTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _GenderTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.accentColor,
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
              ? accentColor.withValues(alpha: 0.10)
              : context.fitlek.card.withValues(alpha: 0.72),
          border: Border.all(
            color: selected ? accentColor : context.fitlek.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? accentColor : context.fitlek.textMuted,
              size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : context.fitlek.textMuted,
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
              color: selected ? accentColor : Colors.transparent,
              border: Border.all(
                color: selected ? accentColor : context.fitlek.border,
                width: 1.5,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded,
                    size: 12, color: Theme.of(context).scaffoldBackgroundColor)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Password Strength Bar ────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  final Color accentColor;

  const _PasswordStrengthBar({
    required this.password,
    required this.accentColor,
  });

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

  Color _strengthColor(BuildContext context) {
    switch (_strength) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return accentColor;
      default:
        return context.fitlek.border;
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
                color: i < _strength
                    ? _strengthColor(context)
                    : context.fitlek.border,
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
          color: _strengthColor(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);
  }
}

// ─── Form Field ────────────────────────────────────────────────────────────────

class _FitField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final Color accentColor;
  final void Function(String)? onChanged;

  const _FitField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    required this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: context.fitlek.card.withValues(alpha: 0.72),
          border: Border.all(color: context.fitlek.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.fitlek.textMuted, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: suffix,
          ),
        ),
      ),
    ]);
  }
}

// ─── Notice Banner ────────────────────────────────────────────────────────────

class _NoticeBanner extends StatelessWidget {
  final String role;
  final Color roleColor;

  const _NoticeBanner({
    required this.role,
    required this.roleColor,
  });

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
                color: context.fitlek.textMuted,
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
