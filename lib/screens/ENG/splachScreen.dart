import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _lime.withOpacity(0.15 * _glowAnim.value),
                            blurRadius: 60 * _glowAnim.value,
                            spreadRadius: 20 * _glowAnim.value,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _FitlekLogoPainter(
                          strokeColor: Colors.white,
                          circleColor: _lime,
                        ),
                        size: const Size(140, 140),
                      ),
                    ),
                    const SizedBox(height: 28),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'FIT',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _lime,
                              letterSpacing: 6,
                              shadows: [
                                Shadow(
                                  color: _lime.withOpacity(0.3 * _glowAnim.value),
                                  blurRadius: 20 * _glowAnim.value,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'LEK',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Votre Coach Personnel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: _lime,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _lime.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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