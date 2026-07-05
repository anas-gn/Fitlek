import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerPendingCoaches extends StatefulWidget {
  const ManagerPendingCoaches({super.key});
  @override
  State<ManagerPendingCoaches> createState() => _ManagerPendingCoachesState();
}

class _ManagerPendingCoachesState extends State<ManagerPendingCoaches> {
  bool _loading = true;
  List<dynamic> _pending = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/manager/pending-coaches');
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _pending = result['data'] ?? [];
      _loading = false;
    });
  }

  void _accept(dynamic c) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF0D1A04), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFFA3FF12), size: 28)),
      const SizedBox(height: 14),
      const Text('Accept Coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Approve ${c['firstName']} ${c['lastName']} as a certified coach?',
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
            final r = await ApiService.patch('/manager/pending-coaches/${c['id']}/accept');
            if (!mounted) return;
            if (r['ok'] == true) _load();
            else ApiService.showError(context, r['message'] ?? 'Failed.');
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Accept', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  void _reject(dynamic c) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 20)),
          const SizedBox(width: 12),
          const Text('Reject Application', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Text('Provide a reason for rejecting ${c['firstName']} ${c['lastName']}\'s application.',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
        const SizedBox(height: 14),
        TextField(controller: ctrl, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Reason for rejection...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final r = await ApiService.patch('/manager/pending-coaches/${c['id']}/reject', {'reason': ctrl.text.trim()});
              if (!mounted) return;
              if (r['ok'] == true) _load();
              else ApiService.showError(context, r['message'] ?? 'Failed.');
            },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
        ]),
      ])),
    ));
  }

  void _showDetail(dynamic c) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFB800), width: 2.5)),
          child: ClipOval(child: c['avatarUrl'] != null
              ? Image.network(c['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.sports_rounded, color: Colors.white54, size: 36))
              : const Icon(Icons.sports_rounded, color: Colors.white54, size: 36))),
        const SizedBox(height: 12),
        Text('${c['firstName']} ${c['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(c['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _chip(c['gender'] ?? '', Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.07)),
          const SizedBox(width: 6),
          _chip('Certificate Submitted', const Color(0xFF7C4DFF), const Color(0xFF1A0A2A)),
        ]),
      ])),
      const SizedBox(height: 20),
      if (c['instagramPage'] != null) Row(children: [
        const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 16), const SizedBox(width: 8),
        Text(c['instagramPage'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      Text('Bio', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: Text(c['bio'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.6))),
      const SizedBox(height: 16),
      Container(width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1A0A2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF7C4DFF), size: 22), const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Certificate Submitted', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Verified during registration', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ]),
        ])),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () { Navigator.pop(ctx); _reject(c); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
            child: const Center(child: Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: () { Navigator.pop(ctx); _accept(c); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Accept', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  Widget _chip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(children: [
            const Text('Pending Coaches', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF2A1F00), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3))),
              child: Text('${_pending.length} pending', style: const TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w700))),
          ])),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : _pending.isEmpty ? _buildEmpty()
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
                child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _pending.length,
                  itemBuilder: (_, i) => _buildCard(_pending[i])))),
      ]),
    );
  }

  Widget _buildCard(dynamic c) => GestureDetector(
    onTap: () => _showDetail(c),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.4), width: 1.5)),
            child: ClipOval(child: c['avatarUrl'] != null
                ? Image.network(c['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.sports_rounded, color: Colors.white54, size: 26))
                : const Icon(Icons.sports_rounded, color: Colors.white54, size: 26))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${c['firstName']} ${c['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(c['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
            const SizedBox(height: 5),
            Row(children: [
              _chip(c['gender'] ?? '', Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.07)),
              const SizedBox(width: 6),
              _chip('Certified', const Color(0xFF7C4DFF), const Color(0xFF1A0A2A)),
            ]),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFF2A1F00), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3))),
            child: const Text('Pending', style: TextStyle(color: Color(0xFFFFB800), fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        if (c['bio'] != null) ...[
          const SizedBox(height: 12),
          Text(c['bio'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.5)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _reject(c),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.25))),
              child: const Center(child: Text('Reject', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w700)))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(onTap: () => _accept(c),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('Accept', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)))))),
        ]),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.how_to_reg_rounded, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No pending coaches', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
    const SizedBox(height: 6),
    Text('All applications have been reviewed.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
  ]));
}
