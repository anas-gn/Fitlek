import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'managerCreateAdmin.dart';
import 'managerEditAdmin.dart';

class ManagerAdmins extends StatefulWidget {
  const ManagerAdmins({super.key});
  @override
  State<ManagerAdmins> createState() => _ManagerAdminsState();
}

class _ManagerAdminsState extends State<ManagerAdmins> {
  bool _loading = true;
  List<dynamic> _admins = [];

  @override
  void initState() { super.initState(); _loadAdmins(); }

  Future<void> _loadAdmins() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/manager/admins');
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _admins = result['data'] ?? [];
      _loading = false;
    });
  }

  void _unremote(dynamic a) => showDialog(context: context, builder: (ctx) => _Dialog(
    title: 'Unremote Admin',
    message: '${a['firstName']} ${a['lastName']} will be returned to a regular client account.',
    actionLabel: 'Unremote', actionColor: Colors.orange,
    onConfirm: () async {
      Navigator.pop(ctx);
      final r = await ApiService.patch('/manager/admins/${a['id']}/unremote');
      if (!mounted) return;
      if (r['ok'] == true) _loadAdmins();
      else ApiService.showError(context, r['message'] ?? 'Failed.');
    },
  ));

  void _delete(dynamic a) => showDialog(context: context, builder: (ctx) => _Dialog(
    title: 'Delete Admin',
    message: 'Remove ${a['firstName']} ${a['lastName']}? This cannot be undone.',
    actionLabel: 'Delete', actionColor: Colors.red,
    onConfirm: () async {
      Navigator.pop(ctx);
      final r = await ApiService.delete('/manager/admins/${a['id']}');
      if (!mounted) return;
      if (r['ok'] == true) _loadAdmins();
      else ApiService.showError(context, r['message'] ?? 'Delete failed.');
    },
  ));

  String _sinceLabel(String? createdAt) {
    if (createdAt == null) return '';
    final d = DateTime.now().difference(DateTime.parse(createdAt)).inDays;
    if (d == 0) return 'Today';
    if (d == 1) return 'Yesterday';
    return '$d days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: GestureDetector(
        onTap: () async {
          final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerCreateAdmin()));
          if (created == true) _loadAdmins();
        },
        child: Container(width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFA3FF12), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 26)),
      ),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
          : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _loadAdmins,
              child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: _admins.length,
                itemBuilder: (_, i) => _buildAdminCard(_admins[i])))),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Admins', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF001A1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3))),
          child: Text('${_admins.length} total', style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF001A1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2))),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('To make a client an admin, use "Make Admin" in the Clients section. Use "Unremote" here to return an admin to client status.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5))),
        ])),
    ]),
  );

  Widget _buildAdminCard(dynamic a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.12))),
    child: Row(children: [
      Container(width: 50, height: 50,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.4), width: 1.5)),
        child: ClipOval(child: a['avatarUrl'] != null
          ? Image.network(a['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.admin_panel_settings_rounded, color: Colors.white54, size: 24))
          : const Icon(Icons.admin_panel_settings_rounded, color: Colors.white54, size: 24))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${a['firstName']} ${a['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(a['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        const SizedBox(height: 4),
        Text('Added ${_sinceLabel(a['createdAt'])}', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
      ])),
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.4), size: 20),
        color: const Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (val) async {
          if (val == 'edit') {
            final updated = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManagerEditAdmin(adminData: a)));
            if (updated == true) _loadAdmins();
          } else if (val == 'unremote') { _unremote(a); }
          else if (val == 'delete') { _delete(a); }
        },
        itemBuilder: (_) => [
          _popItem('edit', Icons.edit_rounded, 'Edit', Colors.white),
          _popItem('unremote', Icons.person_remove_rounded, 'Unremote Admin', Colors.orange),
          _popItem('delete', Icons.delete_rounded, 'Delete', Colors.red),
        ],
      ),
    ]),
  );

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, Color color) =>
    PopupMenuItem(value: val, child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))]));
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
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: onConfirm,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: actionColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  );
}
