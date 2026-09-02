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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _textController;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      imageUrl:
          'assets/branding/sirvya3.jfif',
      tag: 'COACHING',
      title: 'Your Coach,',
      titleAccent: 'On Demand.',
      subtitle:
          'Find certified coaches near you and book a session in seconds.',
    ),
    _OnboardingData(
      imageUrl:
          'assets/branding/sirvya4.jfif',
      tag: 'PROGRESS',
      title: 'Track Every',
      titleAccent: 'Milestone.',
      subtitle:
          'Monitor your sessions and measure your growth day after day.',
    ),
    _OnboardingData(
      imageUrl:
          'assets/branding/sirvya5.jfif',
      tag: 'COMMUNITY',
      title: 'Join',
      titleAccent: 'SIRVYA.',
      subtitle:
          'Connect with top coaches and transform your body for good.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textController.forward();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _textController.reset();
    _textController.forward();
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

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.cyprus,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => _FullscreenImage(url: _pages[i].imageUrl),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    AppColors.cyprus.withValues(alpha: 0.3),
                    AppColors.cyprus.withValues(alpha: 0.82),
                    AppColors.cyprus.withValues(alpha: 0.97),
                    AppColors.cyprus,
                  ],
                  stops: const [0.0, 0.22, 0.45, 0.65, 0.82, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SirvyaLogo(
                    variant: SirvyaLogoVariant.wordmark,
                    height: 22,
                    color: AppColors.sand,
                  ),
                  if (!isLast)
                    GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        _pages.length - 1,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                child: FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.sand.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            data.tag,
                            style: const TextStyle(
                              color: AppColors.sand,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                        Text(
                          data.titleAccent,
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: AppColors.sand,
                            height: 1.05,
                            letterSpacing: -1.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          data.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (isLast) ...[
                          _CTAButton(
                            label: 'LOG IN',
                            onTap: _goToLogin,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),
                          _CTAButton(
                            label: 'CREATE AN ACCOUNT',
                            onTap: _goToRegister,
                            isPrimary: false,
                          ),
                        ] else
                          Row(
                            children: [
                              Row(
                                children: List.generate(_pages.length, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.only(right: 6),
                                    width: _currentPage == i ? 26 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _currentPage == i
                                          ? AppColors.sand
                                          : AppColors.sand
                                              .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                              const Spacer(),
                              _NextButton(onTap: _next),
                            ],
                          ),
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

class _OnboardingData {
  final String imageUrl;
  final String tag;
  final String title;
  final String titleAccent;
  final String subtitle;

  const _OnboardingData({
    required this.imageUrl,
    required this.tag,
    required this.title,
    required this.titleAccent,
    required this.subtitle,
  });
}

class _FullscreenImage extends StatelessWidget {
  final String url;
  const _FullscreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.12),
      colorBlendMode: BlendMode.darken,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
    );
  }
}

class _NextButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.sand,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.cyprus,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _CTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CTAButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.sand : Colors.transparent,
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isPrimary
                    ? AppColors.cyprus
                    : Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}