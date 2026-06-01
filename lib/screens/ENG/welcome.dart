import 'package:fitlek1/screens/ENG/clientHome.dart';
import 'package:flutter/material.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final List<_Slide> _slides = const [
    _Slide(
      tag: '01 — DISCOVER',
      headline: 'Find the coach\nthat fits\nyour rhythm.',
      sub:
          'Browse certified coaches and elite fitness companies near you.',
      // Using a fitness-themed network image as placeholder
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
    ),
    _Slide(
      tag: '02 — BOOK',
      headline: 'One tap\nto book your\nnext session.',
      sub:
          'Real-time availability, instant confirmation, zero friction.',
      imageUrl:
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
    ),
    _Slide(
      tag: '03 — TRACK',
      headline: 'Watch your\nprogress\nunfold.',
      sub:
          'Weight logs, goals, nutrition — all in one powerful dashboard.',
      imageUrl:
          'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800&q=80',
    ),
  ];

  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _ctrl.reset();
      setState(() => _current++);
      _ctrl.forward();
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];
    const lime = Color(0xFFC6F135);
    const dark = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        children: [
          // ── Background image (darkened) ─────────────────────────
          Positioned.fill(
            child: Image.network(
              slide.imageUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.62),
              colorBlendMode: BlendMode.darken,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(color: const Color(0xFF111111)),
            ),
          ),

          // ── Gradient overlay bottom ─────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── Lime accent top bar ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: Container(color: lime),
          ),

          // ── Logo top-left ───────────────────────────────────────
          Positioned(
            top: 56,
            left: 28,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'FIT',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC6F135),
                      letterSpacing: 4,
                    ),
                  ),
                  TextSpan(
                    text: 'LEK',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Skip button top-right ───────────────────────────────
          Positioned(
            top: 50,
            right: 24,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const HomeScreen(),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              child: const Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 52),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lime.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: lime.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          slide.tag,
                          style: const TextStyle(
                            color: Color(0xFFC6F135),
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Headline
                      Text(
                        slide.headline,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub
                      Text(
                        slide.sub,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.55,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Progress dots + CTA row
                      Row(
                        children: [
                          // Dots
                          Row(
                            children: List.generate(
                              _slides.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: i == _current ? 24 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _current
                                      ? lime
                                      : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // CTA button
                          GestureDetector(
                            onTap: _next,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: lime,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _current == _slides.length - 1
                                    ? 'GET STARTED'
                                    : 'NEXT',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stat badge bottom-left overlay ──────────────────────
          Positioned(
            bottom: 170,
            left: 28,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                
                
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String tag;
  final String headline;
  final String sub;
  final String imageUrl;
  const _Slide(
      {required this.tag,
      required this.headline,
      required this.sub,
      required this.imageUrl});
}