import 'package:flutter/material.dart';
import '../../constants/names.dart';
import 'coachSignIn.dart';
import 'managerSignIn.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 20),
                const Text('Fitlek', style: TextStyle(
                    color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 10),
                Text('Premium fitness platform', style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w400)),
                const Spacer(flex: 2),
                _buildRoleCard(
                  icon: Icons.sports_rounded,
                  iconColor: const Color(0xFFA3FF12),
                  iconBg: const Color(0xFF1A3008),
                  title: 'I am a Coach',
                  subtitle: 'Manage your sessions, clients and calendar',
                  borderColor: const Color(0xFFA3FF12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoachSignIn())),
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  icon: Icons.manage_accounts_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  iconBg: const Color(0xFF001A1E),
                  title: 'I am a Manager',
                  subtitle: 'Oversee the platform and all users',
                  borderColor: const Color(0xFF00BCD4),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManagerSignIn())),
                ),
                const Spacer(flex: 1),
                Text('© ${DateTime.now().year} ${AppNames.appName}',
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      color: const Color(0xFFA3FF12),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 12))]),
    child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 46),
  );

  Widget _buildRoleCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, height: 1.4)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: borderColor.withOpacity(0.7), size: 16),
        ]),
      ),
    );
  }
}
