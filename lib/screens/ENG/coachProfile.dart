import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../models/coach.dart';
import 'coachEditProfile.dart';
import 'coachInvitations.dart';
import 'coachSignIn.dart';

class CoachProfile extends StatefulWidget {
  const CoachProfile({super.key});
  @override
  State<CoachProfile> createState() => _CoachProfileState();
}

class _CoachProfileState extends State<CoachProfile> {
  bool _loading = true;
  Coach? _coach;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/coach/profile');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _coach = Coach(
          id:               result['id'].toString(),
          firstName:        result['firstName']      ?? '',
          lastName:         result['lastName']       ?? '',
          email:            result['email']          ?? '',
          gender:           result['gender']         ?? '',
          bio:              result['bio']            ?? '',
          instagramPage:    result['instagramPage']  ?? '',
          totalInvitations: result['totalInvitations'] ?? 0,
          earnedPoints:     result['earnedPoints']   ?? 0,
          avatarUrl:        result['avatarUrl']      ?? '',
        );
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;
    String? error;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setS) => Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFA3FF12), size: 20)),
            const SizedBox(width: 12),
            const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          _pwField(currentCtrl, 'Current Password', obscureCurrent, () => setS(() => obscureCurrent = !obscureCurrent)),
          const SizedBox(height: 12),
          _pwField(newCtrl, 'New Password', obscureNew, () => setS(() => obscureNew = !obscureNew)),
          const SizedBox(height: 12),
          _pwField(confirmCtrl, 'Confirm New Password', obscureConfirm, () => setS(() => obscureConfirm = !obscureConfirm)),
          if (error != null) ...[
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.25))),
              child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () async {
                if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) { setS(() => error = 'All fields are required.'); return; }
                if (newCtrl.text != confirmCtrl.text) { setS(() => error = 'New passwords do not match.'); return; }
                if (newCtrl.text.length < 6) { setS(() => error = 'Password must be at least 6 characters.'); return; }
                final r = await ApiService.put('/coach/profile/edit/password', {'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text});
                if (!mounted) return;
                Navigator.pop(ctx);
                if (r['ok'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password updated.'), backgroundColor: const Color(0xFF0D1A04), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } else { ApiService.showError(context, r['message'] ?? 'Failed.'); }
              },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
          ]),
        ])),
      ),
    ));
  }

  Widget _pwField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: '••••••••', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: GestureDetector(onTap: toggle, child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.35), size: 19)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  void _showLogoutDialog() => showDialog(context: context, builder: (ctx) => Dialog(
    backgroundColor: const Color(0xFF111111),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.logout_rounded, color: Colors.red, size: 26)),
      const SizedBox(height: 16),
      const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Are you sure you want to log out?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () async {
            await ApiService.clearToken();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CoachSignIn()), (_) => false);
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12))));
    if (_coach == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Failed to load profile.', style: TextStyle(color: Colors.white54))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(child: Column(children: [
        _buildHeroSection(),
        _buildInfoSection(),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildActionsList(),
        const SizedBox(height: 32),
      ])),
    );
  }

  Widget _buildHeroSection() => Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
    Container(height: 200, width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D1A04), Color(0xFF1A3008)]))),
    Positioned(bottom: -50, child: Container(width: 100, height: 100,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFA3FF12), width: 3), boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 24)], color: const Color(0xFF1A1A1A)),
      child: ClipOval(child: _coach!.avatarUrl.isNotEmpty
          ? Image.network(_coach!.avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFFA3FF12), size: 48))
          : const Icon(Icons.person, color: Color(0xFFA3FF12), size: 48)))),
  ]);

  Widget _buildInfoSection() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
    child: Column(children: [
      Text(_coach!.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(_coach!.email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFF1A3008), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFA3FF12), size: 14), const SizedBox(width: 4),
          Text('Coach · ${_coach!.gender}', style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
      const SizedBox(height: 20),
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Text(_coach!.bio, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.6), textAlign: TextAlign.center)),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 16), const SizedBox(width: 8),
          Text(_coach!.instagramPage, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
    ]),
  );

  Widget _buildStatsRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(children: [
      Expanded(child: _statCard('${_coach!.totalInvitations}', 'Invitations', Icons.link_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('${_coach!.earnedPoints}', 'Points Earned', Icons.star_rounded)),
    ]),
  );

  Widget _statCard(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFF0D1A04), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFA3FF12).withOpacity(0.2))),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFA3FF12).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFA3FF12), size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );

  Widget _buildActionsList() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      _actionItem(Icons.edit_rounded, const Color(0xFFA3FF12), const Color(0xFF1A3008), 'Edit Profile', () async {
        final updated = await Navigator.of(context).push<Coach>(MaterialPageRoute(builder: (_) => CoachEditProfile(coach: _coach!)));
        if (updated != null) _load();
      }),
      _actionItem(Icons.lock_rounded, const Color(0xFF7C4DFF), const Color(0xFF1A0A2A), 'Change Password', _showChangePasswordDialog),
      _actionItem(Icons.history_rounded, const Color(0xFF00BCD4), const Color(0xFF001A1E), 'Invitations History',
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachInvitations()))),
      _actionItem(Icons.language_rounded, const Color(0xFFFFB800), const Color(0xFF2A1F00), 'Change Language', () {},
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
            child: const Text('English', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))),
      const SizedBox(height: 8),
      _actionItem(Icons.logout_rounded, Colors.red, const Color(0xFF1A0808), 'Log Out', _showLogoutDialog, destructive: true),
    ]),
  );

  Widget _actionItem(IconData icon, Color iconColor, Color iconBg, String label, VoidCallback onTap, {Widget? trailing, bool destructive = false}) =>
    GestureDetector(onTap: onTap, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16), border: Border.all(color: destructive ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 19)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(color: destructive ? Colors.red : Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.25), size: 20),
      ]),
    ));
}
