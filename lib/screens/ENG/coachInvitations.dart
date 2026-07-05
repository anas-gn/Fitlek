import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class CoachInvitations extends StatefulWidget {
  const CoachInvitations({super.key});
  @override
  State<CoachInvitations> createState() => _CoachInvitationsState();
}

class _CoachInvitationsState extends State<CoachInvitations> {
  bool _loading = true;
  List<dynamic> _invitations = [];
  int _totalPoints = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/invitations');
    if (!mounted) return;
    if (result['ok'] == true) {
      final list = List<dynamic>.from(result['data'] ?? []);
      setState(() {
        _invitations = list;
        _totalPoints = list.fold(0, (sum, inv) => sum + ((inv['pointsEarned'] as num?)?.toInt() ?? 0));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    final d = DateTime.parse(dt);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12)))
            : RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    if (_invitations.isEmpty)
                      Padding(padding: const EdgeInsets.only(top: 60),
                        child: Column(children: [
                          Icon(Icons.link_off_rounded, color: Colors.white.withOpacity(0.15), size: 56),
                          const SizedBox(height: 12),
                          Text('No invitations clicked yet', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
                        ]))
                    else
                      ..._invitations.map((inv) => _buildInvitationItem(inv)).toList(),
                    const SizedBox(height: 20),
                  ]),
                ))),
      ])),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
      const SizedBox(width: 16),
      const Text('Invitations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    ]));

  Widget _buildSummaryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA3FF12), Color(0xFF7ACC00)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Earned Points', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text('$_totalPoints pts', style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.w900, height: 1, letterSpacing: -0.5)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${_invitations.length}', style: const TextStyle(color: Colors.black, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
        Text('total invites', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );

  Widget _buildInvitationItem(dynamic inv) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: const Color(0xFF1A3008), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3), width: 1.5)),
        child: Center(child: Text('${inv['firstName']?[0] ?? '?'}',
            style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 18, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${inv['firstName']} ${inv['lastName']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(_formatDate(inv['clickedAt']), style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3))),
        child: Text('+${inv['pointsEarned']} pts', style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 13, fontWeight: FontWeight.w700))),
    ]),
  );
}
