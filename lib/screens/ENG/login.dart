import 'dart:convert';
import 'package:fitlek1/screens/ENG/clientForgot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/apiService.dart';
import 'clientHome.dart';
import '../../mainLayoutCoach.dart';
import 'welcome.dart';
import 'register.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _border = Color(0xFF232323);
const _muted = Color(0xFF888888);
const _white = Color(0xFFFFFFFF);
const _errorRed = Color(0xFFFF5252);

const _baseUrl = 'http://localhost:3000/api';

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
    return SizedBox(
      height: height,
      width: height * 132 / 120,
      child: CustomPaint(
        painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (kDebugMode) debugPrint('🔐 LOGIN ATTEMPT: $email');

      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) debugPrint('📥 LOGIN RESPONSE: ${res.statusCode}');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token = body['accessToken'] as String?;
        final user = body['user'] as Map<String, dynamic>?;

        if (token == null || token.isEmpty) {
          setState(() {
            _errorMsg = 'Token invalide reçu du serveur.';
            _loading = false;
          });
          return;
        }

        if (user == null) {
          setState(() {
            _errorMsg = 'Données utilisateur manquantes.';
            _loading = false;
          });
          return;
        }

        final role = user['role'] as String?;
        final id = user['id'] as int?;
        final firstName = user['firstName'] as String? ?? '';

        if (role == null || id == null) {
          setState(() {
            _errorMsg = 'Informations utilisateur incomplètes.';
            _loading = false;
          });
          return;
        }

        if (kDebugMode) {
          debugPrint('✅ LOGIN SUCCESS - Role: $role, ID: $id');
          debugPrint('✅ TOKEN: ${token.substring(0, 30)}...');
        }

        await ApiService.saveToken(token);
        await ApiService.saveRole(role);
        await ApiService.saveUserData(id, firstName);

        final savedToken = await ApiService.getToken();
        if (kDebugMode) debugPrint('✅ TOKEN VERIFIED: ${savedToken != null ? "Saved" : "Not Saved"}');

        if (!mounted) return;

        Widget dest;
        switch (role) {
          case 'client':
            dest = HomeScreen(
              clientID: id,
              token: token,
              firstName: firstName,
              onLogout: _goToWelcome,
            );
            break;
          case 'coach':
            dest = const MainLayoutCoach();
            break;
          default:
            setState(() {
              _errorMsg = 'Rôle non reconnu: \$role';
              _loading = false;
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
      } else {
        final errorMsg = body['message'] ??
            body['error'] ??
            'Erreur de connexion (\${res.statusCode})';

        setState(() {
          _errorMsg = _friendly(errorMsg.toString());
          _loading = false;
        });
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('❌ NETWORK ERROR: \$e');
      setState(() {
        _errorMsg = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ LOGIN ERROR: \$e');
      setState(() {
        _errorMsg = 'Erreur: \$e';
        _loading = false;
      });
    }
  }

  void _goToWelcome() => Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );

  void _goToRegister() => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RegisterScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );

  String _friendly(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('credentials') || lower.contains('invalid')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (lower.contains('banned') || lower.contains('suspend')) {
      return 'Ce compte est suspendu.';
    }
    if (lower.contains('required')) {
      return 'Veuillez remplir tous les champs.';
    }
    if (lower.contains('not found')) {
      return 'Aucun compte trouvé avec cet email.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
              loadingBuilder: (_, child, p) =>
                  p == null ? child : Container(color: const Color(0xFF111111)),
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
                    Colors.transparent,
                    _dark.withOpacity(0.3),
                    _dark.withOpacity(0.7),
                    _dark,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 104),
                      _buildHeading(),
                      const SizedBox(height: 36),
                      _buildFields(),
                      const SizedBox(height: 12),
                      _buildForgotPassword(),
                      const SizedBox(height: 28),
                      _buildCTA(),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],
                      const SizedBox(height: 48),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildSignup(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const _FitlekLogo(height: 36),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'FIT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _lime,
                  letterSpacing: 3,
                ),
              ),
              TextSpan(
                text: 'LEK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _white,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content de vous revoir',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: _white,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connectez-vous pour accéder à votre espace et gérer vos activités.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        _LoginField(
          controller: _emailCtrl,
          label: 'Adresse email',
          hint: 'votre@email.com',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _LoginField(
          controller: _passwordCtrl,
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_rounded,
          isPassword: true,
          showPassword: _showPassword,
          onTogglePassword: () => setState(() => _showPassword = !_showPassword),
          onSubmit: _loading ? null : _login,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
         onTap: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ClientForgotScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          ),
        child: const Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            color: _lime,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: _loading ? _lime.withOpacity(0.6) : _lime,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: _lime.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.login_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'SE CONNECTER',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedOpacity(
      opacity: _errorMsg != null ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _errorRed.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _errorRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _errorRed,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMsg ?? '',
                style: const TextStyle(
                  color: _errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _white.withOpacity(0.08),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Pas encore inscrit ?',
            style: TextStyle(
              color: _white.withOpacity(0.4),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: _white.withOpacity(0.08),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _goToRegister,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _lime.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person_add_rounded, color: _lime, size: 18),
                SizedBox(width: 10),
                Text(
                  'CRÉER UN COMPTE',
                  style: TextStyle(
                    color: _lime,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Retourner à ',
              style: TextStyle(
                color: _white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: _goToWelcome,
              child: const Text(
                'l accueil',
                style: TextStyle(
                  color: _lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool showPassword;
  final VoidCallback? onTogglePassword;
  final VoidCallback? onSubmit;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.showPassword = false,
    this.onTogglePassword,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: _white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !showPassword,
            onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
            style: const TextStyle(
              color: _white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _muted.withOpacity(0.5),
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
                  color: _lime.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _lime, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: onTogglePassword,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _muted,
                          size: 20,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}