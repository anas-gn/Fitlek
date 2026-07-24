// ─────────────────────────────────────────────
//  welcome_v2.dart  —  Modern Welcome Screen
//  Design: Hero image + Direct CTA buttons
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );

  void _goToRegister() => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RegisterScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(children: [
        // ── Background Hero Image ────────────────────────────────
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.35),
            colorBlendMode: BlendMode.darken,
            loadingBuilder: (_, child, p) =>
                p == null ? child : Container(color: const Color(0xFF111111)),
          ),
        ),

        // ── Dark gradient overlay (bottom) ───────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.cyprus.withValues(alpha: 0.5),
                  AppColors.cyprus.withValues(alpha: 0.88),
                  AppColors.cyprus,
                ],
                stops: const [0.0, 0.3, 0.55, 0.85, 1.0],
              ),
            ),
          ),
        ),

        // ── Left side vignette ────────────────────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top accent bar ────────────────────────────────────────

        // ── Header: Logo ──────────────────────────────────────────
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SirvyaLogo(
                    variant: SirvyaLogoVariant.wordmark,
                    height: 25,
                    color: AppColors.sand,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Content: Bottom section ───────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Main headline ──────────────────────────
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

                      // ── Subtitle ────────────────────────────────
                      Text(
                        'Book your session in just a few taps. '
                        'Transform your body with the best coaches.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── CTA Buttons ─────────────────────────────
                      Column(
                        children: [
                          // Connexion button (Primary - Lime)
                          _CTAButton(
                            label: 'LOG IN',
                            onTap: _goToLogin,
                            isPrimary: true,
                            icon: Icons.login_rounded,
                          ),

                          const SizedBox(height: 14),

                          // Créer compte button (Secondary - Outlined)
                          _CTAButton(
                            label: 'CREATE AN ACCOUNT',
                            onTap: _goToRegister,
                            isPrimary: false,
                            icon: Icons.person_add_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Trust badges ────────────────────────────
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
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
                      color: Colors.black.withValues(alpha: 0.3),
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
