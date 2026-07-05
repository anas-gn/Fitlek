import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/apiService.dart';

class CoachInviteClients extends StatefulWidget {
  const CoachInviteClients({super.key});
  @override
  State<CoachInviteClients> createState() => _CoachInviteClientsState();
}

class _CoachInviteClientsState extends State<CoachInviteClients> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _invitationCode = '';
  int _coachID = 0;
  int _earnedPoints = 0;
  int _totalInvitations = 0;
  bool _copied = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/invite');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _coachID          = result['coachID']          ?? 0;
        _invitationCode   = result['invitationCode']   ?? '';
        _earnedPoints     = result['earnedPoints']     ?? 0;
        _totalInvitations = result['totalInvitations'] ?? 0;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _invitationCode));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  void _shareCode() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: const Text('Share sheet opened (static demo)'),
    backgroundColor: const Color(0xFF1A1A1A),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(color: const Color(0xFFA3FF12), backgroundColor: const Color(0xFF111111), onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            const Text('Invite Clients', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Share your code and earn points for every new client.', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
            const SizedBox(height: 36),
            _buildQRSection(),
            const SizedBox(height: 32),
            _buildCodeSection(),
            const SizedBox(height: 28),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildStatsRow(),
            const SizedBox(height: 32),
            _buildHowItWorks(),
          ]),
        ),
      ),
    );
  }

  Widget _buildQRSection() => Center(child: AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 12))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        QrImageView(data: _invitationCode, version: QrVersions.auto, size: 180, backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Text(_invitationCode, style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
      ]),
    ),
  ));

  Widget _buildCodeSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3), width: 1.5)),
    child: Column(children: [
      Text('Your Invitation Code', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: _buildCodeChars()),
      const SizedBox(height: 12),
      Text('Coach ID: $_coachID', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );

  List<Widget> _buildCodeChars() {
    if (_invitationCode.isEmpty) return [];
    final parts = _invitationCode.split('-');
    final widgets = <Widget>[];
    for (int p = 0; p < parts.length; p++) {
      for (final char in parts[p].split('')) {
        widgets.add(Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 28, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.25))),
          child: Center(child: Text(char, style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 15, fontWeight: FontWeight.w800)))));
      }
      if (p < parts.length - 1) widgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('-', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w300))));
    }
    return widgets;
  }

  Widget _buildActionButtons() => Row(children: [
    Expanded(child: GestureDetector(onTap: _copyCode,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _copied ? const Color(0xFF0D1A04) : const Color(0xFFA3FF12),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _copied ? null : [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
          border: _copied ? Border.all(color: const Color(0xFFA3FF12).withOpacity(0.4), width: 1.5) : null),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, color: _copied ? const Color(0xFFA3FF12) : Colors.black, size: 18),
          const SizedBox(width: 8),
          Text(_copied ? 'Copied!' : 'Copy Code', style: TextStyle(color: _copied ? const Color(0xFFA3FF12) : Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
        ])))),
    const SizedBox(width: 12),
    Expanded(child: GestureDetector(onTap: _shareCode,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.8), size: 18), const SizedBox(width: 8),
          Text('Share', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w700)),
        ])))),
  ]);

  Widget _buildStatsRow() => Row(children: [
    Expanded(child: _statCard('$_totalInvitations', 'Total Invitations', Icons.link_rounded)),
    const SizedBox(width: 12),
    Expanded(child: _statCard('$_earnedPoints pts', 'Points Earned', Icons.star_rounded)),
  ]);

  Widget _statCard(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFA3FF12), size: 20), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ])),
    ]),
  );

  Widget _buildHowItWorks() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('How It Works', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      _buildStep('1', 'Share your code', 'Send it to potential clients via link or QR'),
      _buildStep('2', 'Client registers', 'They use your code during sign up'),
      _buildStep('3', 'Earn points', 'Get 20 points per successful invite'),
    ]),
  );

  Widget _buildStep(String num, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFA3FF12), shape: BoxShape.circle),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ])),
    ]),
  );
}
