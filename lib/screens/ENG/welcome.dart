// ─────────────────────────────────────────────
//  welcome.dart  —  Welcome Screen
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'register.dart';

import '../../constants/app_colors.dart';
import '../../components/sirvya_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _uiCtrl;
  late final Animation<double> _uiFade;
  late final Animation<Offset> _uiSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _uiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _uiFade = CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOut);
    _uiSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOutCubic),
    );

    // Slide up the CTA buttons shortly after arriving on this screen
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _uiCtrl.forward();
    });
  }

  @override
  void dispose() {
    _uiCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── 1. Static dark gradient background ───────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1F1A),
                    AppColors.cyprus.withValues(alpha: 0.90),
                    AppColors.cyprus,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. Subtle radial glow (top-right accent) ─────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sand.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Logo (top-left, always visible) ───────────────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: SirvyaLogo(
                  variant: SirvyaLogoVariant.wordmark,
                  height: 25,
                  color: AppColors.sand,
                ),
              ),
            ),
          ),

          // ── 4. CTA section (slides up) ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _uiFade,
              child: SlideTransition(
                position: _uiSlide,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'Your Personal\nCoach\n',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Within Reach',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.sand,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Book your session in just a few taps. '
                          'Transform your body with the best coaches.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _CTAButton(
                          label: 'LOG IN',
                          onTap: _goToLogin,
                          isPrimary: true,
                          icon: Icons.login_rounded,
                        ),
                        const SizedBox(height: 14),
                        _CTAButton(
                          label: 'CREATE AN ACCOUNT',
                          onTap: _goToRegister,
                          isPrimary: false,
                          icon: Icons.person_add_rounded,
                        ),
                        const SizedBox(height: 28),
                      ],
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
}

// ─────────────────────────────────────────────
//  Widget: CTA Button
// ─────────────────────────────────────────────

class _CTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final IconData icon;

  const _CTAButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.icon,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.sand : Colors.transparent,
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: AppColors.sand.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary ? AppColors.cyprus : AppColors.sand,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? AppColors.cyprus : AppColors.sand,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
