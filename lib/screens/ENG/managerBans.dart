import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerBans extends StatefulWidget {
  const ManagerBans({super.key});
  @override
  State<ManagerBans> createState() => _ManagerBansState();
}

class _ManagerBansState extends State<ManagerBans> {
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _bans = [];

  @override
  void initState() { super.initState(); _loadBans(); }

  Future<void> _loadBans() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/manager/bans?filter=$_filter');
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _bans = result['data'] ?? [];
      _loading = false;
    });
  }

  void _unban(dynamic b) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF0D1A04), shape: BoxShape.circle),
        child: const Icon(Icons.lock_open_rounded, color: Color(0xFFA3FF12), size: 26)),
      const SizedBox(height: 14),
      const Text('Unban User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Remove the ban on ${b['firstName']} ${b['lastName']}?',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () async {
            Navigator.pop(ctx);
            final r = await ApiService.patch('/manager/bans/${b['id']}/unban');
            if (!mounted) return;
            if (r['ok'] == true) _loadBans();
            else ApiService.showError(context, r['message'] ?? 'Unban failed.');
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Unban', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  void _showDetail(dynamic b) {
    final isPerm = b['banType'] == 'permanent';
    final banColor = isPerm ? Colors.red : const Color(0xFFFFB800);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: banColor.withOpacity(0.4), width: 1.5)),
            child: ClipOval(child: b['avatarUrl'] != null
                ? Image.network(b['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 22))
                : const Icon(Icons.person, color: Colors.white54, size: 22))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${b['firstName']} ${b['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(b['userRole'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: banColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: banColor.withOpacity(0.3))),
            child: Text(isPerm ? 'Permanent' : 'Temporary', style: TextStyle(color: banColor, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        Text('Reason', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: Text(b['reason'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.6))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () { Navigator.pop(ctx); _unban(b); },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Unban', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
        ]),
      ])),
    ));
  }

  String _timeAgo(String? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(DateTime.parse(dt));
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : _bans.isEmpty ? _buildEmpty()
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _loadBans,
                child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _bans.length,
                  itemBuilder: (_, i) => _buildBanCard(_bans[i])))),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Bans', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
          child: Text('${_bans.length} active', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Temporary', 'Permanent', 'Clients', 'Coaches'].map((f) {
          final sel = _filter == f;
          return GestureDetector(onTap: () { setState(() => _filter = f); _loadBans(); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.1))),
              child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
    ]),
  );

  Widget _buildBanCard(dynamic b) {
    final isPerm = b['banType'] == 'permanent';
    final banColor = isPerm ? Colors.red : const Color(0xFFFFB800);
    final userRole = b['userRole'] ?? 'client';
    final typeColor = userRole == 'coach' ? const Color(0xFF7C4DFF) : const Color(0xFF00BCD4);
    return GestureDetector(
      onTap: () => _showDetail(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18), border: Border.all(color: banColor.withOpacity(0.15))),
        child: Row(children: [
          Stack(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: banColor.withOpacity(0.4), width: 1.5)),
              child: ClipOval(child: b['avatarUrl'] != null
                  ? Image.network(b['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 24))
                  : const Icon(Icons.person, color: Colors.white54, size: 24))),
            Positioned(right: 0, bottom: 0, child: Container(width: 16, height: 16,
              decoration: BoxDecoration(color: banColor, shape: BoxShape.circle),
              child: const Icon(Icons.block_rounded, color: Colors.white, size: 10))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${b['firstName']} ${b['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(children: [
              _chip(userRole == 'coach' ? 'Coach' : 'Client', typeColor, typeColor.withOpacity(0.1)),
              const SizedBox(width: 6),
              _chip(isPerm ? 'Permanent' : 'Temporary', banColor, banColor.withOpacity(0.1)),
            ]),
            const SizedBox(height: 4),
            Text(_timeAgo(b['bannedAt']), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ])),
          GestureDetector(onTap: () => _unban(b),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3))),
              child: const Text('Unban', style: TextStyle(color: Color(0xFFA3FF12), fontSize: 11, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.25))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.lock_open_rounded, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No active bans', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
  ]));
}
