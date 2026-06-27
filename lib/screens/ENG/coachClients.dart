import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'coachInviteClients.dart';

class CoachClients extends StatefulWidget {
  const CoachClients({super.key});
  @override
  State<CoachClients> createState() => _CoachClientsState();
}

class _CoachClientsState extends State<CoachClients> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _clients = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/clients');
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _clients = result['data'] ?? [];
      _loading = false;
    });
  }

  List<dynamic> get _filtered => _clients.where((c) {
    final q = _query.toLowerCase();
    final mQ = '${c['firstName']} ${c['lastName']}'.toLowerCase().contains(q) || (c['email'] ?? '').toLowerCase().contains(q);
    final mF = _filter == 'All' || (_filter == 'Premium' && (c['isPremium'] == 1 || c['isPremium'] == true)) || (_filter == 'Standard' && !(c['isPremium'] == 1 || c['isPremium'] == true));
    return mQ && mF;
  }).toList();

  int get _premiumCount => _clients.where((c) => c['isPremium'] == 1 || c['isPremium'] == true).length;

  void _showInvitePremiumDialog(dynamic c) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF1A3008), shape: BoxShape.circle),
        child: const Icon(Icons.star_rounded, color: Color(0xFFA3FF12), size: 28)),
      const SizedBox(height: 16),
      const Text('Invite to Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Send a premium invitation to ${c['firstName']} ${c['lastName']}?',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () async {
            Navigator.pop(ctx);
            final r = await ApiService.post('/coach/clients/${c['id']}/invite-premium', {});
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(r['ok'] == true ? 'Invitation sent to ${c['firstName']}!' : r['message'] ?? 'Failed.'),
              backgroundColor: r['ok'] == true ? const Color(0xFF0D1A04) : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Invite', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : _filtered.isEmpty ? _buildEmpty()
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
                child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildClientCard(_filtered[i])))),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Clients', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachInviteClients())),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_add_rounded, color: Colors.black, size: 16), SizedBox(width: 6),
              Text('Invite', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
            ]))),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _statBox('${_clients.length}', 'Total', Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: _statBox('$_premiumCount', 'Premium', const Color(0xFFA3FF12))),
        const SizedBox(width: 10),
        Expanded(child: _statBox('${_clients.length - _premiumCount}', 'Standard', Colors.white.withOpacity(0.6))),
      ]),
      const SizedBox(height: 14),
      Container(decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Search clients...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
      const SizedBox(height: 12),
      Row(children: ['All', 'Premium', 'Standard'].map((f) {
        final sel = _filter == f;
        return GestureDetector(onTap: () => setState(() => _filter = f),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.1))),
            child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
      }).toList()),
    ]),
  );

  Widget _statBox(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w500)),
    ]));

  Widget _buildClientCard(dynamic c) {
    final isPremium = c['isPremium'] == 1 || c['isPremium'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPremium ? const Color(0xFFA3FF12).withOpacity(0.15) : Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Stack(children: [
          Container(width: 50, height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isPremium ? const Color(0xFFA3FF12).withOpacity(0.5) : Colors.white.withOpacity(0.08), width: 1.5)),
            child: ClipOval(child: c['avatarUrl'] != null
                ? Image.network(c['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 24))
                : const Icon(Icons.person, color: Colors.white54, size: 24))),
          if (isPremium) Positioned(right: 0, bottom: 0, child: Container(width: 18, height: 18,
            decoration: const BoxDecoration(color: Color(0xFFA3FF12), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.black, size: 11))),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${c['firstName']} ${c['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(c['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
        if (!isPremium)
          GestureDetector(onTap: () => _showInvitePremiumDialog(c),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Color(0xFFA3FF12), size: 14), SizedBox(width: 4),
                Text('Premium', style: TextStyle(color: Color(0xFFA3FF12), fontSize: 11, fontWeight: FontWeight.w700)),
              ])))
        else
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(10)),
            child: const Text('Premium', style: TextStyle(color: Color(0xFFA3FF12), fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.people_outline_rounded, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No clients found', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
  ]));
}
