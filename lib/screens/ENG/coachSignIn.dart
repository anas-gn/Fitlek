import 'package:flutter/material.dart';
import '../../constants/names.dart';
import '../../services/apiService.dart';
import 'coachSignUp.dart';
import '../../mainLayoutCoach.dart';

class CoachSignIn extends StatefulWidget {
  const CoachSignIn({super.key});
  @override
  State<CoachSignIn> createState() => _CoachSignInState();
}

class _CoachSignInState extends State<CoachSignIn> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ApiService.showError(context, 'Please fill in all fields.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.post('/coach/auth', {'email': email, 'password': password}, auth: false);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['ok'] == true) {
      await ApiService.saveToken(result['token']);
      await ApiService.saveRole('coach');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayoutCoach()), (_) => false);
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
              const Text('Welcome back,\nCoach.', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Sign in to continue your journey.', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15)),
              const SizedBox(height: 40),
              _buildTextField(controller: _emailController, label: 'Email', hint: 'your@email.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: _passwordController, label: 'Password', hint: '••••••••', obscure: _obscurePassword,
                suffix: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.4), size: 20))),
              const SizedBox(height: 36),
              _buildSignInButton(),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachSignUp())),
                  child: const Text('Sign Up', style: TextStyle(color: Color(0xFFA3FF12), fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      )),
    );
  }

  Widget _buildLogo() => Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 26)),
    const SizedBox(width: 12),
    Text(AppNames.appName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
  ]);

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, TextInputType? keyboardType, bool obscure = false, Widget? suffix}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      TextField(controller: controller, keyboardType: keyboardType, obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
          suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);
  }

  Widget _buildSignInButton() => GestureDetector(
    onTap: _isLoading ? null : _signIn,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
        : const Text('Sign In', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
  );
}
