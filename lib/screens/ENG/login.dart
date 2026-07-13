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

import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';
import '../../components/sirvya_logo.dart';

const _baseUrl = 'http://localhost:3000/api';

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
              _errorMsg = 'Unrecognized role: \$role';
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
            'Login error (\${res.statusCode})';

        setState(() {
          _errorMsg = _friendly(errorMsg.toString());
          _loading = false;
        });
      }
    } on http.ClientException {
      if (kDebugMode) debugPrint('❌ NETWORK ERROR: \$e');
      setState(() {
        _errorMsg = 'Unable to reach the server. Check your connection.';
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ LOGIN ERROR: \$e');
      setState(() {
        _errorMsg = 'Error: \$e';
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
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.4),
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
                    AppColors.cyprus.withValues(alpha: 0.4),
                    AppColors.cyprus.withValues(alpha: 0.85),
                    AppColors.cyprus,
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
    return const Row(
      children: [
        SirvyaLogo(
          variant: SirvyaLogoVariant.wordmark,
          height: 32,
          color: AppColors.sand,
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Log in to access your space and manage your activities.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.7),
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
        const SizedBox(height: 16),
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
          'Forgot password?',
          style: TextStyle(
            color: AppColors.sand,
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
          color:
              _loading ? AppColors.sand.withValues(alpha: 0.6) : AppColors.sand,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
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
    return AnimatedOpacity(
      opacity: _errorMsg != null ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
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
        GestureDetector(
          onTap: _goToRegister,
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
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cyprus.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
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
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
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
                  color: AppColors.sand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.sand, size: 18),
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
