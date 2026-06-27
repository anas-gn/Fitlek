import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/apiService.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});
  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _cardAnims;
  bool _loading = true;

  int _totalReservations = 0;
  int _pendingReservations = 0;
  int _confirmedReservations = 0;
  int _totalClients = 0;
  int _invitationPoints = 0;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _cardAnims = List.generate(6, (i) => CurvedAnimation(parent: _animController,
        curve: Interval(i * 0.1, math.min(1.0, i * 0.1 + 0.6), curve: Curves.easeOut)));
    _loadData();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final result = await ApiService.get('/coach/dashboard');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _totalReservations    = result['totalReservations']    ?? 0;
        _pendingReservations  = result['pendingReservations']  ?? 0;
        _confirmedReservations= result['confirmedReservations']?? 0;
        _totalClients         = result['totalClients']         ?? 0;
        _invitationPoints     = result['invitationPoints']     ?? 0;
        _recentActivity       = result['recentActivity']       ?? [];
        _loading = false;
      });
      _animController.forward();
    } else {
      setState(() => _loading = false);
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, Coach 👋';
    if (h < 17) return 'Good afternoon, Coach 👋';
    return 'Good evening, Coach 👋';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: const Color(0xFFA3FF12),
        backgroundColor: const Color(0xFF111111),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            FadeTransition(opacity: _cardAnims[0], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Your Overview', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ])),
            const SizedBox(height: 28),
            FadeTransition(opacity: _cardAnims[1], child: _buildHeroCard()),
            const SizedBox(height: 24),
            FadeTransition(opacity: _cardAnims[2], child: _buildStatsGrid()),
            const SizedBox(height: 28),
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            FadeTransition(opacity: _cardAnims[3], child: _buildActivityList()),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeroCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA3FF12), Color(0xFF7ACC00)]),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Reservations', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Text('$_totalReservations', style: const TextStyle(color: Colors.black, fontSize: 48, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1)),
        const SizedBox(height: 12),
        Row(children: [
          _heroBadge('$_confirmedReservations Confirmed'),
          const SizedBox(width: 8),
          _heroBadge('$_pendingReservations Pending'),
        ]),
      ])),
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.calendar_today_rounded, color: Colors.black, size: 34)),
    ]),
  );

  Widget _heroBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _buildStatsGrid() {
    final stats = [
      {'label': 'Total Clients', 'value': '$_totalClients', 'icon': Icons.group_rounded, 'color': const Color(0xFFA3FF12), 'bg': const Color(0xFF1A2F0A)},
      {'label': 'Pending', 'value': '$_pendingReservations', 'icon': Icons.hourglass_top_rounded, 'color': const Color(0xFFFFB800), 'bg': const Color(0xFF2A1F00)},
      {'label': 'Confirmed', 'value': '$_confirmedReservations', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF00E676), 'bg': const Color(0xFF002A1A)},
      {'label': 'Invite Points', 'value': '$_invitationPoints', 'icon': Icons.star_rounded, 'color': const Color(0xFFBB86FC), 'bg': const Color(0xFF1A0A2A)},
    ];
    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.45,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: (s['color'] as Color).withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(s['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ]),
      )).toList());
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) return Center(child: Text('No recent activity.', style: TextStyle(color: Colors.white.withOpacity(0.3))));
    return Column(children: _recentActivity.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3), width: 1.5)),
          child: ClipOval(child: item['avatarUrl'] != null
            ? Image.network(item['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 22))
            : const Icon(Icons.person, color: Colors.white54, size: 22))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item['firstName']} ${item['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('Booked a session', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
        ])),
      ]),
    )).toList());
  }
}
