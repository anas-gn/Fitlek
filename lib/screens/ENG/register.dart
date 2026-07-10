import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'welcome.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _border = Color(0xFF232323);
const _muted = Color(0xFF888888);
const _white = Color(0xFFFFFFFF);
const _orange = Color(0xFFFFB74D);
const _blue = Color(0xFF64B5F6);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFFF5252);

const _baseUrl = 'http://192.168.0.232:3000/api';

const _bgImageUrl =
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1400&auto=format&fit=crop';

class _FitlekLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color circleColor;

  const _FitlekLogoPainter({required this.strokeColor, required this.circleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 132;
    final scaleY = size.height / 120;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    canvas.drawCircle(const Offset(65.6104, 17.25), 17.25, Paint()..color = circleColor);

    final path = Path()
      ..moveTo(5.8103, 21.85)
      ..cubicTo(19.2827, 35.9, 45.0007, 47.25, 64.4603, 47.7336)
      ..moveTo(125.41, 21.85)
      ..cubicTo(112.388, 36.0329, 83.709, 48.212, 64.4603, 47.7336)
      ..moveTo(64.4603, 47.7336)
      ..lineTo(64.4603, 106.95)
      ..cubicTo(87.8436, 95.8333, 128.4, 73.37, 103.56, 72.45)
      ..cubicTo(78.7203, 71.53, 36.477, 72.0666, 18.4603, 72.45);

    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FitlekLogoPainter oldDelegate) => false;
}

class _FitlekLogo extends StatelessWidget {
  final double height;
  const _FitlekLogo({this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * 132 / 120,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _lime.withOpacity(0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
      ),
    );
  }
}

class _LogoWatermark extends StatelessWidget {
  final double size;
  const _LogoWatermark({this.size = 340});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.035,
        child: SizedBox(
          width: size,
          height: size * 120 / 132,
          child: CustomPaint(
            painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
          ),
        ),
      ),
    );
  }
}

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
            errorBuilder: (_, __, ___) => Container(color: _dark),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: _dark);
            },
          ),
          Container(color: _dark.withOpacity(0.55)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0A0A0A),
                  Color(0xE60A0A0A),
                  _dark,
                ],
                stops: [0.0, 0.45, 1.0],
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
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    super.dispose();
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
        return _role == null ? 'Sélectionne ton rôle pour continuer' : null;
      case 1:
        if (_firstNameCtrl.text.trim().isEmpty) return 'Prénom requis';
        if (_lastNameCtrl.text.trim().isEmpty) return 'Nom requis';
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(_emailCtrl.text.trim())) return 'Email invalide';
        if (_heightCtrl.text.trim().isEmpty) return 'Taille requise';
        if (double.tryParse(_heightCtrl.text.trim()) == null) return 'Taille invalide';
        return null;
      case 2:
        if (_passwordCtrl.text.length < 6) return 'Mot de passe trop court (min 6 car.)';
        if (_passwordCtrl.text != _confirmCtrl.text) return 'Les mots de passe ne correspondent pas';
        return null;
      case 3:
        return _gender == null ? 'Sélectionne ton genre pour continuer' : null;
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
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim().toLowerCase(),
          'password': _passwordCtrl.text,
          'gender': _gender,
          'role': _role,
          'height': double.tryParse(_heightCtrl.text.trim()),
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        if (!mounted) return;
        _showSuccess();
      } else {
        setState(() =>
            _errorMsg = data['error'] as String? ?? 'Erreur lors de l\'inscription');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Impossible de contacter le serveur');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
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
              color: _roleColor(_role).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: _roleColor(_role), size: 40),
          ),
          const SizedBox(height: 24),
          Text('Compte créé !',
              style: const TextStyle(
                  color: _white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'Bienvenue ${_firstNameCtrl.text.trim()}. ',
                style: const TextStyle(
                    color: _muted, fontSize: 14, height: 1.6),
              ),
              if (_role == 'coach' || _role == 'advisor')
                const TextSpan(
                  text: 'Ton compte est en attente d\'approbation.',
                  style: TextStyle(color: _orange, fontSize: 14, height: 1.6),
                )
              else
                const TextSpan(
                  text: 'Tu peux maintenant te connecter.',
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
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
                    color: _roleColor(_role).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text('Se connecter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _dark,
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
        return _lime;
      case 'advisor':
        return _blue;
      default:
        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _white),
          ),
          const Spacer(),
          const _FitlekLogo(height: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'FIT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _lime,
                        letterSpacing: 2.5,
                      ),
                    ),
                    TextSpan(
                      text: 'LEK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _white,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Inscription',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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
                            ? _roleColor(_role).withOpacity(0.4)
                            : _border,
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
    'ÉTAPE 1 / 4',
    'ÉTAPE 2 / 4',
    'ÉTAPE 3 / 4',
    'ÉTAPE 4 / 4'
  ];
  static const _stepTitles = [
    'Quel est\nton rôle ?',
    'Qui es-tu ?',
    'Sécurise\nton compte',
    'Une dernière\nchose'
  ];
  static const _stepSubs = [
    'Choisis comment tu vas utiliser Fitlek.',
    'Dis-nous comment t\'appeler.',
    'Crée un mot de passe solide.',
    'Pour personnaliser ton expérience.',
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
          style: const TextStyle(
              color: _white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
      const SizedBox(height: 10),
      Text(_stepSubs[_step],
          style: const TextStyle(color: _muted, fontSize: 14, height: 1.5)),
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
        description: 'Trouve un coach et réserve des séances.',
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
        description: 'Gère tes clients et développe ton activité.',
        icon: Icons.fitness_center_rounded,
        color: _lime,
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
            label: 'Prénom',
            hint: 'Anas',
            accentColor: _roleColor(_role),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FitField(
            controller: _lastNameCtrl,
            label: 'Nom',
            hint: 'Benali',
            accentColor: _roleColor(_role),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      _FitField(
        controller: _emailCtrl,
        label: 'Email',
        hint: 'ton@email.ma',
        keyboardType: TextInputType.emailAddress,
        accentColor: _roleColor(_role),
      ),
      const SizedBox(height: 16),
      _FitField(
        controller: _heightCtrl,
        label: 'Taille (cm)',
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
        label: 'Mot de passe',
        hint: '••••••••',
        obscure: _obscurePass,
        accentColor: _roleColor(_role),
        suffix: IconButton(
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
          icon: Icon(
            _obscurePass
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: _muted,
            size: 20,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      _FitField(
        controller: _confirmCtrl,
        label: 'Confirmer le mot de passe',
        hint: '••••••••',
        obscure: _obscureConf,
        accentColor: _roleColor(_role),
        suffix: IconButton(
          onPressed: () => setState(() => _obscureConf = !_obscureConf),
          icon: Icon(
            _obscureConf
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: _muted,
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
        label: 'Homme',
        icon: Icons.male_rounded,
        selected: _gender == 'Male',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Male'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Femme',
        icon: Icons.female_rounded,
        selected: _gender == 'Female',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Female'),
      ),
      const SizedBox(height: 12),
      _GenderTile(
        label: 'Autre',
        icon: Icons.person_outline_rounded,
        selected: _gender == 'Other',
        accentColor: _roleColor(_role),
        onTap: () => setState(() => _gender = 'Other'),
      ),
      if (_role == 'coach') ...[
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
                      color: _roleColor(_role).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _step < 3 ? 'CONTINUER' : 'CRÉER MON COMPTE',
                      style: const TextStyle(
                        color: _dark,
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
                      color: _dark,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
      const SizedBox(height: 16),
      if (_step == 0)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text(
            'Déjà inscrit ? ',
            style: TextStyle(color: _muted, fontSize: 13),
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
              'Se connecter',
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
        color: _red.withOpacity(0.1),
        border: Border.all(color: _red.withOpacity(0.35)),
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
          color: selected ? color.withOpacity(0.10) : _card.withOpacity(0.72),
          border: Border.all(
            color: selected ? color : _border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
                    color: selected ? _white : _white.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
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
                color: selected ? color : _border,
                width: 1.5,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 13, color: _dark)
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
          color: selected ? accentColor.withOpacity(0.10) : _card.withOpacity(0.72),
          border: Border.all(
            color: selected ? accentColor : _border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? accentColor : _muted,
              size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: selected ? _white : _muted,
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
                color: selected ? accentColor : _border,
                width: 1.5,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 12, color: _dark)
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

  Color get _color {
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
        return _border;
    }
  }

  String get _label {
    switch (_strength) {
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Bien';
      case 4:
        return 'Fort';
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
                color: i < _strength ? _color : _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Sécurité : $_label',
        style: TextStyle(
          color: _color,
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
          color: accentColor.withOpacity(0.75),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _card.withOpacity(0.72),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: _white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _muted, fontSize: 15),
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
        color: _orange.withOpacity(0.08),
        border: Border.all(color: _orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: _orange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Validation requise',
              style: TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCoach
                  ? 'Ton compte coach sera examiné par un conseiller. Tu pourras exercer une fois approuvé(e).'
                  : 'Ton compte conseiller sera activé après vérification par l\'administration.',
              style: const TextStyle(
                color: _muted,
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