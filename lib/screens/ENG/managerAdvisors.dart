import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerAdvisors extends StatefulWidget {
  const ManagerAdvisors({super.key});
  @override
  State<ManagerAdvisors> createState() => _ManagerAdvisorsState();
}

class _ManagerAdvisorsState extends State<ManagerAdvisors> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _advisors = [];

  static const _specialtyColors = <String, Color>{
    'Nutrition':        Color(0xFFA3FF12),
    'Mental Health':    Color(0xFF7C4DFF),
    'Physical Therapy': Color(0xFF00BCD4),
    'Sports Psychology':Color(0xFFFFB800),
  };

  @override
  void initState() { super.initState(); _loadAdvisors(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadAdvisors() async {
    setState(() => _loading = true);
    String path = '/manager/advisors?filter=$_filter';
    if (_query.isNotEmpty) path += '&search=$_query';
    final result = await ApiService.get(path);
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _advisors = result['data'] ?? [];
      _loading = false;
    });
  }

  void _delete(dynamic a) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 26)),
      const SizedBox(height: 14),
      const Text('Delete Advisor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Remove ${a['firstName']} ${a['lastName']}? This cannot be undone.',
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
            final r = await ApiService.delete('/manager/advisors/${a['id']}');
            if (!mounted) return;
            if (r['ok'] == true) _loadAdvisors();
            else ApiService.showError(context, r['message'] ?? 'Delete failed.');
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  void _showDetail(dynamic a) {
    final color = _specialtyColors[a['specialty']] ?? const Color(0xFFA3FF12);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2.5)),
          child: ClipOval(child: a['avatarUrl'] != null
              ? Image.network(a['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.support_agent_rounded, color: Colors.white54, size: 32))
              : const Icon(Icons.support_agent_rounded, color: Colors.white54, size: 32))),
        const SizedBox(height: 12),
        Text('${a['firstName']} ${a['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(a['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
          child: Text(a['specialty'] ?? '', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(height: 20),
        GestureDetector(onTap: () => Navigator.pop(ctx),
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))))),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : _advisors.isEmpty ? _buildEmpty()
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _loadAdvisors,
                child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _advisors.length,
                  itemBuilder: (_, i) => _buildCard(_advisors[i])))),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Advisors', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF2A1F00), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3))),
          child: Text('${_advisors.length} total', style: const TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 14),
      Container(decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TextField(controller: _searchCtrl,
          onChanged: (v) { _query = v; _loadAdvisors(); },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Search advisors...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Nutrition', 'Mental Health', 'Physical Therapy', 'Sports Psychology'].map((f) {
          final sel = _filter == f;
          final color = _specialtyColors[f] ?? const Color(0xFFA3FF12);
          return GestureDetector(onTap: () { setState(() => _filter = f); _loadAdvisors(); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? color : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? color : Colors.white.withOpacity(0.1))),
              child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
    ]),
  );

  Widget _buildCard(dynamic a) {
    final color = _specialtyColors[a['specialty']] ?? const Color(0xFFA3FF12);
    return GestureDetector(
      onTap: () => _showDetail(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.1))),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4), width: 1.5)),
            child: ClipOval(child: a['avatarUrl'] != null
                ? Image.network(a['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.support_agent_rounded, color: Colors.white54, size: 24))
                : const Icon(Icons.support_agent_rounded, color: Colors.white54, size: 24))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a['firstName']} ${a['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(a['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
            const SizedBox(height: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.25))),
              child: Text(a['specialty'] ?? '', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
          ])),
          GestureDetector(onTap: () => _delete(a),
            child: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18))),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.support_agent_outlined, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No advisors found', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
  ]));
}
