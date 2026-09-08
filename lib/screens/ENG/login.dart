import 'dart:convert';
import 'dart:ui';
import 'package:fitlek1/screens/ENG/clientForgot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../../services/google_auth_service.dart';
import '../../services/apple_auth_service.dart';
import '../../services/apiService.dart';
import '../../services/notification_service.dart';
import 'clientHome.dart';
import '../../mainLayoutCoach.dart';
import 'welcome.dart';
import 'register.dart';
import 'package:fitlek1/constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';

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
  bool _googleLoading = false;
  bool _appleLoading = false;
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

    if (email.isEmpty) {
      setState(() => _errorMsg = 'Enter your email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Enter your password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (kDebugMode) debugPrint('ðŸ” LOGIN ATTEMPT');

      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) debugPrint('ðŸ“¥ LOGIN RESPONSE: ${res.statusCode}');

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
          debugPrint('âœ… LOGIN SUCCESS - Role: $role, ID: $id');
          debugPrint('âœ… TOKEN: ${token.substring(0, 30)}...');
        }

        await _completeSignIn(token: token, role: role, id: id, firstName: firstName);
      } else if (res.statusCode == 403 && body['authProvider'] == 'google') {
        // Google-only account trying to use email/password
        setState(() {
          _errorMsg = 'This account uses Google Sign-In. Tap "Continue with Google" below to log in.';
          _loading = false;
        });
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
      if (kDebugMode) debugPrint('âŒ NETWORK ERROR');
      setState(() {
        _errorMsg = 'Check your connection.';
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('âŒ LOGIN ERROR: $e');
      setState(() {
        _errorMsg = 'Check your connection';
        _loading = false;
      });
    }
  }

  Future<void> _completeSignIn({
    required String token,
    required String role,
    required int id,
    required String firstName,
    bool isNewUser = false,
    bool hasPassword = true,
  }) async {
    await ApiService.saveToken(token);
    await ApiService.saveRole(role);
    await ApiService.saveUserData(id, firstName);
    await NotificationService.instance.getFCMToken();

    if (!mounted) return;

    // If new Google user with no password, offer to set one
    if (isNewUser && !hasPassword && mounted) {
      _showSetPasswordPrompt(token: token);
    }

    Widget dest;
    switch (role) {
      case 'client':
        dest = HomeScreen(
          clientID: id,
          token: token,
          firstName: firstName,
          onLogout: () async {
            await ApiService.clearToken();
            if (!mounted) return;
            _goToWelcome();
          },
        );
        break;
      case 'coach':
        dest = const MainLayoutCoach();
        break;
      default:
        setState(() {
          _errorMsg = 'Unrecognized role: $role';
          _loading = false;
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
  }

  void _showSetPasswordPrompt({required String token}) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetPasswordSheet(token: token, baseUrl: baseUrl),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await GoogleAuthService.signInWithGoogle(role: 'client');
      await _completeSignIn(
        token: result.accessToken,
        role: result.user['role'] as String? ?? 'client',
        id: result.user['id'] as int? ?? 0,
        firstName: result.user['firstName'] as String? ?? '',
        isNewUser: result.isNewUser,
        hasPassword: result.hasPassword,
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'cancelled') {
        setState(() => _googleLoading = false);
        return;
      }
      if (kDebugMode) debugPrint('❌ GOOGLE LOGIN ERROR: ');
      setState(() {
        _errorMsg = msg;
        _googleLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ GOOGLE LOGIN ERROR: ');
      setState(() {
        _errorMsg = 'Google sign-in failed. Please try again.';
        _googleLoading = false;
      });
    }
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _appleLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await AppleAuthService.signInWithApple(role: 'client');
      await _completeSignIn(
        token: result.accessToken,
        role: result.user['role'] as String? ?? 'client',
        id: result.user['id'] as int? ?? 0,
        firstName: result.user['firstName'] as String? ?? '',
        isNewUser: result.isNewUser,
        hasPassword: result.hasPassword,
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'cancelled' || msg.contains('canceled') || msg.contains('1001')) {
        setState(() => _appleLoading = false);
        return;
      }
      if (kDebugMode) debugPrint('❌ APPLE LOGIN ERROR: ');
      setState(() {
        _errorMsg = msg;
        _appleLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ APPLE LOGIN ERROR: ');
      setState(() {
        _errorMsg = 'Apple sign-in failed. Please try again.';
        _appleLoading = false;
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
    if (lower.contains('required')) return 'Please fill in all fields.';
    if (lower.contains('not found')) return 'No account found with this email.';
    return raw;
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
            _goToWelcome();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/branding/sirvya1.jfif',
                  fit: BoxFit.cover,
                  frameBuilder: (_, child, frame, __) =>
                      frame == null ? Container(color: const Color(0xFF111111)) : child,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
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
                              const SizedBox(height: 24),
                              _buildOrDivider(),
                              const SizedBox(height: 20),
                              _buildGoogleButton(),
                              if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                                const SizedBox(height: 12),
                                _buildAppleButton(),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [],
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
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _LoginField(
          controller: _passwordCtrl,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline_rounded,
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
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, color: AppColors.cyprus, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'LOG IN',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.cyprus,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
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
            'OR',
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
    return _PressableScale(
      onTap: _googleLoading || _loading || _appleLoading ? null : _loginWithGoogle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(
                        _googleLogoSvg,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'CONTINUE WITH GOOGLE',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
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
    return _PressableScale(
      onTap: _googleLoading || _loading || _appleLoading ? null : _loginWithApple,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple_rounded, color: Colors.black, size: 26),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'CONTINUE WITH APPLE',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        border:
            Border.all(color: context.fitlek.error.withValues(alpha: 0.35), width: 1),
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
            child: Icon(Icons.error_outline_rounded,
                color: context.fitlek.error, size: 16),
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
              color: Colors.white.withValues(alpha: 0.15), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Not registered yet?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
        ),
        Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.15), thickness: 1),
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.sand.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_rounded, color: AppColors.sand, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'CREATE AN ACCOUNT',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.sand,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
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
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
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

class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
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
                  obscureText: widget.isPassword && !widget.showPassword,
                  onSubmitted:
                      widget.onSubmit != null ? (_) => widget.onSubmit!() : null,
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
              if (widget.isPassword)
                GestureDetector(
                  onTap: widget.onTogglePassword,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey(widget.showPassword),
                        color: _isFocused
                            ? AppColors.sand.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.35),
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Set Password Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SetPasswordSheet extends StatefulWidget {
  final String token;
  final String baseUrl;
  const _SetPasswordSheet({required this.token, required this.baseUrl});

  @override
  State<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends State<_SetPasswordSheet> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/auth/set-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'password': pass}),
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        setState(() { _done = true; _loading = false; });
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _error = body['error'] as String? ?? 'Failed to set password.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() { _error = 'Connection error.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: _done
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 56),
                const SizedBox(height: 12),
                const Text('Password set!',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('You can now log in with your email and password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sand,
                        foregroundColor: AppColors.cyprus,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Text('Set a Password',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Optionally set a password so you can also log in with your email later.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sand)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white38),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sand)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white60,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sand,
                          foregroundColor: AppColors.cyprus,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyprus))
                          : const Text('Set Password',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}

