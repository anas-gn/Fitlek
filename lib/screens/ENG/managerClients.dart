import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'managerCreateClient.dart';
import 'managerEditClient.dart';

class ManagerClients extends StatefulWidget {
  const ManagerClients({super.key});
  @override
  State<ManagerClients> createState() => _ManagerClientsState();
}

class _ManagerClientsState extends State<ManagerClients> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _clients = [];

  @override
  void initState() { super.initState(); _loadClients(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    String path = '/manager/clients?filter=$_filter';
    if (_query.isNotEmpty) path += '&search=$_query';
    final result = await ApiService.get(path);
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _clients = result['data'] ?? [];
      _loading = false;
    });
  }

  void _deleteClient(dynamic c) {
    showDialog(context: context, builder: (ctx) => _ConfirmDialog(
      title: 'Delete Client',
      message: 'Delete ${c['firstName']} ${c['lastName']}? This cannot be undone.',
      actionLabel: 'Delete', actionColor: Colors.red,
      onConfirm: () async {
        Navigator.pop(ctx);
        final r = await ApiService.delete('/manager/clients/${c['id']}');
        if (!mounted) return;
        if (r['ok'] == true) _loadClients();
        else ApiService.showError(context, r['message'] ?? 'Delete failed.');
      },
    ));
  }

  void _makeAdmin(dynamic c) {
    showDialog(context: context, builder: (ctx) => _ConfirmDialog(
      title: 'Make Remote Admin',
      message: 'Grant admin privileges to ${c['firstName']} ${c['lastName']}?',
      actionLabel: 'Grant', actionColor: const Color(0xFFA3FF12), actionTextColor: Colors.black,
      onConfirm: () async {
        Navigator.pop(ctx);
        final r = await ApiService.patch('/manager/clients/${c['id']}/make-admin');
        if (!mounted) return;
        if (r['ok'] == true) _loadClients();
        else ApiService.showError(context, r['message'] ?? 'Failed.');
      },
    ));
  }

  void _showBanDialog(dynamic c) {
    String selectedType = 'temporary';
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setS) => Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.block_rounded, color: Colors.red, size: 20)),
            const SizedBox(width: 12),
            const Text('Ban Client', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setS(() => selectedType = 'temporary'),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'temporary' ? const Color(0xFFFFB800).withOpacity(0.15) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selectedType == 'temporary' ? const Color(0xFFFFB800) : Colors.transparent, width: 1.5)),
                child: Column(children: [
                  Icon(Icons.timer_rounded, color: selectedType == 'temporary' ? const Color(0xFFFFB800) : Colors.white54, size: 20),
                  const SizedBox(height: 4),
                  Text('Temporary', style: TextStyle(color: selectedType == 'temporary' ? const Color(0xFFFFB800) : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                ])))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () => setS(() => selectedType = 'permanent'),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'permanent' ? Colors.red.withOpacity(0.12) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selectedType == 'permanent' ? Colors.red : Colors.transparent, width: 1.5)),
                child: Column(children: [
                  Icon(Icons.block_rounded, color: selectedType == 'permanent' ? Colors.red : Colors.white54, size: 20),
                  const SizedBox(height: 4),
                  Text('Permanent', style: TextStyle(color: selectedType == 'permanent' ? Colors.red : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                ])))),
          ]),
          const SizedBox(height: 14),
          TextField(controller: reasonCtrl, maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(hintText: 'Reason for ban...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
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
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final body = {'banType': selectedType, 'reason': reasonCtrl.text.trim()};
                if (selectedType == 'temporary') {
                  body['expiresAt'] = DateTime.now().add(const Duration(days: 30)).toIso8601String();
                }
                final r = await ApiService.post('/manager/clients/${c['id']}/ban', body);
                if (!mounted) return;
                if (r['ok'] == true) _loadClients();
                else ApiService.showError(context, r['message'] ?? 'Ban failed.');
              },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Ban', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
          ]),
        ])),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: GestureDetector(
        onTap: () async {
          final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagerCreateClient()));
          if (created == true) _loadClients();
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
          : _clients.isEmpty ? _buildEmpty()
          : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _loadClients,
              child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: _clients.length,
                itemBuilder: (_, i) => _buildClientCard(_clients[i])))),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Clients', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3))),
          child: Text('${_clients.length} total', style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 14),
      Container(decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TextField(controller: _searchCtrl,
          onChanged: (v) { _query = v; _loadClients(); },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Search clients...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Premium', 'Standard', 'Banned', 'Remote Admin'].map((f) {
          final sel = _filter == f;
          return GestureDetector(onTap: () { setState(() => _filter = f); _loadClients(); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.1))),
              child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
    ]),
  );

  Widget _buildClientCard(dynamic c) {
    final isBanned = c['isBanned'] == 1 || c['isBanned'] == true;
    final isAdmin = c['role'] == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isBanned ? Colors.red.withOpacity(0.2) : isAdmin ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.white.withOpacity(0.04))),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isBanned ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.1), width: 1.5)),
          child: ClipOval(child: c['avatarUrl'] != null
            ? Image.network(c['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 24))
            : const Icon(Icons.person, color: Colors.white54, size: 24))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${c['firstName']} ${c['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(c['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            if (c['isPremium'] == 1 || c['isPremium'] == true) _badge('Premium', const Color(0xFFA3FF12), const Color(0xFF1A3008)),
            if (isBanned) ...[const SizedBox(width: 6), _badge('Banned', Colors.red, Colors.red.withOpacity(0.1))],
            if (isAdmin) ...[const SizedBox(width: 6), _badge('Admin', const Color(0xFF00BCD4), const Color(0xFF001A1E))],
          ]),
        ])),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.4), size: 20),
          color: const Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) async {
            if (val == 'edit') {
              final updated = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManagerEditClient(clientData: c)));
              if (updated == true) _loadClients();
            } else if (val == 'delete') { _deleteClient(c); }
            else if (val == 'admin') { _makeAdmin(c); }
            else if (val == 'ban') { _showBanDialog(c); }
          },
          itemBuilder: (_) => [
            _popItem('edit', Icons.edit_rounded, 'Edit', Colors.white),
            if (!isAdmin) _popItem('admin', Icons.admin_panel_settings_rounded, 'Make Admin', const Color(0xFF00BCD4)),
            if (!isBanned) _popItem('ban', Icons.block_rounded, 'Ban', const Color(0xFFFFB800)),
            _popItem('delete', Icons.delete_rounded, 'Delete', Colors.red),
          ],
        ),
      ])),
    );
  }

  Widget _badge(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, Color color) =>
    PopupMenuItem(value: val, child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))]));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.people_outline_rounded, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No clients found', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
  ]));
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, actionLabel;
  final Color actionColor;
  final Color actionTextColor;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.message, required this.actionLabel, required this.actionColor, required this.onConfirm, this.actionTextColor = Colors.white});

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
            child: Center(child: Text(actionLabel, style: TextStyle(color: actionTextColor, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  );
}
