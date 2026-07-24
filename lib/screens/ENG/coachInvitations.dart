import 'package:flutter/material.dart';
import '../../services/apiService.dart';

import '../../theme/fitlek_theme_extension.dart';
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
        _totalPoints = list
            .where((inv) => inv['status'] == 'accepted')
            .fold(
              0,
              (sum, inv) =>
                  sum + ((inv['pointsEarned'] as num?)?.toInt() ?? 0),
            );
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

  Future<void> _respond(dynamic inv, bool accept) async {
    final id = inv['id'];
    final action = accept ? 'accept' : 'refuse';
    final result = await ApiService.patch('/coach/invitations/$id/$action', {});
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        inv['status'] = accept ? 'accepted' : 'refused';
        if (accept) {
          final awarded =
              (result['pointsAwarded'] as num?)?.toInt() ?? 20;
          inv['pointsEarned'] = awarded;
          _totalPoints += awarded;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Something went wrong, please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : RefreshIndicator(color: cs.primary, backgroundColor: f.card, onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    if (_invitations.isEmpty)
                      Padding(padding: const EdgeInsets.only(top: 60),
                        child: Column(children: [
                          Icon(Icons.link_off_rounded, color: f.textMuted, size: 56),
                          const SizedBox(height: 12),
                          Text('No invitations clicked yet', style: TextStyle(color: f.textMuted, fontSize: 15)),
                        ]))
                    else
                      ..._invitations.map((inv) => _buildInvitationItem(inv)),
                    const SizedBox(height: 20),
                  ]),
                ))),
      ])),
    );
  }

  Widget _buildTopBar() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: f.border)),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 18))),
      const SizedBox(width: 16),
      Text('Invitations', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _buildSummaryCard() {
    final cs = Theme.of(context).colorScheme;
    final accepted =
        _invitations.where((inv) => inv['status'] == 'accepted').length;
    return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary, cs.primary.withValues(alpha: 0.85)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Client Invitation Points', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text('$_totalPoints pts', style: TextStyle(color: cs.onPrimary, fontSize: 36, fontWeight: FontWeight.w900, height: 1, letterSpacing: -0.5)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$accepted', style: TextStyle(color: cs.onPrimary, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
        Text('accepted clients', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
  }

  Widget _buildInvitationItem(dynamic inv) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: f.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.10), shape: BoxShape.circle, border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5)),
          child: Center(child: Text('${inv['firstName']?[0] ?? '?'}',
              style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${inv['firstName']} ${inv['lastName']}', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(_formatDate(inv['clickedAt']), style: TextStyle(color: f.textMuted, fontSize: 12)),
        ])),
        if (inv['status'] != 'pending')
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: inv['status'] == 'accepted' ? cs.primary.withValues(alpha: 0.10) : f.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: inv['status'] == 'accepted' ? cs.primary.withValues(alpha: 0.3) : f.error.withValues(alpha: 0.3))),
            child: Text(
              inv['status'] == 'accepted'
                  ? '+${inv['pointsEarned'] ?? 20} pts'
                  : 'Declined',
              style: TextStyle(color: inv['status'] == 'accepted' ? cs.primary : f.error, fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
      if (inv['status'] == 'pending') ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _respond(inv, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: f.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Decline', style: TextStyle(color: f.textSecondary, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => _respond(inv, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Accept', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700)))),
        ]),
      ],
    ]),
  );
  }
}
