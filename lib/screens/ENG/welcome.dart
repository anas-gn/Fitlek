// ─────────────────────────────────────────────
//  welcome_v2.dart  —  Modern Welcome Screen
//  Design: Hero image + Direct CTA buttons
// ─────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'register.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);

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
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ),
  );

  void _goToRegister() => Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const RegisterScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _dark,
      body: Stack(children: [
        // ── Background Hero Image ────────────────────────────────
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.35),
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
                  _dark.withOpacity(0.4),
                  _dark.withOpacity(0.8),
                  _dark,
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
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top accent bar ────────────────────────────────────────
      
        // ── Header: Logo ──────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _FitlekLogo(height: 32),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(children: [
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
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ]),
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
                            text: 'Votre Coach\nPersonnel\n',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                          TextSpan(
                            text: 'À votre portée',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: _lime,
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Subtitle ────────────────────────────────
                      Text(
                        'Réservez votre séance en quelques taps. '
                        'Transformez votre corps avec les meilleurs coachs.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── CTA Buttons ─────────────────────────────
                      Column(
                        children: [
                          // Connexion button (Primary - Lime)
                          _CTAButton(
                            label: 'CONNEXION',
                            onTap: _goToLogin,
                            isPrimary: true,
                            icon: Icons.login_rounded,
                          ),

                          const SizedBox(height: 14),

                          // Créer compte button (Secondary - Outlined)
                          _CTAButton(
                            label: 'CRÉER UN COMPTE',
                            onTap: _goToRegister,
                            isPrimary: false,
                            icon: Icons.person_add_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Trust badges ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          
                        ],
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
            color: widget.isPrimary ? _lime : Colors.transparent,
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _lime.withOpacity(0.5),
                    width: 1.5,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: _lime.withOpacity(0.35),
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
                color: widget.isPrimary ? Colors.black : _lime,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? Colors.black : _lime,
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

// ─────────────────────────────────────────────
//  Widget: Trust Badge
// ─────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}