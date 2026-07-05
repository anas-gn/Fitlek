//  app_header.dart — Header Premium avec Logo SVG
//  Widget réutilisable pour toutes les pages
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─── Constants ──────────────────────────────────────────────────────────────
const _lime       = Color(0xFFC6F135);
const _limeDark   = Color(0xFF9BC420);
const _dark       = Color(0xFF0A0A0A);
const _darkElev2  = Color(0xFF141414);
const _darkElev3  = Color(0xFF1A1A1A);
const _cardBorder = Color(0xFF232323);
const _textPrimary   = Colors.white;
const _textSecondary = Color(0xFF9CA3AF);
const _textMuted     = Color(0xFF6B7280);

// ═════════════════════════════════════════════
//  APP HEADER — Logo + Avatar + Notification
// ═════════════════════════════════════════════

class AppHeader extends StatelessWidget {
  final String? firstName;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final String? title;
  final double scrollOffset;

  const AppHeader({
    super.key,
    this.firstName,
    this.avatarUrl,
    this.onAvatarTap,
    this.onNotificationTap,
    this.showBackButton = false,
    this.onBackTap,
    this.title,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isScrolled = scrollOffset > 50;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(20, 12, 20, isScrolled ? 12 : 16),
      decoration: BoxDecoration(
        color: isScrolled ? _darkElev2.withOpacity(0.95) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isScrolled ? _cardBorder.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: isScrolled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button OR Logo
            if (showBackButton)
              _buildBackButton()
            else
              _buildLogo(),

            const Spacer(),

            // Title (si fourni et scrolled)
            if (title != null && isScrolled)
              Expanded(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

            if (title != null && isScrolled) const Spacer(),

            // Notification Bell
            if (onNotificationTap != null)
              _buildNotificationBell(),

            const SizedBox(width: 12),

            // Avatar avec glow
            _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: onBackTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _darkElev3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 16),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo SVG custom
        SizedBox(
          width: 36,
          height: 32,
          child: CustomPaint(
            size: const Size(132, 120),
            painter: _FitLekLogoPainter(),
          ),
        ),
        const SizedBox(width: 10),
        // Texte FITLEK
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'FIT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _lime,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'LEK',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _darkElev3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: const Icon(Icons.notifications_outlined, color: _textSecondary, size: 20),
          ),
          // Badge notification
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _lime.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: _darkElev3,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
                  firstName != null && firstName!.isNotEmpty
                      ? firstName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  LOGO PAINTER — SVG FitLek
// ═════════════════════════════════════════════

class _FitLekLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 132;
    final scaleY = size.height / 120;

    // Circle (head) — #D1F96B (lime)
    final headPaint = Paint()
      ..color = const Color(0xFFD1F96B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(65.6104 * scaleX, 17.25 * scaleY),
      17.25 * math.min(scaleX, scaleY),
      headPaint,
    );

    // Body path — white stroke
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.1 * math.min(scaleX, scaleY)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // M5.8103 21.85
    path.moveTo(5.8103 * scaleX, 21.85 * scaleY);
    // C19.2827 35.9 45.0007 47.25 64.4603 47.7336
    path.cubicTo(
      19.2827 * scaleX, 35.9 * scaleY,
      45.0007 * scaleX, 47.25 * scaleY,
      64.4603 * scaleX, 47.7336 * scaleY,
    );
    // M125.41 21.85
    path.moveTo(125.41 * scaleX, 21.85 * scaleY);
    // C112.388 36.0329 83.709 48.212 64.4603 47.7336
    path.cubicTo(
      112.388 * scaleX, 36.0329 * scaleY,
      83.709 * scaleX, 48.212 * scaleY,
      64.4603 * scaleX, 47.7336 * scaleY,
    );
    // M64.4603 47.7336
    path.moveTo(64.4603 * scaleX, 47.7336 * scaleY);
    // V106.95
    path.lineTo(64.4603 * scaleX, 106.95 * scaleY);
    // C87.8436 95.8333 128.4 73.37 103.56 72.45
    path.cubicTo(
      87.8436 * scaleX, 95.8333 * scaleY,
      128.4 * scaleX, 73.37 * scaleY,
      103.56 * scaleX, 72.45 * scaleY,
    );
    // C78.7203 71.53 36.477 72.0666 18.4603 72.45
    path.cubicTo(
      78.7203 * scaleX, 71.53 * scaleY,
      36.477 * scaleX, 72.0666 * scaleY,
      18.4603 * scaleX, 72.45 * scaleY,
    );

    canvas.drawPath(path, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─────────────────────────────────────────────
//  app_footer.dart — Bottom Navigation Premium
//  Widget réutilisable pour toutes les pages
// ─────────────────────────────────────────────

// ═════════════════════════════════════════════
//  APP FOOTER — Bottom Navigation Glassmorphism
// ═════════════════════════════════════════════

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darkElev2.withOpacity(0.95),
            _darkElev2.withOpacity(0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2A2A2A).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _lime.withOpacity(0.03),
            blurRadius: 40,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [_lime, _limeDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _lime.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active ? Colors.black : _textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? Colors.black : _textMuted,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  NAV ITEM MODEL
// ═════════════════════════════════════════════

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}


// ─────────────────────────────────────────────
//  main_screen.dart — Écran principal assemblé
//  Header + Body + Footer séparés
// ─────────────────────────────────────────────

// ═════════════════════════════════════════════
//  MAIN SCREEN — Assemble Header + Body + Footer
// ═════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final String? firstName;
  final String? avatarUrl;
  final VoidCallback? onLogout;

  const MainScreen({
    super.key,
    required this.clientID,
    required this.token,
    this.firstName,
    this.avatarUrl,
    this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  // Définis tes vrais écrans ici
  // Remplace ces placeholders par tes imports réels
  late final List<Widget> _screens;

  static const _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explorer',
    ),
    NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Séances',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });

    // Remplace ces placeholders par tes vrais écrans
    _screens = [
      _HomePlaceholder(),           // ← Remplace par ton HomeScreen
      _ExplorePlaceholder(),        // ← Remplace par ClientList
      _SessionsPlaceholder(),       // ← Remplace par ClientSessions
      _ProfilePlaceholder(),        // ← Remplace par ClientProfil
    ];
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _onAvatarTap() {
    setState(() => _currentIndex = 3); // Va au profil
  }

  void _onNotificationTap() {
    // Ouvre la page notifications
    debugPrint('Notifications tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // ═══ HEADER (fixe en haut) ═══
          AppHeader(
            firstName: widget.firstName,
            avatarUrl: widget.avatarUrl,
            onAvatarTap: _onAvatarTap,
            onNotificationTap: _onNotificationTap,
            scrollOffset: _scrollOffset,
          ),

          // ═══ BODY (scrollable) ═══
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),

      // ═══ FOOTER (fixe en bas) ═══
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}


// ═════════════════════════════════════════════
//  PLACEHOLDER SCREENS (à remplacer par les tiens)
// ═════════════════════════════════════════════

class _HomePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 20,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: _darkElev2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Home Content $i',
            style: const TextStyle(color: _textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ExplorePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Explorer', style: TextStyle(color: _textPrimary, fontSize: 24)),
    );
  }
}

class _SessionsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Séances', style: TextStyle(color: _textPrimary, fontSize: 24)),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profil', style: TextStyle(color: _textPrimary, fontSize: 24)),
    );
  }
}