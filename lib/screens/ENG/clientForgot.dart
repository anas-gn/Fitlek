import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _border = Color(0xFF232323);
const _muted = Color(0xFF888888);
const _white = Color(0xFFFFFFFF);
const _red = Color(0xFFFF5252);

const _baseUrl = 'http://192.168.0.232:3000/api';

// ─── Background Image URL (dark gym barbell) ──────────────────────────────
const _bgImageUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRS3dWtlrupEMLWcbrgWbDlQpjQBrdjco7z-PoA1RDtc7U6NU2UR7hjuBLo&s=10';






class ClientForgotScreen extends StatefulWidget {
  const ClientForgotScreen({super.key});

  @override
  State<ClientForgotScreen> createState() => _ClientForgotScreenState();
}

class _ClientForgotScreenState extends State<ClientForgotScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0 = email, 1 = nouveau mot de passe
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
    _emailCtrl.dispose();
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

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(_emailCtrl.text.trim())) {
          return 'Email invalide';
        }
        return null;
      case 1:
        if (_passwordCtrl.text.length < 6) return 'Mot de passe trop court (min 6 car.)';
        if (_passwordCtrl.text != _confirmCtrl.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _nextStep() async {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    if (_step == 0) {
      // Vérifie que l'email existe
      await _verifyEmail();
    } else {
      // Réinitialise le mot de passe
      await _resetPassword();
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['exists'] == true) {
        setState(() {
          _step = 1;
          _loading = false;
        });
        _animateStep();
      } else {
        setState(() {
          _errorMsg = 'Cet email n\'est pas enregistré';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = 'Impossible de contacter le serveur';
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password-direct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim().toLowerCase(),
          'newPassword': _passwordCtrl.text,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        if (!mounted) return;
        _showSuccess();
      } else {
        setState(() {
          _errorMsg = data['error'] as String? ?? 'Erreur lors de la réinitialisation';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMsg = 'Impossible de contacter le serveur';
        _loading = false;
      });
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
              color: _lime.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open_rounded, color: _lime, size: 36),
          ),
          const SizedBox(height: 24),
          const Text('Mot de passe mis à jour',
              style: TextStyle(color: _white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text(
            'Tu peux maintenant te connecter avec ton nouveau mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
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
                color: _lime,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _lime.withOpacity(0.3),
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

    void _prevStep() {
    if (_step > 0) {
      setState(() {
        _step--;
        _errorMsg = null;
      });
      _animateStep();
    } else {
      // Redirection vers LoginScreen au lieu de pop
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
    return Scaffold(
      body: Stack(
        children: [
          // ─── Background Image ─────────────────────────────────────
          Positioned.fill(
            child: Image.network(
              _bgImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: _dark);
              },
              errorBuilder: (context, error, stackTrace) => Container(color: _dark),
            ),
          ),
          // ─── Dark Overlay ───────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _dark.withOpacity(0.3),
                    _dark.withOpacity(0.85),
                    _dark.withOpacity(0.95),
                  ],
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
                          const SizedBox(height: 302),
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
            onPressed: _loading ? null : _prevStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _white),
          ),
          const Spacer(),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
          
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const total = 2;
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
                        ? _lime
                        : active
                            ? _lime.withOpacity(0.4)
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

  static const _stepLabels = ['ÉTAPE 1 / 2', 'ÉTAPE 2 / 2'];
  static const _stepTitles = ['Ton\nadresse email', 'Nouveau mot\nde passe'];
  static const _stepSubs = [
    'Entre ton email pour réinitialiser ton mot de passe.',
    'Choisis un nouveau mot de passe sécurisé.',
  ];

  Widget _buildStepHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_stepLabels[_step],
          style: const TextStyle(
              color: _lime, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
      const SizedBox(height: 8),
      Text(_stepTitles[_step],
          style: const TextStyle(
              color: _white, fontSize: 34, fontWeight: FontWeight.w900, height: 1.1)),
      const SizedBox(height: 10),
      Text(_stepSubs[_step],
          style: const TextStyle(color: _muted, fontSize: 14, height: 1.5)),
    ]);
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _FitField(
          controller: _emailCtrl,
          label: 'Email',
          hint: 'ton@email.ma',
          keyboardType: TextInputType.emailAddress,
        );
      case 1:
        return Column(children: [
          _FitField(
            controller: _passwordCtrl,
            label: 'Nouveau mot de passe',
            hint: '••••••••',
            obscure: _obscurePass,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: _muted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FitField(
            controller: _confirmCtrl,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            obscure: _obscureConf,
            suffix: IconButton(
              onPressed: () => setState(() => _obscureConf = !_obscureConf),
              icon: Icon(
                _obscureConf ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: _muted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PasswordStrengthBar(password: _passwordCtrl.text),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCTA() {
    const labels = ['CONTINUER', 'RÉINITIALISER'];
    return Column(children: [
      _loading
          ? const Center(
              child: CircularProgressIndicator(color: _lime, strokeWidth: 2.5),
            )
          : GestureDetector(
              onTap: _nextStep,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _lime.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[_step],
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                 
                  ],
                ),
              ),
            ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Tu te souviens de ton mot de passe ? ',
            style: TextStyle(color: _muted, fontSize: 13)),
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
          child: const Text(
            'Se connecter',
            style: TextStyle(color: _lime, fontSize: 13, fontWeight: FontWeight.w700),
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
          child: Text(_errorMsg ?? '', style: const TextStyle(color: _red, fontSize: 13)),
        ),
      ]),
    );
  }
}

// ─── Password Strength Bar ────────────────────────────────────────────────────

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

  Color get _color {
    switch (_strength) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return _lime;
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
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
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
  final void Function(String)? onChanged;

  const _FitField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: const TextStyle(
          color: _lime,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _card.withOpacity(0.85),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffix,
          ),
        ),
      ),
    ]);
  }
}