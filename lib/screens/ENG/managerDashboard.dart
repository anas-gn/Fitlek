import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/apiService.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});
  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _anims;
  bool _loading = true;

  int _totalClients = 0, _totalCoaches = 0, _totalAdmins = 0, _totalAdvisors = 0;
  int _totalReservations = 0, _confirmedReservations = 0, _pendingReservations = 0, _cancelledReservations = 0;
  int _activeBans = 0, _pendingCoaches = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anims = List.generate(6, (i) => CurvedAnimation(parent: _animController,
        curve: Interval(i * 0.08, math.min(1.0, i * 0.08 + 0.6), curve: Curves.easeOut)));
    _loadData();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final result = await ApiService.get('/manager/dashboard');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _totalClients         = result['totalClients']          ?? 0;
        _totalCoaches         = result['totalCoaches']          ?? 0;
        _totalAdmins          = result['totalAdmins']           ?? 0;
        _totalAdvisors        = result['totalAdvisors']         ?? 0;
        _totalReservations    = result['totalReservations']     ?? 0;
        _confirmedReservations= result['confirmedReservations'] ?? 0;
        _pendingReservations  = result['pendingReservations']   ?? 0;
        _cancelledReservations= result['cancelledReservations'] ?? 0;
        _activeBans           = result['activeBans']            ?? 0;
        _pendingCoaches       = result['pendingCoaches']        ?? 0;
        _loading = false;
      });
      _animController.forward();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12))));
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            FadeTransition(opacity: _anims[0], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting, Manager 👋', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Platform Overview', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ])),
            const SizedBox(height: 24),
            FadeTransition(opacity: _anims[1], child: _buildHeroRow()),
            const SizedBox(height: 16),
            FadeTransition(opacity: _anims[2], child: _buildStatsGrid()),
            const SizedBox(height: 28),
            FadeTransition(opacity: _anims[3], child: _buildReservationsSummary()),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeroRow() => Row(children: [
    Expanded(flex: 3, child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA3FF12), Color(0xFF7ACC00)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 28, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Users', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Text('${_totalClients + _totalCoaches + _totalAdmins + _totalAdvisors}',
          style: const TextStyle(color: Colors.black, fontSize: 44, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1)),
      ])),
    ),
    const SizedBox(width: 12),
    Expanded(flex: 2, child: Column(children: [
      _miniCard('$_pendingCoaches', 'Pending', Icons.hourglass_top_rounded, const Color(0xFFFFB800), const Color(0xFF2A1F00)),
      const SizedBox(height: 12),
      _miniCard('$_activeBans', 'Bans', Icons.block_rounded, Colors.red, const Color(0xFF1A0808)),
    ])),
  ]);

  Widget _miniCard(String val, String label, IconData icon, Color color, Color bg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ]),
    ]),
  );

  Widget _buildStatsGrid() {
    final stats = [
      {'label': 'Clients',  'value': '$_totalClients',  'icon': Icons.people_rounded,              'color': const Color(0xFFA3FF12), 'bg': const Color(0xFF0D1A04)},
      {'label': 'Coaches',  'value': '$_totalCoaches',  'icon': Icons.sports_rounded,              'color': const Color(0xFF7C4DFF), 'bg': const Color(0xFF1A0A2A)},
      {'label': 'Admins',   'value': '$_totalAdmins',   'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF00BCD4), 'bg': const Color(0xFF001A1E)},
      {'label': 'Advisors', 'value': '$_totalAdvisors', 'icon': Icons.support_agent_rounded,       'color': const Color(0xFFFFB800), 'bg': const Color(0xFF2A1F00)},
    ];
    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: (s['color'] as Color).withOpacity(0.15))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 3),
            Text(s['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          ]),
        ]),
      )).toList());
  }

  Widget _buildReservationsSummary() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Reservations', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _resStat('$_totalReservations', 'Total', Colors.white)),
        _divider(),
        Expanded(child: _resStat('$_confirmedReservations', 'Confirmed', const Color(0xFFA3FF12))),
        _divider(),
        Expanded(child: _resStat('$_pendingReservations', 'Pending', const Color(0xFFFFB800))),
        _divider(),
        Expanded(child: _resStat('$_cancelledReservations', 'Cancelled', Colors.red)),
      ]),
      const SizedBox(height: 16),
      if (_totalReservations > 0) ClipRRect(borderRadius: BorderRadius.circular(4),
        child: Row(children: [
          Flexible(flex: _confirmedReservations.clamp(1, 1000), child: Container(height: 6, color: const Color(0xFFA3FF12))),
          Flexible(flex: _pendingReservations.clamp(1, 1000), child: Container(height: 6, color: const Color(0xFFFFB800))),
          Flexible(flex: _cancelledReservations.clamp(1, 1000), child: Container(height: 6, color: Colors.red)),
        ])),
    ]),
  );

  Widget _resStat(String val, String label, Color color) => Column(children: [
    Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 3),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
  ]);

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));
}
