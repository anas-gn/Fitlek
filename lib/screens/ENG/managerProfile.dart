import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'managerSignIn.dart';

class ManagerProfile extends StatefulWidget {
  const ManagerProfile({super.key});
  @override
  State<ManagerProfile> createState() => _ManagerProfileState();
}

class _ManagerProfileState extends State<ManagerProfile> {
  bool _loading = true;
  String _firstName = '';
  String _lastName  = '';
  String _email     = '';
  String? _avatarUrl;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/manager/profile');
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _firstName = result['firstName'] ?? '';
        _lastName  = result['lastName']  ?? '';
        _email     = result['email']     ?? '';
        _avatarUrl = result['avatarUrl'];
        _loading   = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _showEditInfoDialog() {
    final firstCtrl = TextEditingController(text: _firstName);
    final lastCtrl  = TextEditingController(text: _lastName);
    final emailCtrl = TextEditingController(text: _email);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(children: [Expanded(child: _dialogField(firstCtrl, 'First Name', 'John')), const SizedBox(width: 12), Expanded(child: _dialogField(lastCtrl, 'Last Name', 'Doe'))]),
        const SizedBox(height: 14),
        _dialogField(emailCtrl, 'Email', 'manager@fitlek.com', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () async {
              final r = await ApiService.put('/manager/profile', {
                'firstName': firstCtrl.text.trim(),
                'lastName':  lastCtrl.text.trim(),
                'email':     emailCtrl.text.trim(),
              });
              if (!mounted) return;
              Navigator.pop(ctx);
              if (r['ok'] == true) _load();
              else ApiService.showError(context, r['message'] ?? 'Update failed.');
            },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))))),
        ]),
      ])),
    ));
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
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF1A0A2A), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF7C4DFF), size: 20)),
            const SizedBox(width: 12),
            const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          _passwordField(currentCtrl, 'Current Password', obscureCurrent, () => setS(() => obscureCurrent = !obscureCurrent)),
          const SizedBox(height: 12),
          _passwordField(newCtrl, 'New Password', obscureNew, () => setS(() => obscureNew = !obscureNew)),
          const SizedBox(height: 12),
          _passwordField(confirmCtrl, 'Confirm New Password', obscureConfirm, () => setS(() => obscureConfirm = !obscureConfirm)),
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
                final r = await ApiService.put('/manager/profile/password', {'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text});
                if (!mounted) return;
                Navigator.pop(ctx);
                if (r['ok'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password updated.'), backgroundColor: const Color(0xFF0D1A04), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } else { ApiService.showError(context, r['message'] ?? 'Failed.'); }
              },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
          ]),
        ])),
      ),
    ));
  }

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
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ManagerSignIn()), (_) => false);
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
      ]),
    ])),
  ));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFA3FF12))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(child: Column(children: [
        _buildHero(),
        _buildInfoSection(),
        const SizedBox(height: 24),
        _buildActions(),
        const SizedBox(height: 32),
      ])),
    );
  }

  Widget _buildHero() => Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
    Container(height: 190, width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF001A1E), Color(0xFF003040)])),
      child: Stack(children: [
        Positioned(right: -30, top: -30, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00BCD4).withOpacity(0.06)))),
      ])),
    Positioned(bottom: -48, child: Container(width: 96, height: 96,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00BCD4), width: 3), boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.35), blurRadius: 24)], color: const Color(0xFF1A1A1A)),
      child: ClipOval(child: _avatarUrl != null
          ? Image.network(_avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.manage_accounts_rounded, color: Color(0xFF00BCD4), size: 46))
          : const Icon(Icons.manage_accounts_rounded, color: Color(0xFF00BCD4), size: 46)))),
  ]);

  Widget _buildInfoSection() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 62, 24, 0),
    child: Column(children: [
      Text('$_firstName $_lastName', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(_email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFF001A1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.manage_accounts_rounded, color: Color(0xFF00BCD4), size: 14), SizedBox(width: 5),
          Text('Platform Manager', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
    ]),
  );

  Widget _buildActions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      _actionItem(Icons.edit_rounded, const Color(0xFFA3FF12), const Color(0xFF1A3008), 'Edit Profile', 'Update your personal information', _showEditInfoDialog),
      _actionItem(Icons.lock_rounded, const Color(0xFF7C4DFF), const Color(0xFF1A0A2A), 'Change Password', 'Update your account password', _showChangePasswordDialog),
      const SizedBox(height: 8),
      _actionItem(Icons.logout_rounded, Colors.red, const Color(0xFF1A0808), 'Log Out', 'Sign out of your manager account', _showLogoutDialog, destructive: true),
    ]),
  );

  Widget _actionItem(IconData icon, Color iconColor, Color iconBg, String title, String subtitle, VoidCallback onTap, {bool destructive = false}) =>
    GestureDetector(onTap: onTap, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF0E0E0E), borderRadius: BorderRadius.circular(16), border: Border.all(color: destructive ? Colors.red.withOpacity(0.12) : Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: destructive ? Colors.red : Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
      ]),
    ));

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {TextInputType? keyboard}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _passwordField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: '••••••••', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: GestureDetector(onTap: toggle, child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.35), size: 19)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5)))),
    ]);
}
