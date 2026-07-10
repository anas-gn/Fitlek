import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import '../../services/apiService.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});
  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> with SingleTickerProviderStateMixin {
  static const bg = Color(0xFF0A0A0A);
  static const lime = Color(0xFFC6F135);
  static const card = Color(0xFF141414);
  static const border = Color(0xFF232323);

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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
      _animController.forward(from: 0);
    } else {
      setState(() => _loading = false);
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'BONJOUR, COACH';
    if (h < 17) return 'BON APRÈS-MIDI, COACH';
    return 'BONSOIR, COACH';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _loading ? _buildShimmer() : RefreshIndicator(
          color: lime,
          backgroundColor: card,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeTransition(opacity: _cardAnims[0], child: _buildHeader()),
              const SizedBox(height: 24),
              FadeTransition(opacity: _cardAnims[1], child: SlideTransition(
                position: _cardAnims[1].drive(Tween(begin: const Offset(0, 0.08), end: Offset.zero)),
                child: _buildHeroCard())),
              const SizedBox(height: 20),
              FadeTransition(opacity: _cardAnims[2], child: _buildStatsGrid()),
              const SizedBox(height: 28),
              FadeTransition(opacity: _cardAnims[3], child: _buildSectionHeader()),
              const SizedBox(height: 14),
              FadeTransition(opacity: _cardAnims[4], child: _buildActivityList()),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_getGreeting(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4)),
      const SizedBox(height: 6),
      const Text('Aperçu', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1)),
    ]);
  }

  Widget _buildSectionHeader() {
    return Row(children: const [
      Text('ACTIVITÉ RÉCENTE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
    ]);
  }

  Widget _buildHeroCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: lime,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: lime.withOpacity(0.25), blurRadius: 28, offset: const Offset(0, 14))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RÉSERVATIONS TOTALES', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        Text('$_totalReservations', style: const TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.w700, height: 1)),
        const SizedBox(height: 14),
        Row(children: [
          _heroBadge('$_confirmedReservations confirmées'),
          const SizedBox(width: 8),
          _heroBadge('$_pendingReservations en attente'),
        ]),
      ])),
      Container(width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.calendar_today_rounded, color: Colors.black87, size: 28)),
    ]),
  );

  Widget _heroBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)));

  Widget _buildStatsGrid() {
    final stats = [
      _StatData('Clients', '$_totalClients', Icons.groups_rounded, lime),
      _StatData('En attente', '$_pendingReservations', Icons.hourglass_top_rounded, const Color(0xFFFFB800)),
      _StatData('Confirmées', '$_confirmedReservations', Icons.check_circle_rounded, const Color(0xFF00E676)),
      _StatData('Points', '$_invitationPoints', Icons.star_rounded, const Color(0xFFBB86FC)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map((s) => _StatCard(data: s)).toList(),
    );
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
        child: Column(children: [
          Icon(Icons.inbox_rounded, color: Colors.white.withOpacity(0.15), size: 32),
          const SizedBox(height: 10),
          Text('Aucune activité récente', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ]),
      );
    }
    return Column(children: _recentActivity.map((item) => _ActivityTile(item: item)).toList());
  }

  Widget _buildShimmer() {
    Widget block(double h, {double w = double.infinity, double r = 16}) => Shimmer.fromColors(
      baseColor: card,
      highlightColor: border,
      child: Container(height: h, width: w, decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(r))),
    );
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        block(14, w: 140, r: 4),
        const SizedBox(height: 10),
        block(34, w: 160, r: 6),
        const SizedBox(height: 24),
        block(160, r: 24),
        const SizedBox(height: 20),
        Row(children: [Expanded(child: block(110)), const SizedBox(width: 12), Expanded(child: block(110))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: block(110)), const SizedBox(width: 12), Expanded(child: block(110))]),
        const SizedBox(height: 28),
        block(14, w: 160, r: 4),
        const SizedBox(height: 14),
        block(70),
        const SizedBox(height: 10),
        block(70),
        const SizedBox(height: 10),
        block(70),
      ]),
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CoachDashboardState.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CoachDashboardState.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: data.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(data.icon, color: data.color, size: 18),
        ),
        const SizedBox(height: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1)),
          const SizedBox(height: 3),
          Text(data.label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ]),
      ]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final dynamic item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = (item['avatarUrl'] as String?)?.trim();
    final hasRealAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final fallbackUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent('${item['firstName'] ?? ''} ${item['lastName'] ?? ''}')}&background=141414&color=C6F135';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _CoachDashboardState.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachDashboardState.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _CoachDashboardState.lime.withOpacity(0.4), width: 1.4)),
          child: ClipOval(
            child: Image.network(
              hasRealAvatar ? avatarUrl : fallbackUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.network(fallbackUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white38, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item['firstName'] ?? ''} ${item['lastName'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('A réservé une séance', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
      ]),
    );
  }
}