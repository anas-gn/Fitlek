import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'managerCreateCoach.dart';
import 'managerEditCoach.dart';

class ManagerCoaches extends StatefulWidget {
  const ManagerCoaches({super.key});
  @override
  State<ManagerCoaches> createState() => _ManagerCoachesState();
}

class _ManagerCoachesState extends State<ManagerCoaches> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _coaches = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    String path = '/manager/coaches?filter=$_filter';
    if (_query.isNotEmpty) path += '&search=$_query';
    final result = await ApiService.get(path);
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _coaches = result['data'] ?? [];
      _loading = false;
    });
  }

  void _delete(dynamic c) => showDialog(context: context, builder: (ctx) => _Dialog(
    title: 'Delete Coach',
    message: 'Delete ${c['firstName']} ${c['lastName']}? This cannot be undone.',
    actionLabel: 'Delete', actionColor: Colors.red,
    onConfirm: () async {
      Navigator.pop(ctx);
      final r = await ApiService.delete('/manager/coaches/${c['id']}');
      if (!mounted) return;
      if (r['ok'] == true) _load();
      else ApiService.showError(context, r['message'] ?? 'Delete failed.');
    },
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: GestureDetector(
        onTap: () async {
          final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerCreateCoach()));
          if (created == true) _load();
        },
        child: Container(width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFA3FF12), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 26)),
      ),
      body: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
          : _coaches.isEmpty ? _buildEmpty()
          : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: _coaches.length,
                itemBuilder: (_, i) => _buildCoachCard(_coaches[i])))),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Coaches', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF1A0A2A), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3))),
          child: Text('${_coaches.length} total', style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 14),
      Container(decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TextField(controller: _searchCtrl,
          onChanged: (v) { _query = v; _load(); },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Search coaches...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
      const SizedBox(height: 10),
      Row(children: ['All', 'Active', 'Banned'].map((f) {
        final sel = _filter == f;
        return GestureDetector(onTap: () { setState(() => _filter = f); _load(); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.1))),
            child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6),
                fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
      }).toList()),
    ]),
  );

  Widget _buildCoachCard(dynamic c) {
    final isBanned = c['isBanned'] == 1 || c['isBanned'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isBanned ? Colors.red.withOpacity(0.2) : const Color(0xFF7C4DFF).withOpacity(0.1))),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Stack(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: isBanned ? Colors.red.withOpacity(0.5) : const Color(0xFF7C4DFF).withOpacity(0.4), width: 1.5)),
            child: ClipOval(child: c['avatarUrl'] != null
                ? Image.network(c['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.sports_rounded, color: Colors.white54, size: 26))
                : const Icon(Icons.sports_rounded, color: Colors.white54, size: 26))),
          Positioned(right: 0, bottom: 0, child: Container(width: 18, height: 18,
            decoration: BoxDecoration(color: isBanned ? Colors.red : const Color(0xFF7C4DFF), shape: BoxShape.circle),
            child: Icon(isBanned ? Icons.block_rounded : Icons.verified_rounded, color: Colors.white, size: 11))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${c['firstName']} ${c['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(c['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            _statChip(Icons.group_rounded, '${c['totalClients'] ?? 0}', const Color(0xFFA3FF12)),
            const SizedBox(width: 8),
            _statChip(Icons.calendar_today_rounded, '${c['totalReservations'] ?? 0}', const Color(0xFF00BCD4)),
            if (isBanned) ...[const SizedBox(width: 8), _badge('Banned', Colors.red, Colors.red.withOpacity(0.1))],
          ]),
        ])),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.4), size: 20),
          color: const Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) async {
            if (val == 'edit') {
              final updated = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManagerEditCoach(coachData: c)));
              if (updated == true) _load();
            } else if (val == 'delete') { _delete(c); }
          },
          itemBuilder: (_) => [
            _popItem('edit', Icons.edit_rounded, 'Edit', Colors.white),
            _popItem('delete', Icons.delete_rounded, 'Delete', Colors.red),
          ],
        ),
      ])),
    );
  }

  Widget _statChip(IconData icon, String val, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 12), const SizedBox(width: 3),
    Text(val, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))]);

  Widget _badge(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, Color color) =>
    PopupMenuItem(value: val, child: Row(children: [
      Icon(icon, color: color, size: 18), const SizedBox(width: 10),
      Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))]));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.sports_outlined, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No coaches found', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15))]));
}

class _Dialog extends StatelessWidget {
  final String title, message, actionLabel;
  final Color actionColor;
  final VoidCallback onConfirm;
  const _Dialog({required this.title, required this.message, required this.actionLabel, required this.actionColor, required this.onConfirm});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF111111), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: onConfirm,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: actionColor, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  );
}
