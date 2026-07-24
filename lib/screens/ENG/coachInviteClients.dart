
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
class CoachInviteClients extends StatefulWidget {
  const CoachInviteClients({super.key});
  @override
  State<CoachInviteClients> createState() => _CoachInviteClientsState();
}

class _CoachInviteClientsState extends State<CoachInviteClients> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _invitationCode = '';
  int _earnedPoints = 0;
  int _totalInvitations = 0;
  List<dynamic> _referrals = [];
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
    final refs = await ApiService.get('/coach/invite/referrals');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _invitationCode   = result['invitationCode']   ?? '';
        _earnedPoints     = result['earnedPoints']     ?? 0;
        _totalInvitations = result['totalInvitations'] ?? 0;
        _referrals = refs['ok'] == true ? List<dynamic>.from(refs['data'] ?? []) : [];
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

  void _shareCode() async {
    final msg =
        'Join me on SIRVYA as a Coach! Use my referral code $_invitationCode when you sign up.';
    await Clipboard.setData(ClipboardData(text: msg));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Invite message copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  String _formatRefDate(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(color: Theme.of(context).colorScheme.primary, backgroundColor: context.fitlek.card, onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Text('Invite a new Coach to SIRVYA. You earn 40 points after their Coach account is successfully created.', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 14)),
                const SizedBox(height: 36),
                _buildQRSection(),
                const SizedBox(height: 32),
                _buildCodeSection(),
                const SizedBox(height: 28),
                _buildActionButtons(),
                const SizedBox(height: 32),
                _buildStatsRow(),
                const SizedBox(height: 32),
                _buildReferralHistory(),
                const SizedBox(height: 32),
                _buildHowItWorks(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
      ),
      title: Text(
        'Invite Coaches',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
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
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 12))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Placeholder for QR image when qr_flutter package is not available.
        Container(
          width: 180,
          height: 180,
          color: Colors.white,
          child: Center(
            child: Text(
              _invitationCode.isNotEmpty ? _invitationCode : 'No Code',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Text(_invitationCode, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
      ]),
    ),
  ));

  Widget _buildCodeSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1.5)),
    child: Column(children: [
      Text('Your Invitation Code', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: _buildCodeChars()),
      const SizedBox(height: 12),
      Text('You earn 40 points when a new coach registers with your code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );

  List<Widget> _buildCodeChars() {
    if (_invitationCode.isEmpty) return [];
    final parts = _invitationCode.split('-');
    final widgets = <Widget>[];
    for (int p = 0; p < parts.length; p++) {
      for (final char in parts[p].split('')) {
        widgets.add(Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 28, height: 40,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25))),
          child: Center(child: Text(char, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 15, fontWeight: FontWeight.w800)))));
      }
      if (p < parts.length - 1) {
        widgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('-', style: TextStyle(color: context.fitlek.textMuted, fontSize: 18, fontWeight: FontWeight.w300))));
      }
    }
    return widgets;
  }

  Widget _buildActionButtons() => Row(children: [
    Expanded(child: GestureDetector(onTap: _copyCode,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _copied ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _copied ? null : [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          border: _copied ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 1.5) : null),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, color: _copied ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary, size: 18),
          const SizedBox(width: 8),
          Text(_copied ? 'Copied!' : 'Copy Code', style: TextStyle(color: _copied ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ])))),
    const SizedBox(width: 12),
    Expanded(child: GestureDetector(onTap: _shareCode,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.fitlek.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.share_rounded, color: context.fitlek.textSecondary, size: 18), const SizedBox(width: 8),
          Text('Share', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 14, fontWeight: FontWeight.w700)),
        ])))),
  ]);

  Widget _buildStatsRow() => Row(children: [
    Expanded(child: _statCard('$_totalInvitations', 'Total Invitations', Icons.link_rounded)),
    const SizedBox(width: 12),
    Expanded(child: _statCard('$_earnedPoints pts', 'Points Earned', Icons.star_rounded)),
  ]);

  Widget _statCard(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 11)),
      ])),
    ]),
  );

  Widget _buildHowItWorks() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.fitlek.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How It Works', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      _buildStep('1', 'Share your code', 'Send your referral code to another coach'),
      _buildStep('2', 'They register', 'They enter your code during Coach sign up'),
      _buildStep('3', 'Earn 40 points', 'Added to your balance once their account is created'),
    ]),
  );

  Widget _buildReferralHistory() {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Coaches You Invited', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (_referrals.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: f.border)),
          child: Column(children: [
            Icon(Icons.group_add_rounded, color: f.textMuted, size: 40),
            const SizedBox(height: 10),
            Text('No coach referrals yet', style: TextStyle(color: f.textMuted, fontSize: 13)),
          ]),
        )
      else
        ..._referrals.map(_buildReferralItem),
    ]);
  }

  Widget _buildReferralItem(dynamic r) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final name = '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim();
    final avatar = r['avatarUrl']?.toString();
    final pts = r['pointsAwarded'] ?? 20;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: f.border)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: f.border)),
          child: ClipOval(
            child: (avatar != null && avatar.isNotEmpty)
                ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, color: f.textMuted, size: 20))
                : Icon(Icons.person, color: f.textMuted, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? 'Coach' : name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_formatRefDate(r['createdAt']), style: TextStyle(color: f.textMuted, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: cs.primary.withValues(alpha: 0.3))),
          child: Text('+$pts pts', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildStep(String num, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
        child: Center(child: Text(num, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(subtitle, style: TextStyle(color: context.fitlek.textMuted, fontSize: 12)),
      ])),
    ]),
  );
}
