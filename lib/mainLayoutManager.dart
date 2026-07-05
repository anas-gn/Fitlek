import 'package:flutter/material.dart';
import 'components/ENG/managerHeader.dart';
import 'components/ENG/managerNavbar.dart';
import 'screens/ENG/managerDashboard.dart';
import 'screens/ENG/managerClients.dart';
import 'screens/ENG/managerCoaches.dart';
import 'screens/ENG/managerReservations.dart';
import 'screens/ENG/managerAdmins.dart';
import 'screens/ENG/managerAdvisors.dart';
import 'screens/ENG/managerBans.dart';
import 'screens/ENG/managerPendingCoaches.dart';
import 'screens/ENG/managerProfile.dart';

class MainLayoutManager extends StatefulWidget {
  const MainLayoutManager({super.key});

  @override
  State<MainLayoutManager> createState() => _MainLayoutManagerState();
}

class _MainLayoutManagerState extends State<MainLayoutManager> {
  int _currentIndex = 0;

  static const String _managerName = 'Admin Manager';
  static const String _avatarUrl   = '';

  final List<Widget> _screens = const [
    ManagerDashboard(),
    ManagerClients(),
    ManagerCoaches(),
    ManagerReservations(),
    _MoreScreen(),
  ];

  // Profile tab lives inside _MoreScreen, so always show the header
  // except when on the More tab (index 4) which handles its own layout.
  bool get _showHeader => _currentIndex != 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_showHeader)
            ManagerHeader(
              managerName: _managerName,
              avatarUrl: _avatarUrl,
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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

// ── More tab ─────────────────────────────────────────────────────────────────
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
          _item(context, Icons.admin_panel_settings_rounded, const Color(0xFF00BCD4), const Color(0xFF001A1E),
              'Admins', 'Manage platform administrators', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerAdmins()))),
          _item(context, Icons.support_agent_rounded, const Color(0xFFFFB800), const Color(0xFF2A1F00),
              'Advisors', 'View and manage advisors', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerAdvisors()))),
          _item(context, Icons.block_rounded, Colors.red, const Color(0xFF1A0808),
              'Bans', 'View and manage active bans', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerBans()))),
          _item(context, Icons.hourglass_top_rounded, const Color(0xFFFFB800), const Color(0xFF2A1F00),
              'Pending Coaches', 'Review coach applications',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerPendingCoaches()))),
          _item(context, Icons.person_rounded, const Color(0xFFA3FF12), const Color(0xFF1A3008),
              'My Profile', 'Edit profile and change password',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerProfile()))),
          const SizedBox(height: 32),
          _buildVersionCard(),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, Color iconColor, Color iconBg,
      String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.25), size: 20),
        ]),
      ),
    );
  }

  Widget _buildVersionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.15))),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fitlek Manager', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text('Version 1.0.0 · Manager Panel', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
      ]),
    );
  }
}
