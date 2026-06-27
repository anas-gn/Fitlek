import 'package:flutter/material.dart';
import '../../constants/names.dart';
import '../../services/apiService.dart';
import '../../mainLayoutManager.dart';

class ManagerSignIn extends StatefulWidget {
  const ManagerSignIn({super.key});
  @override
  State<ManagerSignIn> createState() => _ManagerSignInState();
}

class _ManagerSignInState extends State<ManagerSignIn> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  void _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ApiService.showError(context, 'Please fill in all fields.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.post('/manager/auth', {'email': email, 'password': password}, auth: false);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['ok'] == true) {
      await ApiService.saveToken(result['token']);
      await ApiService.saveRole('manager');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayoutManager()), (_) => false);
    } else {
      ApiService.showError(context, result['message'] ?? 'Sign in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: FadeTransition(opacity: _fadeAnim,
        child: SlideTransition(position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 48),
              const Text('Manager\nPortal.', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Sign in to manage your platform.', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15)),
              const SizedBox(height: 40),
              _buildField(_emailCtrl, 'Email', 'manager@fitlek.com', TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 36),
              _buildSignInButton(),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      )),
    );
  }

  Widget _buildLogo() => Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF00BCD4), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.manage_accounts_rounded, color: Colors.black, size: 26)),
    const SizedBox(width: 12),
    Text(AppNames.appName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    const SizedBox(width: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFF001A1E), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.4))),
      child: const Text('MANAGER', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
  ]);

  Widget _buildField(TextEditingController ctrl, String label, String hint, TextInputType keyboard) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
          filled: true, fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _buildPasswordField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
    const SizedBox(height: 8),
    TextField(controller: _passwordCtrl, obscureText: _obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(hintText: '••••••••', hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
        filled: true, fillColor: const Color(0xFF111111),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        suffixIcon: GestureDetector(onTap: () => setState(() => _obscure = !_obscure),
          child: Padding(padding: const EdgeInsets.only(right: 14),
            child: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.4), size: 20))),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
  ]);

  Widget _buildSignInButton() => GestureDetector(
    onTap: _loading ? null : _signIn,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
        : const Text('Sign In', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
  );
}
