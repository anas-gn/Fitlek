import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerReservations extends StatefulWidget {
  const ManagerReservations({super.key});
  @override
  State<ManagerReservations> createState() => _ManagerReservationsState();
}

class _ManagerReservationsState extends State<ManagerReservations> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;
  List<dynamic> _reservations = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    String path = '/manager/reservations?filter=$_filter';
    if (_query.isNotEmpty) path += '&search=$_query';
    final result = await ApiService.get(path);
    if (!mounted) return;
    setState(() {
      if (result['ok'] == true) _reservations = result['data'] ?? [];
      _loading = false;
    });
  }

  int get _confirmed  => _reservations.where((r) => r['status'] == 'confirmed').length;
  int get _pending    => _reservations.where((r) => r['status'] == 'pending').length;
  int get _cancelled  => _reservations.where((r) => r['status'] == 'cancelled').length;

  void _delete(dynamic r) => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 26)),
      const SizedBox(height: 14),
      const Text('Delete Reservation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Delete the reservation between ${r['clientFirstName']} ${r['clientLastName']} and ${r['coachFirstName']} ${r['coachLastName']}?',
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
            final res = await ApiService.delete('/manager/reservations/${r['id']}');
            if (!mounted) return;
            if (res['ok'] == true) _load();
            else ApiService.showError(context, res['message'] ?? 'Delete failed.');
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  void _showDetail(dynamic r) {
    final statusColor = r['status'] == 'confirmed' ? const Color(0xFFA3FF12) : r['status'] == 'pending' ? const Color(0xFFFFB800) : Colors.red;
    final statusLabel = r['status'] == 'confirmed' ? 'Confirmed' : r['status'] == 'pending' ? 'Pending' : 'Cancelled';
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Reservation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: _personBlock(r['clientAvatarUrl'], '${r['clientFirstName']} ${r['clientLastName']}', 'Client', const Color(0xFF00BCD4))),
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08)),
            Expanded(child: _personBlock(r['coachAvatarUrl'], '${r['coachFirstName']} ${r['coachLastName']}', 'Coach', const Color(0xFF7C4DFF))),
          ])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: _infoBlock(Icons.calendar_today_rounded, 'Date', r['reservedDate'] ?? '', const Color(0xFFA3FF12))),
            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08)),
            Expanded(child: _infoBlock(Icons.access_time_rounded, 'Time', r['reservedTime'] ?? '', const Color(0xFF00BCD4))),
          ])),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(onTap: () { Navigator.pop(ctx); _delete(r); },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
        ]),
      ])),
    ));
  }

  Widget _personBlock(String? url, String name, String role, Color color) => Column(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4), width: 1.5)),
      child: ClipOval(child: url != null
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: color.withOpacity(0.6), size: 22))
          : Icon(Icons.person, color: color.withOpacity(0.6), size: 22))),
    const SizedBox(height: 8),
    Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  Widget _infoBlock(IconData icon, String label, String value, Color color) => Column(children: [
    Icon(icon, color: color, size: 18), const SizedBox(height: 6),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
    const SizedBox(height: 2),
    Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : _reservations.isEmpty ? _buildEmpty()
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
                child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _reservations.length,
                  itemBuilder: (_, i) => _buildCard(_reservations[i])))),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Reservations', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _summaryCard('${_reservations.length}', 'Total', Colors.white, const Color(0xFF111111))),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('$_confirmed', 'Confirmed', const Color(0xFFA3FF12), const Color(0xFF0D1A04))),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('$_pending', 'Pending', const Color(0xFFFFB800), const Color(0xFF2A1F00))),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('$_cancelled', 'Cancelled', Colors.red, const Color(0xFF1A0808))),
      ]),
      const SizedBox(height: 14),
      Container(decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TextField(controller: _searchCtrl,
          onChanged: (v) { _query = v; _load(); },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: 'Search by client or coach...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Confirmed', 'Pending', 'Cancelled'].map((f) {
          final sel = _filter == f;
          return GestureDetector(onTap: () { setState(() => _filter = f); _load(); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.1))),
              child: Text(f, style: TextStyle(color: sel ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
    ]),
  );

  Widget _summaryCard(String val, String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
    ]));

  Widget _buildCard(dynamic r) {
    final statusColor = r['status'] == 'confirmed' ? const Color(0xFFA3FF12) : r['status'] == 'pending' ? const Color(0xFFFFB800) : Colors.red;
    final statusLabel = r['status'] == 'confirmed' ? 'Confirmed' : r['status'] == 'pending' ? 'Pending' : 'Cancelled';
    return GestureDetector(
      onTap: () => _showDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(18), border: Border.all(color: statusColor.withOpacity(0.12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700))),
            const Spacer(),
            Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withOpacity(0.35)),
            const SizedBox(width: 5),
            Text(r['reservedDate'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.access_time_rounded, size: 12, color: Colors.white.withOpacity(0.35)),
            const SizedBox(width: 4),
            Text(r['reservedTime'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _miniPerson(r['clientAvatarUrl'], '${r['clientFirstName']} ${r['clientLastName']}', 'Client', const Color(0xFF00BCD4))),
            Container(width: 32, height: 32, margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), shape: BoxShape.circle),
              child: const Icon(Icons.swap_horiz_rounded, color: Colors.white54, size: 16)),
            Expanded(child: _miniPerson(r['coachAvatarUrl'], '${r['coachFirstName']} ${r['coachLastName']}', 'Coach', const Color(0xFF7C4DFF))),
          ]),
          const SizedBox(height: 10),
          GestureDetector(onTap: () => _delete(r),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.15))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_outline_rounded, color: Colors.red, size: 14), SizedBox(width: 6),
                Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ]))),
        ]),
      ),
    );
  }

  Widget _miniPerson(String? url, String name, String role, Color color) => Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4), width: 1.5)),
      child: ClipOval(child: url != null
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: color.withOpacity(0.6), size: 18))
          : Icon(Icons.person, color: color.withOpacity(0.6), size: 18))),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(role, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ])),
  ]);

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.15), size: 56), const SizedBox(height: 12),
    Text('No reservations found', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
  ]));
}
