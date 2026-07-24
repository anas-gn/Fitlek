
import 'package:flutter/material.dart';
import 'headerFooter.dart';

import '../../theme/fitlek_theme_extension.dart';



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
      label: 'Home',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Sessions',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
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
        title: 'Home',
        color: Theme.of(context).colorScheme.primary,
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Explore',
        color: context.fitlek.violet,
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Sessions',
        color: context.fitlek.info,
        scrollCtrl: _scrollCtrl,
      ),
      _PlaceholderScreen(
        title: 'Profile',
        color: context.fitlek.error,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
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
                'Replace this placeholder with your real screen',
                style: TextStyle(
                  color: context.fitlek.textMuted,
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