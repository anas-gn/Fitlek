import 'package:flutter/material.dart';
import 'components/ENG/managerHeader.dart';
import 'components/ENG/managerNavbar.dart';
import 'screens/ENG/managerDashboard.dart';
import 'screens/ENG/managerClients.dart';
import 'screens/ENG/managerCoaches.dart';
import 'screens/ENG/managerReservations.dart';
import 'screens/ENG/managerProfile.dart';
import 'screens/ENG/managerAdmins.dart';
import 'screens/ENG/managerAdvisors.dart';
import 'screens/ENG/managerBans.dart';
import 'screens/ENG/managerPendingCoaches.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static const String role = 'manager';

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  static const String _managerName = 'Admin Manager';
  static const String _avatarUrl = 'https://i.pravatar.cc/150?img=20';

  final List<Widget> _screens = const [
    ManagerDashboard(),
    ManagerClients(),
    ManagerCoaches(),
    ManagerReservations(),
    _MoreScreen(),
  ];

  bool get _showHeader => _currentIndex != 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_showHeader)
            ManagerHeader(managerName: _managerName, avatarUrl: _avatarUrl),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ]),
      ),
      bottomNavigationBar: ManagerNavbar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const Text('More', style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Additional management tools',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          const SizedBox(height: 28),
          _buildMoreItem(context,
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF00BCD4),
            iconBg: const Color(0xFF001A1E),
            title: 'Admins',
            subtitle: 'Manage platform administrators',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerAdmins()))),
          _buildMoreItem(context,
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFFFFB800),
            iconBg: const Color(0xFF2A1F00),
            title: 'Advisors',
            subtitle: 'View and manage advisors',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerAdvisors()))),
          _buildMoreItem(context,
            icon: Icons.block_rounded,
            iconColor: Colors.red,
            iconBg: const Color(0xFF1A0808),
            title: 'Bans',
            subtitle: 'View and manage active bans',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerBans()))),
          _buildMoreItem(context,
            icon: Icons.hourglass_top_rounded,
            iconColor: const Color(0xFFFFB800),
            iconBg: const Color(0xFF2A1F00),
            title: 'Pending Coaches',
            subtitle: 'Review coach applications',
            badge: '4',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerPendingCoaches()))),
          _buildMoreItem(context,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFFA3FF12),
            iconBg: const Color(0xFF1A3008),
            title: 'My Profile',
            subtitle: 'Edit profile and change password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManagerProfile()))),
          const SizedBox(height: 32),
          _buildVersionCard(),
        ]),
      ),
    );
  }

  Widget _buildMoreItem(BuildContext context, {
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required VoidCallback onTap, String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04))),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          if (badge != null)
            Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFFB800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3))),
              child: Text(badge, style: const TextStyle(
                  color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.w700))),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.25), size: 20),
        ]),
      ),
    );
  }

  Widget _buildVersionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.15))),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fitlek Manager', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('Version 1.0.0 · Manager Panel',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
      ]),
    );
  }
}
