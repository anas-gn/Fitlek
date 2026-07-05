// lib/screens/main_layout.dart
// ═════════════════════════════════════════════
//  MAIN LAYOUT — Assemble Header + Body + Footer
// ═════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'headerFooter.dart';

// Importe tes vrais écrans ici
// import 'homeScreen.dart';
// import 'clientList.dart';
// import 'clientSessions.dart';
// import 'clientProfil.dart';

const _dark = Color(0xFF0A0A0A);
const _darkElev2 = Color(0xFF141414);
const _textMuted = Color(0xFF6B7280);

class MainLayout extends StatefulWidget {
  final int clientID;
  final String token;
  final String? firstName;
  final String? avatarUrl;
  final VoidCallback? onLogout;

  const MainLayout({
    super.key,
    required this.clientID,
    required this.token,
    this.firstName,
    this.avatarUrl,
    this.onLogout,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });

    // ═══ REMPLACE CES PLACEHOLDERS PAR TES VRAIS ÉCRANS ═══
    _screens = [
      _PlaceholderScreen(
        title: 'Accueil',
        color: const Color(0xFFC6F135),
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Explorer',
        color: const Color(0xFF8B5CF6),
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Séances',
        color: const Color(0xFF3B82F6),
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Profil',
        color: const Color(0xFFEF4444),
        scrollCtrl: _scrollCtrl,
      ),
    ];
    
    // QUAND TES ÉCRANS SONT PRÊTS, REMPLACE PAR :
    // _screens = [
    //   HomeScreen(
    //     clientID: widget.clientID,
    //     token: widget.token,
    //     firstName: widget.firstName,
    //     onLogout: widget.onLogout,
    //   ),
    //   ClientList(clientID: widget.clientID, token: widget.token),
    //   ClientSessions(clientID: widget.clientID, token: widget.token),
    //   ClientProfil(
    //     clientID: widget.clientID,
    //     token: widget.token,
    //     onLogout: widget.onLogout,
    //   ),
    // ];
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

  void _onAvatarTap() => _onNavTap(3); // Va au profil
  void _onNotificationTap() {
    // Navigation vers notifications
    debugPrint('🔔 Notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      // ═══ HEADER FIXE EN HAUT ═══
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppHeader(
          firstName: widget.firstName,
          avatarUrl: widget.avatarUrl,
          onAvatarTap: _onAvatarTap,
          onNotificationTap: _onNotificationTap,
          scrollOffset: _scrollOffset,
        ),
      ),
      
      // ═══ BODY (scrollable, change selon l'onglet) ═══
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // ═══ FOOTER FIXE EN BAS ═══
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  PLACEHOLDER — À supprimer quand tes écrans sont prêts
// ═════════════════════════════════════════════

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final Color color;
  final ScrollController scrollCtrl;

  const _PlaceholderScreen({
    required this.title,
    required this.color,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: 20,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: _darkElev2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                '$title — Item ${i + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Remplace ce placeholder par ton vrai écran',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}