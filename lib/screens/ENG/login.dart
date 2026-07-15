import 'dart:convert';
import 'dart:ui';
import 'package:fitlek1/screens/ENG/clientForgot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../../services/apiService.dart';
import 'clientHome.dart';
import '../../mainLayoutCoach.dart';
import 'welcome.dart';
import 'register.dart';

import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';

const _baseUrl = 'http://localhost:3000/api';

/// Logo Sirvya (icône + wordmark) vectorisé, intégré en dur pour éviter
/// de dépendre d'un asset externe. Blanc pur (#FFFFFF), fond transparent.
/// Le ColorFilter sur le widget force aussi Colors.white à l'affichage,
/// donc la couleur reste blanche même si ce fill venait à changer.
const String _sirvyaLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1328 325">
<g transform="translate(0.000000,325.000000) scale(0.100000,-0.100000)" fill="#FFFFFF" stroke="none">
  <path d="M0 2175 l0 -1075 308 0 308 0 243 -245 c133 -135 246 -245 249 -245
4 1 122 113 262 250 l255 250 -250 247 -250 248 -5 -248 -5 -247 -533 533
-533 533 538 537 538 537 -562 0 -563 0 0 -1075z"/>
  <path d="M1665 2720 l530 -530 -296 0 -296 0 -239 240 -239 241 -242 -236
c-134 -130 -243 -242 -243 -248 0 -13 460 -477 473 -477 4 0 7 104 7 230 0
127 2 230 6 230 8 0 1064 -1058 1064 -1067 0 -4 -246 -254 -547 -555 l-548
-548 903 0 902 0 0 1625 0 1625 -882 0 -883 0 530 -530z"/>
  <path d="M0 544 l0 -544 542 0 c298 0 539 2 537 5 -2 3 -246 247 -541 543
l-538 539 0 -543z"/>
</g>
<g transform="translate(290,0)">
<g transform="translate(0.000000,325.000000) scale(0.100000,-0.100000)" fill="#FFFFFF" stroke="none">
  <path d="M0 1625 l0 -1625 5190 0 5190 0 0 475 0 475 -159 0 -159 0 -69 123
-70 122 -432 3 c-489 3 -419 24 -529 -163 -47 -80 -47 -80 -204 -83 -87 -1
-158 0 -158 3 0 6 57 103 372 635 60 102 178 301 261 443 l150 257 111 0 c111
-1 111 -1 185 -128 86 -147 232 -396 479 -812 96 -162 185 -313 198 -335 24
-40 24 -40 24 1098 l0 1137 -5190 0 -5190 0 0 -1625z m2385 -5 l0 -665 -137
-3 -138 -3 0 671 0 671 138 -3 137 -3 0 -665z m2792 588 c27 -46 157 -266 288
-490 132 -224 242 -404 246 -400 4 4 32 50 62 103 30 53 126 217 212 365 86
148 182 312 212 364 31 52 62 105 70 118 13 21 18 22 173 22 88 0 160 -4 160
-8 0 -4 -4 -12 -9 -17 -10 -11 -395 -644 -637 -1049 -159 -265 -159 -265 -254
-266 l-96 0 -394 656 c-217 361 -396 663 -398 670 -3 11 26 14 156 14 160 0
160 0 209 -82z m2303 -225 c150 -170 276 -309 279 -310 3 -2 129 137 280 307
l274 310 175 0 c176 0 176 0 151 -27 -97 -107 -253 -282 -428 -478 -112 -127
-227 -254 -255 -283 -51 -53 -51 -53 -56 -300 l-5 -247 -137 -3 -138 -3 0 241
c0 240 0 240 -83 332 -168 187 -643 723 -660 745 -18 23 -18 23 156 23 l175 0
272 -307z m-6043 185 c62 -62 113 -116 113 -120 0 -5 -250 -8 -556 -8 -556 0
-556 0 -590 -34 -32 -32 -34 -38 -34 -100 0 -68 14 -110 46 -137 14 -11 96
-15 458 -19 441 -5 441 -5 491 -32 62 -32 129 -103 158 -166 20 -42 22 -64 22
-202 0 -146 -1 -158 -26 -211 -33 -69 -88 -124 -159 -158 -55 -26 -55 -26
-585 -29 l-529 -3 -118 118 -118 118 605 5 c605 5 605 5 632 33 26 25 28 34
31 121 4 92 3 94 -26 127 -30 34 -30 34 -469 39 -438 5 -438 5 -493 31 -71 34
-126 89 -159 158 -22 48 -26 73 -29 172 -5 135 9 197 59 272 17 26 50 60 73
76 87 60 86 60 611 61 l480 0 112 -112z m2814 79 c67 -32 142 -109 172 -175
20 -43 22 -63 22 -232 0 -169 -2 -189 -22 -232 -31 -68 -106 -143 -175 -177
-59 -28 -59 -28 106 -248 91 -120 166 -222 166 -226 0 -4 -74 -7 -164 -7
l-165 0 -78 106 c-43 58 -117 160 -166 225 l-87 119 -298 -2 -297 -3 -3 -223
-2 -222 -135 0 -135 0 0 665 0 666 603 -3 c602 -3 602 -3 658 -31z"/>
  <path d="M3262 1838 l3 -203 405 0 c458 0 456 0 490 69 16 33 20 61 19 132 0
110 -14 151 -58 181 -34 23 -34 23 -448 23 l-413 0 2 -202z"/>
  <path d="M9341 1694 c-78 -136 -140 -249 -138 -251 2 -2 133 -2 291 -1 l286 3
-89 155 c-170 297 -195 340 -202 340 -3 0 -70 -111 -148 -246z"/>
</g>
</g>
</svg>
''';

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
      setState(() => _errorMsg = 'Please fill in all fields.');
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
            _errorMsg = 'Invalid token received from the server.';
            _loading = false;
          });
          return;
        }

        if (user == null) {
          setState(() {
            _errorMsg = 'User data is missing.';
            _loading = false;
          });
          return;
        }

        final role = user['role'] as String?;
        final id = user['id'] as int?;
        final firstName = user['firstName'] as String? ?? '';

        if (role == null || id == null) {
          setState(() {
            _errorMsg = 'Incomplete user information.';
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
        if (kDebugMode) {
          debugPrint(
              '✅ TOKEN VERIFIED: ${savedToken != null ? "Saved" : "Not Saved"}');
        }

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
              _errorMsg = 'Unrecognized role: $role';
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
            'Login error (${res.statusCode})';

        setState(() {
          _errorMsg = _friendly(errorMsg.toString());
          _loading = false;
        });
      }
    } on http.ClientException {
      if (kDebugMode) debugPrint('❌ NETWORK ERROR');
      setState(() {
        _errorMsg = 'Unable to reach the server. Check your connection.';
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ LOGIN ERROR: $e');
      setState(() {
        _errorMsg = 'Error: $e';
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
      return 'Incorrect email or password.';
    }
    if (lower.contains('banned') || lower.contains('suspend')) {
      return 'This account is suspended.';
    }
    if (lower.contains('required')) {
      return 'Please fill in all fields.';
    }
    if (lower.contains('not found')) {
      return 'No account found with this email.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Fond image + flou léger pour plus de profondeur ──
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80',
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
          // ── Dégradé de lisibilité, plus doux et progressif ──
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 88),
                          _buildHeading(),
                          const SizedBox(height: 32),
                          _buildFields(),
                          const SizedBox(height: 10),
                          _buildForgotPassword(),
                          const SizedBox(height: 24),
                          _buildCTA(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            child: _errorMsg != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: _buildErrorBanner(),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          const SizedBox(height: 40),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          _buildSignup(),
                        ],
                      ),
                    ),
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
        SvgPicture.string(
          _sirvyaLogoSvg,
          height: 26,
          colorFilter: const ColorFilter.mode(
            Color.fromARGB(0, 255, 255, 255),
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.sand.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'SIGN IN',
            style: TextStyle(
              color: AppColors.sand,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.08,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Log in to access your space and manage your activities.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.65),
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
          label: 'Email address',
          hint: 'your@email.com',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _LoginField(
          controller: _passwordCtrl,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_rounded,
          isPassword: true,
          showPassword: _showPassword,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onSubmit: _loading ? null : _login,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ClientForgotScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Forgot password?',
            style: TextStyle(
              color: AppColors.sand,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return _PressableScale(
      onTap: _loading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _loading
                ? [
                    AppColors.sand.withValues(alpha: 0.55),
                    AppColors.sand.withValues(alpha: 0.45),
                  ]
                : [
                    AppColors.sand,
                    AppColors.sand.withValues(alpha: 0.85),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.sand.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.cyprus,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded,
                        color: AppColors.cyprus, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'LOG IN',
                      style: TextStyle(
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
    );
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

  Widget _buildDivider() {
    return Row(
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
            'Not registered yet?',
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
    );
  }

  Widget _buildSignup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToRegister,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.sand.withValues(alpha: 0.15),
            highlightColor: AppColors.sand.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.sand.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, color: AppColors.sand, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'CREATE AN ACCOUNT',
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Back to ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: _goToWelcome,
              child: const Text(
                'home',
                style: TextStyle(
                  color: AppColors.sand,
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

/// Applique un léger effet d'échelle au tap, pour un feedback tactile.
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

/// Champ de saisie avec halo animé au focus.
class _LoginField extends StatefulWidget {
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
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
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
              color: _isFocused
                  ? AppColors.sand
                  : Colors.white.withValues(alpha: 0.7),
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
            obscureText: widget.isPassword && !widget.showPassword,
            onSubmitted: widget.onSubmit != null ? (_) => widget.onSubmit!() : null,
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
                  color: (_isFocused ? AppColors.sand : AppColors.sand)
                      .withValues(alpha: _isFocused ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: AppColors.sand, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: widget.onTogglePassword,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          widget.showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
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